import std/unittest

import codestatspkg/languages

suite "language detection":
  test "detects Cabal package files by extension":
    check detectLanguage("project.cabal") == "Haskell"
    check detectLanguage("foo/bar/project.cabal") == "Haskell"

  test "keeps known JavaScript extensions recognized":
    check detectLanguage("app.js") == "JavaScript"
    check detectLanguage("app.mjs") == "JavaScript"
    check detectLanguage("app.cjs") == "JavaScript"

  test "keeps Swift and Objective-C++ extensions recognized":
    check detectLanguage("main.swift") == "Swift"
    check detectLanguage("foo.mm") == "Objective-C"

  test "keeps exact filename detection case-insensitive":
    check detectLanguage("GNUmakefile") == "Makefile"
    check detectLanguage("gnumakefile") == "Makefile"
    check detectLanguage("CMakeLists.txt") == "CMake"
