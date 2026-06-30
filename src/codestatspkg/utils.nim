import std/[json, os, strutils, times, unicode]
import ./gitignore

proc comma*(n: int): string =
  let s = $n
  var formatted = ""
  for i, ch in s:
    if ch == '-':
      formatted.add(ch)
      continue
    if i > 0 and (s.len - i) mod 3 == 0:
      formatted.add(',')
    formatted.add(ch)
  formatted

proc percent*(part, total: int): float =
  if total <= 0: 0.0 else: (part.float / total.float) * 100.0

proc nowString*(): string =
  now().format("yyyy-MM-dd HH:mm:ss")

proc crop*(s: string, width: int): string =
  if width <= 0: return ""
  let rLen = s.runeLen
  if rLen <= width: s
  else:
    var buf = ""
    var count = 0
    for ch in s.runes:
      if count >= width - 1: break
      buf.add(ch)
      inc count
    buf & "…"

proc jsonEscapePath*(path: string): string = path.replace("\\", "/")

proc writeJsonFile*(path: string, node: JsonNode) =
  writeFile(path, node.pretty())

proc newestMTime*(dir: string, ignorePatterns: seq[string] = @[]): Time =
  ## Prunes ignored directories while finding the newest file mtime.
  result = fromUnix(0)
  if not dirExists(dir): return

  var dirStack: seq[string] = @[dir]
  while dirStack.len > 0:
    let currentDir = dirStack.pop()
    try:
      for kind, path in walkDir(currentDir):
        case kind
        of pcDir:
          let rel = relativePath(path, dir).replace('\\', '/').strip(chars = {'/'})
          if dirPathIgnored(rel, ignorePatterns): continue
          dirStack.add(path)
        of pcFile:
          try:
            let info = getFileInfo(path)
            if info.kind == pcFile and info.lastWriteTime > result:
              result = info.lastWriteTime
          except OSError:
            discard
        else: discard
    except OSError:
      # Skip directories that cannot be traversed.
      continue
