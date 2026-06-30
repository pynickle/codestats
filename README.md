# codestats

TUI code line statistics tool.

A fast, interactive terminal interface for counting lines of code, comments, and blanks across dozens of languages. Respects `.gitignore`, handles complex comment syntax correctly, and supports live watching and JSON export.

## Overview

`codestats` scans a directory tree and presents a sortable, filterable dashboard showing per-language and per-file breakdowns. It is written in Nim and uses the `illwill` library for a responsive, double-buffered terminal UI.

It is designed for developers who want more than a one-shot CLI report: you can navigate results, toggle between language and file views, refresh on demand, and watch a tree for changes while you edit.

## Features

- Accurate line classification: distinguishes code, comments, blanks, and mixed lines (code + comment on the same line).
- Proper handling of block comments, including Nim's `#[ ]#`, Python docstrings, and nested cases.
- Respects `.gitignore` (including negation patterns) plus built-in defaults for common build artifacts.
- 60+ languages with smart detection by extension and special filenames (`CMakeLists.txt`, `package.json`, `Dockerfile`, etc.).
- Live watch mode: automatically rescans when files change.
- On-demand refresh and JSON export (`codestats_export.json`).
- Keyboard-driven interface with column sorting, file/language toggle, and help overlay.
- Single binary, no runtime dependencies beyond a modern terminal.

## Installation

### Prerequisites

- [Nim](https://nim-lang.org) ≥ 2.0
- [nimble](https://github.com/nim-lang/nimble) (usually installed with Nim)

### From source

```bash
git clone https://github.com/ENC_Euphony/codestats
cd codestats
nimble build
```

The resulting binary is placed in `bin/codestats`.

You can also run directly without installing:

```bash
nimble run codestats [path]
```

### Using nimble (once published)

```bash
nimble install codestats
codestats .
```

## Usage

Run without arguments to scan the current directory:

```bash
codestats
codestats /path/to/project
```

### Interactive controls

| Key              | Action                              |
|------------------|-------------------------------------|
| `↑` / `k`        | Move selection up                   |
| `↓` / `j`        | Move selection down                 |
| `1`–`6`          | Sort by column (ascending)          |
| `!` `@` `#` `$` `%` `^` | Sort by column (descending)  |
| `Tab`            | Cycle sort column                   |
| `f`              | Toggle language view / file view    |
| `r`              | Force rescan                        |
| `w`              | Toggle watch mode                   |
| `e`              | Export to `codestats_export.json`   |
| `?`              | Toggle help overlay                 |
| `q` / `Esc`      | Quit                                |

The header shows the scanned root, total files/lines, and watch status. A comment-ratio gauge and top files are displayed at the bottom.

### Export

Press `e` at any time. The export contains the full `ProjectStats` structure (languages + per-file details) in pretty-printed JSON.

## Language support

Detection covers common systems, web, scripting, and configuration languages. See `src/codestatspkg/languages.nim` for the full mapping.

Special cases are handled for files without conventional extensions (makefiles, Dockerfiles, various lockfiles, etc.).

Unknown or binary files are skipped.

## How it works

- Directory traversal prunes ignored directories early using gitignore semantics.
- Each file is read once. A 512-byte probe detects binary content.
- Line classification runs a single pass that tracks block comment state and detects the earliest comment token (single-line or block).
- Mixed lines (e.g. `let x = 1  # comment`) are attributed correctly.
- Results are aggregated by language and kept in memory for instant sorting and view switching.

The implementation deliberately avoids regex-heavy approaches for comment detection to stay fast and precise across many syntaxes.

## Alternatives

- [tokei](https://github.com/XAMPPRocky/tokei) — very fast CLI, excellent language support, JSON output.
- [scc](https://github.com/boyter/scc) — fast Go implementation with complexity and COCOMO estimates.
- [cloc](https://github.com/AlDanial/cloc) — the classic Perl tool, very accurate but slower.

`codestats` is the choice when you want an **interactive** experience inside the terminal rather than a one-shot report.

## Built with

- [Nim](https://nim-lang.org) — systems language with excellent metaprogramming and single-binary output.
- [illwill](https://github.com/johnnovak/illwill) — lightweight, cross-platform TUI library with double buffering and non-blocking input.

## License

See `LICENSE` file.
