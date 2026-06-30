import std/[os, strutils]

const defaultPatterns* = @[
  ".git/", ".svn/", ".hg/", "node_modules/", "__pycache__/", ".DS_Store",
  "*.o", "*.obj", "*.exe", "*.dll", "*.so", "*.dylib"
]

proc normalizePath(path: string): string =
  path.replace('\\', '/').strip(chars = {'/'})

proc matchCharClass(ch: char, pattern: string, i: var int): bool =
  var negate = false
  result = false
  inc i
  if i < pattern.len and pattern[i] in {'!', '^'}:
    negate = true
    inc i
  while i < pattern.len and pattern[i] != ']':
    if i + 2 < pattern.len and pattern[i + 1] == '-' and pattern[i + 2] != ']':
      if ch >= pattern[i] and ch <= pattern[i + 2]: result = true
      i += 3
    else:
      if ch == pattern[i]: result = true
      inc i
  while i < pattern.len and pattern[i] != ']': inc i
  if negate: result = not result

proc globMatch(text, pattern: string): bool =
  ## Supports * within a path segment and ** across directory separators.
  proc go(ti, pi: int): bool =
    if pi == pattern.len: return ti == text.len
    # ** can cross directory separators.
    if pi + 1 < pattern.len and pattern[pi] == '*' and pattern[pi + 1] == '*':
      var next = pi + 2
      if next == pattern.len: return true
      if pattern[next] == '/': inc next
      if next == pattern.len: return true
      # Retry the remaining pattern at each possible position.
      for pos in ti .. text.len:
        if go(pos, next): return true
      return false
    # * stays within the current path segment.
    if pattern[pi] == '*':
      var next = pi + 1
      if next == pattern.len:
        for pos in ti .. text.len:
          if pos < text.len and text[pos] == '/': return false
          if go(pos, next): return true
        return false
      for pos in ti .. text.len:
        if pos < text.len and text[pos] == '/': break
        if go(pos, next): return true
      return false
    if ti >= text.len: return false
    case pattern[pi]
    of '?':
      if text[ti] != '/': return go(ti + 1, pi + 1)
      return false
    of '[':
      var classEnd = pi
      let ok = matchCharClass(text[ti], pattern, classEnd)
      if text[ti] == '/': return false
      ok and classEnd < pattern.len and go(ti + 1, classEnd + 1)
    else:
      text[ti].toLowerAscii() == pattern[pi].toLowerAscii() and go(ti + 1, pi + 1)
  go(0, 0)

proc loadGitignore*(dir: string): seq[string] =
  ## Loads .gitignore entries and preserves negation patterns for matching.
  let gitignorePath = dir / ".gitignore"
  if not fileExists(gitignorePath): return @[]
  for raw in lines(gitignorePath):
    let line = raw.strip()
    if line.len == 0 or line.startsWith("#"):
      continue
    result.add(line)

proc hasWildcard(pattern: string): bool =
  for ch in pattern:
    if ch in {'*', '?', '[', ']'}: return true
  false

proc matchesIgnorePattern(normalized, base, rawPattern: string): bool =
  ## Matches one non-negation .gitignore pattern.
  var pattern = rawPattern.strip()
  if pattern.len == 0: return false
  pattern = pattern.replace('\\', '/')
  let isDirPattern = pattern.endsWith("/")
  pattern = pattern.strip(chars = {'/'})
  if pattern.len == 0: return false

  if isDirPattern:
    return normalized == pattern or normalized.startsWith(pattern & "/") or
           normalized.contains("/" & pattern & "/")

  if not hasWildcard(pattern):
    if base == pattern: return true
    if not pattern.contains("/"):
      # A single path segment can match any segment in the path.
      for part in normalized.split('/'):
        if part == pattern: return true
    else:
      # Multi-segment patterns match the whole path or a path suffix.
      if normalized.endsWith("/" & pattern) or normalized == pattern:
        return true
  else:
    if globMatch(base, pattern) or globMatch(normalized, pattern):
      return true
    if not pattern.contains("/"):
      for part in normalized.split('/'):
        if part == pattern: return true

  false

proc shouldIgnore*(path: string, patterns: seq[string]): bool =
  let normalized = normalizePath(path)
  let base = extractFilename(normalized)

  var ignored = false
  for rawPattern in patterns:
    if rawPattern.strip().startsWith("!"): continue
    if matchesIgnorePattern(normalized, base, rawPattern):
      ignored = true
      break

  if not ignored: return false

  for rawPattern in patterns:
    var pattern = rawPattern.strip()
    if not pattern.startsWith("!"): continue
    pattern = pattern[1..^1]
    if matchesIgnorePattern(normalized, base, pattern):
      return false

  true

proc dirPathIgnored*(relPath: string, patterns: seq[string]): bool =
  ## Checks whether any relative path segment should be pruned during traversal.
  let parts = relPath.replace('\\', '/').split('/')
  var accumulated = ""
  for i, part in parts:
    if i > 0: accumulated.add('/')
    accumulated.add(part)
    for rawPattern in patterns:
      var pattern = rawPattern.strip()
      if pattern.len == 0 or pattern.startsWith("!"): continue
      pattern = pattern.replace('\\', '/')
      if not pattern.endsWith("/"): continue
      pattern = pattern.strip(chars = {'/'})
      if pattern.len == 0: continue
      if not pattern.contains('/'):
        if part == pattern or globMatch(part, pattern):
          return true
  false
