import std/[algorithm, json, os, strutils, tables]
import ./[gitignore, languages, utils]

type
  LineCategory* = enum
    lcCode, lcComment, lcBlank, lcMixed

  FileInfo* = object
    path*: string
    language*: string
    totalLines*: int
    codeLines*: int
    commentLines*: int
    blankLines*: int

  LanguageStats* = object
    language*: string
    fileCount*: int
    totalLines*: int
    codeLines*: int
    commentLines*: int
    blankLines*: int

  ProjectStats* = object
    rootDir*: string
    totalFiles*: int
    totalLines*: int
    codeLines*: int
    commentLines*: int
    blankLines*: int
    languages*: seq[LanguageStats]
    files*: seq[FileInfo]
    scannedAt*: string

proc singleLineTokens(language: string): seq[string] =
  case language
  of "Python", "Ruby", "Perl", "Shell", "Bash", "Zsh", "Fish", "PowerShell",
     "Nim", "YAML", "TOML", "CMake", "Makefile", "R", "Julia", "Crystal",
     "Elixir", "Groovy", "Pascal", "Fortran", "COBOL", "Verilog":
    @["#"]
  of "Ada", "VHDL": @["--"]
  of "Lua", "Haskell", "SQL": @["--"]
  of "Clojure", "Common Lisp", "Emacs Lisp", "Lisp", "Racket", "Scheme":
    @[";"]
  of "F#": @["//"]
  of "HTML", "XML", "Vue", "Svelte", "Astro", "JSX":
    @[]
  of "CSS":
    @[]
  of "Kotlin", "Scala", "Java", "C", "C++", "C#", "Go", "Rust", "Zig", "D", "V",
     "Swift", "Objective-C", "JavaScript", "TypeScript", "Dart", "PHP",
     "SCSS", "LESS", "Sass", "Stylus", "React":
    @["//", "///"]
  of "Batch": @["REM", "rem"]
  else: @["//", "///"]

proc blockTokens(language: string): seq[(string, string)] =
  result = @[]
  case language
  of "Python": result.add(("\"\"\"", "\"\"\"")); result.add(("'''", "'''"))
  of "Haskell": result.add(("{-", "-}"))
  of "HTML", "XML", "Vue", "Svelte", "Astro", "JSX", "React": result.add(("<!--", "-->"))
  of "Lua": result.add(("--[[", "]]"))
  of "Nim": result.add(("#[", "]#"))
  of "Julia": result.add(("#=", "=#"))
  of "Kotlin", "Scala", "Java", "C", "C++", "C#", "Go", "Rust", "Zig", "D", "V",
     "Swift", "Objective-C", "JavaScript", "TypeScript", "Dart", "PHP",
     "CSS", "SCSS", "Sass", "LESS", "Stylus", "SQL", "Crystal", "Groovy",
     "Assembly", "Fortran", "Verilog", "SystemVerilog":
    result.add(("/*", "*/"))
  of "F#", "OCaml": result.add(("(*", "*)"))
  of "Pascal":
    result.add(("{", "}"))
    result.add(("(*", "*)"))
  of "Lisp", "Common Lisp", "Emacs Lisp", "Racket", "Scheme", "Clojure":
    result.add(("#|", "|#"))
  else:
    result.add(("/*", "*/"))

proc hasBinaryByte(file: File): bool =
  ## Reads the first 512 bytes, then restores the caller's file position.
  ## Binary files without NUL bytes in that window may still be treated as text.
  try:
    let originalPos = file.getFilePos()
    defer: file.setFilePos(originalPos)
    var buf: array[512, byte]
    let bytesRead = file.readBuffer(addr buf[0], 512)
    for i in 0 ..< bytesRead:
      if buf[i] == 0: return true
  except CatchableError:
    return true

proc classifyLine(line: string, language: string, inBlock: var string): LineCategory =
  let trimmed = line.strip()
  if trimmed.len == 0: return lcBlank

  if inBlock.len > 0:
    let endPos = trimmed.find(inBlock)
    if endPos >= 0:
      let after = trimmed[(endPos + inBlock.len) .. ^1].strip()
      inBlock = ""
      if after.len > 0:
        # Reclassify the tail because code or another comment can follow a block close.
        let afterCategory = classifyLine(after, language, inBlock)
        if afterCategory == lcCode: return lcMixed
        return afterCategory
      return lcComment
    return lcComment

  # Use the earliest comment token so "// comment /*" stays a line comment.
  var earliestPos = -1
  var earliestIsBlock = false
  var blockPair: (string, string)

  for pair in blockTokens(language):
    let pos = trimmed.find(pair[0])
    if pos >= 0 and (earliestPos < 0 or pos < earliestPos):
      earliestPos = pos
      earliestIsBlock = true
      blockPair = pair

  for token in singleLineTokens(language):
    if token.len == 0: continue
    let pos = trimmed.find(token)
    if pos >= 0 and (earliestPos < 0 or pos < earliestPos):
      earliestPos = pos
      earliestIsBlock = false

  if earliestPos < 0:
    return lcCode

  if not earliestIsBlock:
    return if earliestPos == 0: lcComment else: lcMixed

  let before = trimmed[0 ..< earliestPos].strip()
  let afterStart = earliestPos + blockPair[0].len
  let endPos = trimmed.find(blockPair[1], afterStart)
  if endPos >= 0:
    let after = trimmed[(endPos + blockPair[1].len) .. ^1].strip()
    if before.len > 0 or after.len > 0: return lcMixed
    return lcComment
  inBlock = blockPair[1]
  if before.len > 0: return lcMixed
  return lcComment

proc countLines*(filePath: string, lang: string = ""): FileInfo =
  result.path = filePath
  result.language = if lang.len > 0: lang else: detectLanguage(filePath)
  if result.language.len == 0: return

  try:
    let file = open(filePath, fmRead)
    defer: close(file)
    if hasBinaryByte(file):
      result = FileInfo(path: filePath, language: result.language)
      return
    var inBlock = ""
    for line in file.lines():
      inc result.totalLines
      case classifyLine(line, result.language, inBlock)
      of lcBlank: inc result.blankLines
      of lcComment: inc result.commentLines
      of lcCode, lcMixed: inc result.codeLines
  except CatchableError:
    result = FileInfo(path: filePath, language: result.language)

proc makeRelative(root, path: string): string =
  try: relativePath(path, root).replace('\\', '/')
  except CatchableError: path.replace('\\', '/')

proc scanDirectory*(dir: string, ignorePatterns: seq[string]): ProjectStats =
  let root = absolutePath(dir)
  result.rootDir = root
  result.scannedAt = nowString()
  var byLang = initTable[string, LanguageStats]()

  # Prune ignored directories before descending into them.
  var dirStack: seq[string] = @[root]
  while dirStack.len > 0:
    let currentDir = dirStack.pop()
    try:
      for kind, path in walkDir(currentDir):
        case kind
        of pcDir:
          let rel = makeRelative(root, path)
          if dirPathIgnored(rel, ignorePatterns): continue
          dirStack.add(path)
        of pcFile:
          let rel = makeRelative(root, path)
          if shouldIgnore(rel, ignorePatterns): continue
          let lang = detectLanguage(path)
          if lang.len == 0: continue
          let info = countLines(path, lang)
          if info.language.len == 0 or info.totalLines == 0: continue
          result.files.add(info)
          inc result.totalFiles
          result.totalLines += info.totalLines
          result.codeLines += info.codeLines
          result.commentLines += info.commentLines
          result.blankLines += info.blankLines
          var langStats = byLang.getOrDefault(info.language, LanguageStats(language: info.language))
          inc langStats.fileCount
          langStats.totalLines += info.totalLines
          langStats.codeLines += info.codeLines
          langStats.commentLines += info.commentLines
          langStats.blankLines += info.blankLines
          byLang[info.language] = langStats
        else: discard
    except OSError:
      # Skip directories that cannot be traversed.
      continue

  for lang in byLang.values: result.languages.add(lang)
  result.languages.sort(proc (a, b: LanguageStats): int = cmp(b.codeLines, a.codeLines))
  result.files.sort(proc (a, b: FileInfo): int = cmp(b.codeLines, a.codeLines))

proc toJson*(info: FileInfo): JsonNode =
  %*{
    "path": jsonEscapePath(info.path), "language": info.language, "totalLines": info.totalLines,
    "codeLines": info.codeLines, "commentLines": info.commentLines, "blankLines": info.blankLines
  }

proc toJson*(lang: LanguageStats): JsonNode =
  %*{
    "language": lang.language, "fileCount": lang.fileCount, "totalLines": lang.totalLines,
    "codeLines": lang.codeLines, "commentLines": lang.commentLines, "blankLines": lang.blankLines
  }

proc toJson*(stats: ProjectStats): JsonNode =
  result = %*{
    "rootDir": jsonEscapePath(stats.rootDir), "scannedAt": stats.scannedAt, "totalFiles": stats.totalFiles,
    "totalLines": stats.totalLines, "codeLines": stats.codeLines, "commentLines": stats.commentLines,
    "blankLines": stats.blankLines, "languages": [], "files": []
  }
  for lang in stats.languages: result["languages"].add(lang.toJson())
  for file in stats.files: result["files"].add(file.toJson())

proc exportJson*(stats: ProjectStats, path = "codestats_export.json") =
  writeJsonFile(path, stats.toJson())
