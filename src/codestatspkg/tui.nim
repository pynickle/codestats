import std/[algorithm, strformat, strutils]
from std/os import extractFilename
import illwill
import ./[core, languages, utils]

type
  SortColumn* = enum
    scLanguage, scFiles, scCode, scComments, scBlanks, scTotal

  ViewState* = object
    sortBy*: SortColumn
    sortAsc*: bool
    scrollOffset*: int
    selectedRow*: int
    showFiles*: bool
    needsRescan*: bool
    watchMode*: bool
    showHelp*: bool
    exportRequested*: bool
    statusMessage*: string
    # Cached sorted rows; dataGeneration invalidates them after rescans.
    cachedSortBy*: SortColumn
    cachedSortAsc*: bool
    cachedLangs*: seq[LanguageStats]
    cachedFiles*: seq[FileInfo]
    dataGeneration*: int
    cachedGeneration*: int

proc exitProc*() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc initTUI*() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()

proc shutdownTUI*() =
  illwillDeinit()
  showCursor()

proc colColor(language: string): ForegroundColor =
  case languageColorName(language)
  of "yellow": fgYellow
  of "red": fgRed
  of "blue": fgBlue
  of "cyan": fgCyan
  of "green": fgGreen
  of "magenta": fgMagenta
  of "white": fgWhite
  of "black": fgBlack
  else: fgWhite

proc ratioColor(ratio: float): ForegroundColor =
  if ratio >= 70: fgGreen
  elif ratio >= 45: fgYellow
  else: fgRed

proc commentGaugeColor(ratio: float): ForegroundColor =
  if ratio >= 15 and ratio <= 30: fgGreen
  elif (ratio >= 5 and ratio < 15) or (ratio > 30 and ratio <= 50): fgYellow
  else: fgRed

proc sortedLanguages(stats: ProjectStats, view: var ViewState): seq[LanguageStats] =
  if view.cachedSortBy == view.sortBy and view.cachedSortAsc == view.sortAsc and
     view.cachedLangs.len == stats.languages.len and
     view.cachedGeneration == view.dataGeneration:
    return view.cachedLangs
  result = stats.languages
  let sortCol = view.sortBy
  let sortAsc = view.sortAsc
  result.sort(proc (a, b: LanguageStats): int =
    result = case sortCol
    of scLanguage: cmp(a.language, b.language)
    of scFiles: cmp(a.fileCount, b.fileCount)
    of scCode: cmp(a.codeLines, b.codeLines)
    of scComments: cmp(a.commentLines, b.commentLines)
    of scBlanks: cmp(a.blankLines, b.blankLines)
    of scTotal: cmp(a.totalLines, b.totalLines)
    if not sortAsc: result = -result
  )
  view.cachedSortBy = view.sortBy
  view.cachedSortAsc = view.sortAsc
  view.cachedLangs = result
  view.cachedGeneration = view.dataGeneration

proc sortedFiles(stats: ProjectStats, view: var ViewState): seq[FileInfo] =
  if view.cachedSortBy == view.sortBy and view.cachedSortAsc == view.sortAsc and
     view.cachedFiles.len == stats.files.len and
     view.cachedGeneration == view.dataGeneration:
    return view.cachedFiles
  result = stats.files
  let sortCol = view.sortBy
  let sortAsc = view.sortAsc
  result.sort(proc (a, b: FileInfo): int =
    result = case sortCol
    of scLanguage: cmp(a.language & a.path, b.language & b.path)
    of scFiles: cmp(a.path, b.path)
    of scCode: cmp(a.codeLines, b.codeLines)
    of scComments: cmp(a.commentLines, b.commentLines)
    of scBlanks: cmp(a.blankLines, b.blankLines)
    of scTotal: cmp(a.totalLines, b.totalLines)
    if not sortAsc: result = -result
  )
  view.cachedSortBy = view.sortBy
  view.cachedSortAsc = view.sortAsc
  view.cachedFiles = result
  view.cachedGeneration = view.dataGeneration

proc drawBar(tb: var TerminalBuffer, x, y, code, total, width: int, fillColor: ForegroundColor, bright: bool) =
  if width <= 0: return
  if width <= 2:
    let filled = if total <= 0: 0 else: min(width, max(0, (code * width) div total))
    if filled > 0:
      tb.setForegroundColor(fillColor, bright = bright)
      for i in 0 ..< filled:
        tb.write(x + i, y, "▓")
    if filled < width:
      tb.setForegroundColor(fgBlack)
      for i in filled ..< width:
        tb.write(x + i, y, "░")
    tb.resetAttributes()
    return
  let innerWidth = width - 2
  let filled = if total <= 0: 0 else: min(innerWidth, max(0, (code * innerWidth) div innerWidth))
  tb.setForegroundColor(fgWhite)
  tb.write(x, y, "│")
  if filled > 0:
    tb.setForegroundColor(fillColor, bright = bright)
    for i in 0 ..< filled:
      tb.write(x + 1 + i, y, "▓")
  if filled < innerWidth:
    tb.setForegroundColor(fgBlack)
    for i in filled ..< innerWidth:
      tb.write(x + 1 + i, y, "░")
  tb.setForegroundColor(fgWhite)
  tb.write(x + 1 + innerWidth, y, "│")
  tb.resetAttributes()

proc drawText(tb: var TerminalBuffer, x, y: int, text: string, color = fgWhite, bright = false) =
  if y < 0 or y >= tb.height or x >= tb.width: return
  tb.setForegroundColor(color, bright = bright)
  tb.write(x, y, crop(text, max(0, tb.width - x - 1)))
  tb.resetAttributes()

proc drawBox(tb: var TerminalBuffer, x, y, w, h: int, color = fgWhite) =
  if w < 2 or h < 2: return
  tb.setForegroundColor(color)
  tb.write(x, y, "┌" & repeat("─", w - 2) & "┐")
  for row in y + 1 ..< y + h - 1:
    tb.write(x, row, "│")
    tb.write(x + w - 1, row, "│")
  tb.write(x, y + h - 1, "└" & repeat("─", w - 2) & "┘")
  tb.resetAttributes()

proc drawHelp(tb: var TerminalBuffer) =
  let w = min(68, max(30, tb.width - 6))
  let h = 14
  let x = max(0, (tb.width - w) div 2)
  let y = max(0, (tb.height - h) div 2)
  drawBox(tb, x, y, w, h, fgYellow)
  drawText(tb, x + 2, y + 1, "Help", fgYellow, true)
  let lines = [
    "↑/↓ or j/k  Navigate rows", "1-6          Sort columns ascending",
    "! @ # $ % ^  Sort columns descending", "Tab          Cycle sort column",
    "f            Toggle language/file view", "r            Refresh scan",
    "w            Toggle watch mode", "e            Export codestats_export.json",
    "?            Toggle this help", "q or Esc     Quit"
  ]
  for i, line in lines:
    drawText(tb, x + 2, y + 3 + i, line, fgWhite)

proc drawDashboard*(stats: ProjectStats, view: var ViewState) =
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  if tb.width < 50 or tb.height < 16:
    drawText(tb, 0, 0, "Terminal too small for CodeLineStats", fgYellow, true)
    tb.display()
    return

  let w = tb.width
  let h = tb.height
  drawBox(tb, 0, 0, w, h, fgYellow)
  drawText(tb, 3, 1, "CodeLineStats v0.1", fgYellow, true)
  let watch = if view.watchMode: "[WATCH]" else: "       "
  drawText(tb, max(24, w - stats.rootDir.len - watch.len - 5), 1, crop(stats.rootDir, max(10, w - 36)), fgWhite)
  drawText(tb, w - watch.len - 3, 1, watch, if view.watchMode: fgGreen else: fgWhite, true)

  tb.setForegroundColor(fgYellow)
  tb.write(0, 2, "├" & repeat("─", w - 2) & "┤")
  tb.write(0, 4, "├" & repeat("─", w - 2) & "┤")
  tb.resetAttributes()
  drawText(tb, 3, 3, fmt"Total: {comma(stats.totalFiles)} files │ {comma(stats.totalLines)} lines │ {comma(stats.codeLines)} code │ {comma(stats.commentLines)} comments │ {comma(stats.blankLines)} blank", fgWhite, true)

  let tableTop = 5
  let footerTop = max(tableTop + 4, h - 6)
  let visibleRows = max(1, footerTop - tableTop - 3)
  drawText(tb, 3, tableTop, if view.showFiles: "File / Language               Code     Comment  Blank     Total     %Code   Bar" else: "Language      Files   Code     Comment   Blank     Total     %Code   Bar", fgCyan, true)
  drawText(tb, 3, tableTop + 1, repeat("─", max(10, w - 6)), fgWhite)

  if view.showFiles:
    let rows = sortedFiles(stats, view)
    for i in 0 ..< min(visibleRows, max(0, rows.len - view.scrollOffset)):
      let idx = view.scrollOffset + i
      let file = rows[idx]
      let y = tableTop + 2 + i
      let selected = idx == view.selectedRow
      let color = if selected: fgGreen else: fgWhite
      let p = percent(file.codeLines, file.totalLines)
      drawText(tb, 3, y, crop(extractFilename(file.path) & " / " & file.language, 28).alignLeft(28), color, selected)
      drawText(tb, 32, y, comma(file.codeLines).align(8), color, selected)
      drawText(tb, 41, y, comma(file.commentLines).align(8), color, selected)
      drawText(tb, 50, y, comma(file.blankLines).align(7), color, selected)
      drawText(tb, 58, y, comma(file.totalLines).align(8), color, selected)
      drawText(tb, 67, y, fmt"{p:5.1f}%", ratioColor(p), selected)
      drawBar(tb, 75, y, file.codeLines, file.totalLines, max(1, w - 78), ratioColor(p), selected)
  else:
    let rows = sortedLanguages(stats, view)
    for i in 0 ..< min(visibleRows, max(0, rows.len - view.scrollOffset)):
      let idx = view.scrollOffset + i
      let lang = rows[idx]
      let y = tableTop + 2 + i
      let selected = idx == view.selectedRow
      let rowColor = if selected: fgGreen else: fgWhite
      let p = percent(lang.codeLines, lang.totalLines)
      drawText(tb, 3, y, "●", colColor(lang.language), true)
      drawText(tb, 5, y, crop(lang.language, 12).alignLeft(12), rowColor, selected)
      drawText(tb, 17, y, comma(lang.fileCount).align(6), rowColor, selected)
      drawText(tb, 25, y, comma(lang.codeLines).align(7), rowColor, selected)
      drawText(tb, 34, y, comma(lang.commentLines).align(8), rowColor, selected)
      drawText(tb, 44, y, comma(lang.blankLines).align(7), rowColor, selected)
      drawText(tb, 52, y, comma(lang.totalLines).align(8), rowColor, selected)
      drawText(tb, 62, y, fmt"{p:5.1f}%", ratioColor(p), selected)
      drawBar(tb, 70, y, lang.codeLines, lang.totalLines, max(1, w - 73), ratioColor(p), selected)

  tb.setForegroundColor(fgYellow)
  tb.write(0, footerTop, "├" & repeat("─", w - 2) & "┤")
  tb.write(0, footerTop + 2, "├" & repeat("─", w - 2) & "┤")
  tb.write(0, h - 2, "├" & repeat("─", w - 2) & "┤")
  tb.resetAttributes()

  let cr = percent(stats.commentLines, stats.codeLines + stats.commentLines)
  drawText(tb, 3, footerTop + 1, fmt"Comment Ratio: {cr:.1f}%", commentGaugeColor(cr), true)
  if stats.files.len > 0:
    drawText(tb, max(3, w - 42), footerTop + 1, fmt"Top: {crop(extractFilename(stats.files[0].path), 20)} ({comma(stats.files[0].codeLines)})", fgYellow, true)

  var topText = "Top files: "
  for i in 0 ..< min(5, stats.files.len):
    if i > 0: topText.add("  • ")
    topText.add(fmt"{extractFilename(stats.files[i].path)} ({comma(stats.files[i].codeLines)})")
  drawText(tb, 3, footerTop + 3, topText, fgWhite)
  let status = if view.statusMessage.len > 0: " │ " & view.statusMessage else: ""
  drawText(tb, 3, h - 1, "[1-6] Sort  [f] Files  [r] Refresh  [w] Watch  [e] Export  [?] Help  [q] Quit" & status, fgWhite)

  if view.showHelp: drawHelp(tb)
  tb.display()

proc rowCount*(stats: ProjectStats, view: ViewState): int =
  if view.showFiles: stats.files.len else: stats.languages.len

proc clampView*(view: var ViewState, rowCount, visibleRows: int) =
  if rowCount <= 0:
    view.selectedRow = 0
    view.scrollOffset = 0
    return
  view.selectedRow = clamp(view.selectedRow, 0, rowCount - 1)
  if view.selectedRow < view.scrollOffset: view.scrollOffset = view.selectedRow
  if view.selectedRow >= view.scrollOffset + visibleRows:
    view.scrollOffset = view.selectedRow - visibleRows + 1
  view.scrollOffset = clamp(view.scrollOffset, 0, max(0, rowCount - visibleRows))

proc handleInput*(view: var ViewState, key: Key): bool =
  result = true
  view.statusMessage = ""
  case key
  of Key.Escape, Key.Q: result = false
  of Key.Up, Key.K:
    dec view.selectedRow
  of Key.Down, Key.J:
    inc view.selectedRow
  of Key.One: view.sortBy = scLanguage; view.sortAsc = true
  of Key.Two: view.sortBy = scFiles; view.sortAsc = true
  of Key.Three: view.sortBy = scCode; view.sortAsc = true
  of Key.Four: view.sortBy = scComments; view.sortAsc = true
  of Key.Five: view.sortBy = scBlanks; view.sortAsc = true
  of Key.Six: view.sortBy = scTotal; view.sortAsc = true
  of Key.ExclamationMark: view.sortBy = scLanguage; view.sortAsc = false
  of Key.At: view.sortBy = scFiles; view.sortAsc = false
  of Key.Hash: view.sortBy = scCode; view.sortAsc = false
  of Key.Dollar: view.sortBy = scComments; view.sortAsc = false
  of Key.Percent: view.sortBy = scBlanks; view.sortAsc = false
  of Key.Caret: view.sortBy = scTotal; view.sortAsc = false
  of Key.Tab:
    view.sortBy = SortColumn((ord(view.sortBy) + 1) mod (ord(high(SortColumn)) + 1))
  of Key.F:
    view.showFiles = not view.showFiles
    view.selectedRow = 0
    view.scrollOffset = 0
  of Key.R:
    view.needsRescan = true
    view.statusMessage = "Refreshing..."
  of Key.W:
    view.watchMode = not view.watchMode
    view.statusMessage = if view.watchMode: "Watching..." else: "Watch off"
  of Key.E:
    view.exportRequested = true
  of Key.QuestionMark:
    view.showHelp = not view.showHelp
  else: discard
