import std/[os, unittest]

import codestatspkg/core

suite "line counting":
  test "counts from the beginning after binary probing":
    let path = getTempDir() / "codestats_count_probe.nim"
    writeFile(path, "echo 1\n# comment\n\n")
    defer: removeFile(path)

    let info = countLines(path, "Nim")

    check info.totalLines == 3
    check info.codeLines == 1
    check info.commentLines == 1
    check info.blankLines == 1
