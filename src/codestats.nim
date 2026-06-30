import std/[os, times]
import illwill
import codestatspkg/[core, gitignore, tui, utils]

proc scan(targetDir: string, ignorePatterns: seq[string]): ProjectStats =
  scanDirectory(targetDir, ignorePatterns)

proc main() =
  let targetDir = if paramCount() > 0: paramStr(1) else: "."
  let ignorePatterns = loadGitignore(targetDir) & defaultPatterns

  var tuiReady = false
  var view = ViewState(sortBy: scCode, sortAsc: false)
  try:
    var stats: ProjectStats
    try:
      stats = scan(targetDir, ignorePatterns)
    except CatchableError:
      stats = ProjectStats(rootDir: targetDir, scannedAt: nowString())

    var lastMTime = fromUnix(0)
    try:
      lastMTime = newestMTime(targetDir, ignorePatterns)
    except CatchableError:
      discard

    initTUI()
    tuiReady = true
    while true:
      let visibleRows = max(1, terminalHeight() - 14)
      view.clampView(rowCount(stats, view), visibleRows)
      drawDashboard(stats, view)

      let key = getKey()
      if not handleInput(view, key): break
      view.clampView(rowCount(stats, view), visibleRows)

      if view.exportRequested:
        exportJson(stats)
        view.exportRequested = false
        view.statusMessage = "Exported codestats_export.json"

      if view.needsRescan:
        try:
          stats = scan(targetDir, ignorePatterns)
          lastMTime = newestMTime(targetDir, ignorePatterns)
          view.cachedLangs = @[]
          view.cachedFiles = @[]
          inc view.dataGeneration
          view.statusMessage = "Scan refreshed"
        except CatchableError:
          view.statusMessage = "Scan failed — some directories may be inaccessible"
        view.needsRescan = false
      elif view.watchMode:
        try:
          let currentMTime = newestMTime(targetDir, ignorePatterns)
          if currentMTime > lastMTime:
            stats = scan(targetDir, ignorePatterns)
            lastMTime = currentMTime
            view.cachedLangs = @[]
            view.cachedFiles = @[]
            inc view.dataGeneration
            view.statusMessage = "Changes detected; rescanned"
        except CatchableError:
          discard

      sleep(80)
  finally:
    if tuiReady:
      shutdownTUI()

when isMainModule:
  main()
