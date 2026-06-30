import std/[os, strutils, tables]

const languageByExtension* = {
  "c": "C", "h": "C",
  "cpp": "C++", "cc": "C++", "cxx": "C++", "c++": "C++", "hpp": "C++", "hh": "C++", "hxx": "C++",
  "rs": "Rust", "go": "Go", "zig": "Zig", "d": "D",
  "py": "Python", "pyw": "Python", "rb": "Ruby", "pl": "Perl", "pm": "Perl", "lua": "Lua",
  "php": "PHP",
  "js": "JavaScript", "mjs": "JavaScript", "cjs": "JavaScript",
  "ts": "TypeScript", "jsx": "React", "tsx": "React",
  "vue": "Vue", "svelte": "Svelte", "astro": "Astro",
  "hs": "Haskell", "lhs": "Haskell", "cabal": "Haskell",
  "ml": "OCaml", "mli": "OCaml",
  "fs": "F#", "fsx": "F#", "fsi": "F#",
  "clj": "Clojure", "cljs": "Clojure", "cljc": "Clojure",
  "ex": "Elixir", "exs": "Elixir",
  "lisp": "Lisp", "lsp": "Lisp", "cl": "Common Lisp", "el": "Emacs Lisp",
  "scm": "Scheme", "ss": "Scheme",
  "rkt": "Racket",
  "scala": "Scala", "sc": "Scala",
  "java": "Java", "kt": "Kotlin", "kts": "Kotlin",
  "groovy": "Groovy", "gradle": "Groovy",
  "cs": "C#", "vb": "VB.NET",
  "swift": "Swift", "mm": "Objective-C",
  "dart": "Dart",
  "r": "R", "rmd": "R Markdown",
  "jl": "Julia",
  "sql": "SQL",
  "sh": "Shell", "bash": "Shell", "zsh": "Shell", "fish": "Shell",
  "ps1": "PowerShell", "psm1": "PowerShell", "psd1": "PowerShell",
  "bat": "Batch", "cmd": "Batch",
  "tcl": "Tcl",
  "html": "HTML", "htm": "HTML", "xhtml": "HTML",
  "css": "CSS", "scss": "SCSS", "sass": "Sass", "less": "LESS", "styl": "Stylus",
  "md": "Markdown", "markdown": "Markdown", "mdx": "MDX",
  "rst": "reStructuredText", "adoc": "AsciiDoc", "asciidoc": "AsciiDoc",
  "tex": "LaTeX", "sty": "LaTeX", "cls": "LaTeX",
  "json": "JSON", "jsonc": "JSON", "json5": "JSON5",
  "yaml": "YAML", "yml": "YAML",
  "toml": "TOML", "ini": "INI", "cfg": "Config",
  "xml": "XML", "csv": "CSV", "tsv": "TSV",
  "graphql": "GraphQL", "gql": "GraphQL",
  "proto": "Protocol Buffers",
  "dockerfile": "Dockerfile",
  "mk": "Makefile", "make": "Makefile",
  "cmake": "CMake",
  "nim": "Nim", "nims": "Nim", "nimble": "Nim",
  "asm": "Assembly", "s": "Assembly",
  "cr": "Crystal",
  "p": "Pascal", "pp": "Pascal", "lpr": "Pascal", "pas": "Pascal",
  "ada": "Ada", "adb": "Ada", "ads": "Ada",
  "vhd": "VHDL", "vhdl": "VHDL",
  "sv": "SystemVerilog",
  "cob": "COBOL", "cpy": "COBOL",
  "for": "Fortran", "f90": "Fortran", "f95": "Fortran", "f03": "Fortran", "f08": "Fortran",
  "pro": "Prolog",
  "st": "Smalltalk",
  "nut": "Squirrel",
  "wren": "Wren",
  "nelua": "Nelua",
  # Treat .v as V; Verilog uses .sv here.
  "v": "V"
}.toTable

const languageByFilename* = {
  "dockerfile": "Dockerfile",
  "makefile": "Makefile",
  "gnumakefile": "Makefile",
  "cmakelists.txt": "CMake",
  "gemfile": "Ruby",
  "rakefile": "Ruby",
  "podfile": "Ruby",
  "vagrantfile": "Ruby",
  "brewfile": "Ruby",
  "cargo.toml": "Rust",
  "rust-toolchain": "Rust",
  "rust-toolchain.toml": "Rust",
  "go.mod": "Go",
  "go.sum": "Go",
  "package.json": "JavaScript",
  "package-lock.json": "JavaScript",
  "yarn.lock": "YAML",
  "pnpm-lock.yaml": "YAML",
  "tsconfig.json": "JSON",
  "pyproject.toml": "Python",
  "setup.py": "Python",
  "setup.cfg": "Python",
  "requirements.txt": "Python",
  "pipfile": "Python",
  "pipfile.lock": "JSON",
  "pom.xml": "XML",
  "build.gradle": "Groovy",
  "build.gradle.kts": "Kotlin",
  "settings.gradle": "Groovy",
  "settings.gradle.kts": "Kotlin",
  "pubspec.yaml": "YAML",
  "pubspec.lock": "YAML",
  "mix.exs": "Elixir",
  "mix.lock": "JSON",
  "cabal": "Haskell",
  "stack.yaml": "YAML",
  "package.yaml": "YAML",
  "dub.json": "D",
  "dub.sdl": "D",
  ".gitignore": "Git Ignore",
  ".dockerignore": "Docker Ignore",
  ".editorconfig": "Config",
  ".eslintrc": "JSON",
  ".prettierrc": "JSON",
  "jest.config.js": "JavaScript",
  "jest.config.ts": "TypeScript",
  "webpack.config.js": "JavaScript",
  "webpack.config.ts": "TypeScript",
  "vite.config.js": "JavaScript",
  "vite.config.ts": "TypeScript",
  "next.config.js": "JavaScript",
  "next.config.mjs": "JavaScript",
  "nuxt.config.js": "JavaScript",
  "nuxt.config.ts": "TypeScript",
  "svelte.config.js": "JavaScript",
  "svelte.config.ts": "TypeScript",
  "astro.config.mjs": "JavaScript",
  "tailwind.config.js": "JavaScript",
  "tailwind.config.ts": "TypeScript",
  "postcss.config.js": "JavaScript",
  "postcss.config.cjs": "JavaScript",
  "babel.config.js": "JavaScript",
  ".babelrc": "JSON",
  "rollup.config.js": "JavaScript",
  "rollup.config.mjs": "JavaScript",
  "angular.json": "JSON",
  "ionic.config.json": "JSON",
  "capacitor.config.json": "JSON",
  "capacitor.config.ts": "TypeScript",
  "firebase.json": "JSON",
  "vercel.json": "JSON",
  "netlify.toml": "TOML",
  "render.yaml": "YAML",
  "heroku.yml": "YAML",
  "app.json": "JSON",
  "procfile": "Config"
}.toTable

proc detectLanguage*(path: string): string =
  let name = extractFilename(path).toLowerAscii()
  if languageByFilename.hasKey(name):
    return languageByFilename[name]
  let ext = splitFile(path).ext.strip(chars = {'.'}).toLowerAscii()
  if ext.len == 0: return ""
  languageByExtension.getOrDefault(ext, "")

proc languageColorName*(language: string): string =
  case language
  of "Nim", "JavaScript", "TypeScript": "yellow"
  of "Rust", "Java", "Kotlin": "red"
  of "Python", "Ruby", "Dart": "blue"
  of "Go", "Zig", "Crystal": "cyan"
  of "C", "C++", "Objective-C": "gray"
  of "Swift": "orange"
  of "Scala", "Clojure": "magenta"
  of "Haskell", "OCaml", "F#": "purple"
  of "Elixir", "Lua": "green"
  of "Vue": "green"
  of "Svelte": "orange"
  of "Astro": "purple"
  of "Shell", "Bash", "Zsh": "green"
  of "PowerShell": "blue"
  of "SQL": "cyan"
  of "R": "blue"
  of "Julia": "purple"
  of "MATLAB": "orange"
  of "Assembly": "gray"
  of "Fortran": "blue"
  of "Pascal": "blue"
  of "Ada": "red"
  of "COBOL": "blue"
  of "HTML", "XML": "orange"
  of "CSS", "SCSS", "Sass", "LESS": "purple"
  of "Markdown": "white"
  of "JSON": "yellow"
  of "YAML": "red"
  of "TOML": "brown"
  else: "white"
