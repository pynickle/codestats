#!/usr/bin/env python3
"""Extract GitHub language colors and generate Nim color mapping."""

import re
from collections import defaultdict
from pathlib import Path


def hex_to_rgb(hex_color):
    """Convert #RRGGBB to RGB tuple."""
    hex_color = hex_color.strip('#"')
    if len(hex_color) != 6:
        return (0, 0, 0)
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def rgb_to_term_color(r, g, b):
    """Map RGB to closest ANSI terminal color."""
    # Calculate luminance and saturation
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    max_c = max(r, g, b)
    min_c = min(r, g, b)
    saturation = (max_c - min_c) / max_c if max_c > 0 else 0

    # Low saturation = grayscale
    if saturation < 0.15:
        return "white" if luminance >= 64 else "black"

    # Determine dominant hue
    if r > g and r > b:
        if r > 180 and g < 100:
            return "red"
        elif g > 100 and g > b:
            return "yellow"  # Orange/yellow
        else:
            return "red"
    elif g > r and g > b:
        if b < 100:
            return "yellow"  # Yellow-green
        else:
            return "green"
    elif b > r and b > g:
        if r > 100 or g > 100:
            return "cyan"  # Light blue
        else:
            return "blue"
    elif r > 150 and b > 150 and g < 150:
        return "magenta"
    elif r > 150 and g > 150:
        return "yellow"
    elif g > 150 and b > 150:
        return "cyan"
    else:
        return "white"


def extract_colors(yaml_path):
    """Extract language -> color mapping from languages.yml."""
    color_map = {}
    current_lang = None

    with open(yaml_path, 'r', encoding='utf-8') as f:
        for line in f:
            # Match language name (starts at column 0, ends with :)
            if line and line[0].isupper() and line.rstrip().endswith(':'):
                current_lang = line.rstrip()[:-1]
            # Match color line (indented with "  color:")
            elif line.startswith('  color:') and current_lang:
                color = line.split(':', 1)[1].strip()
                color_map[current_lang] = color

    return color_map


def generate_nim_code(color_map, supported_langs):
    """Generate Nim code for languageColorName proc."""
    print("proc languageColorName*(language: string): string =")
    print('  ## Map language to terminal color based on GitHub colors')
    print('  case language')

    # Group languages by terminal color
    color_groups = defaultdict(list)
    for lang, hex_color in color_map.items():
        # Only include languages we support
        if lang not in supported_langs:
            continue

        r, g, b = hex_to_rgb(hex_color)
        term_color = rgb_to_term_color(r, g, b)
        color_groups[term_color].append(lang)

    # Output in color order
    color_order = ['red', 'yellow', 'green', 'cyan', 'blue', 'magenta', 'white', 'black']
    for color in color_order:
        if color in color_groups:
            langs = sorted(color_groups[color])
            langs_str = '", "'.join(langs)
            print(f'  of "{langs_str}": "{color}"')

    print('  else: "white"')


def get_supported_languages():
    """Extract currently supported languages from languages.nim."""
    # Read from languageByExtension
    langs = set()

    # Common languages from the mapping
    langs.update([
        "C", "C++", "Rust", "Go", "Zig", "D",
        "Python", "Ruby", "Perl", "Lua", "PHP",
        "JavaScript", "TypeScript", "React",
        "Vue", "Svelte", "Astro",
        "Haskell", "OCaml", "F#",
        "Clojure", "Elixir",
        "Lisp", "Common Lisp", "Emacs Lisp",
        "Scheme", "Racket",
        "Scala", "Java", "Kotlin", "Groovy",
        "C#", "VB.NET",
        "Swift", "Objective-C", "Dart",
        "R", "R Markdown", "Julia",
        "SQL",
        "Shell", "PowerShell", "Batch", "Tcl",
        "HTML", "CSS", "SCSS", "Sass", "LESS", "Stylus",
        "Markdown", "MDX", "reStructuredText", "AsciiDoc",
        "LaTeX",
        "JSON", "JSON5", "YAML", "TOML", "INI", "Config",
        "XML", "CSV", "TSV",
        "GraphQL", "Protocol Buffers",
        "Dockerfile", "Makefile", "CMake",
        "Nim",
        "Assembly", "Crystal",
        "Pascal", "Ada", "VHDL", "SystemVerilog",
        "COBOL", "Fortran", "Prolog",
        "Smalltalk", "Squirrel", "Wren", "Nelua", "V",
        "MATLAB"
    ])

    return langs


if __name__ == '__main__':
    yaml_path = Path('bin/languages.yml')
    if not yaml_path.exists():
        print(f"Error: {yaml_path} not found")
        exit(1)

    color_map = extract_colors(yaml_path)
    supported_langs = get_supported_languages()

    print(f"# Extracted {len(color_map)} colors, using {len([l for l in color_map if l in supported_langs])} for supported languages")
    print()
    generate_nim_code(color_map, supported_langs)
