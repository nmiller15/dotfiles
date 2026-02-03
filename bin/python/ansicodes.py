#!/usr/bin/env python3

import argparse
from dataclasses import dataclass
from enum import Enum, auto


class Category(Enum):
    TEXT = auto()
    COLOR = auto()
    BG_COLOR = auto()
    SCREEN = auto()
    CURSOR = auto()


class Lang(Enum):
    CSHARP = auto()
    PYTHON = auto()
    JAVASCRIPT = auto()


@dataclass(frozen=True)
class AnsiCode:
    name: str
    seq: str
    description: str
    category: Category


ANSI_CODES = [
    AnsiCode("RESET", "\033[0m", "Reset / clear all", Category.TEXT),
    AnsiCode("BOLD", "\033[1m", "Bold (bright)", Category.TEXT),
    AnsiCode("DIM", "\033[2m", "Dim", Category.TEXT),
    AnsiCode("ITALIC", "\033[3m", "Italic", Category.TEXT),
    AnsiCode("UNDERLINE", "\033[4m", "Underline", Category.TEXT),
    AnsiCode("BLINK", "\033[5m", "Blink (often unsupported)", Category.TEXT),
    AnsiCode("REVERSE", "\033[7m", "Reverse (invert fg/bg)", Category.TEXT),
    AnsiCode("STRIKETHROUGH", "\033[9m", "Strikethrough", Category.TEXT),

    AnsiCode("BLACK", "\033[30m", "Black", Category.COLOR),
    AnsiCode("RED", "\033[31m", "Red", Category.COLOR),
    AnsiCode("GREEN", "\033[32m", "Green", Category.COLOR),
    AnsiCode("YELLOW", "\033[33m", "Yellow", Category.COLOR),
    AnsiCode("BLUE", "\033[34m", "Blue", Category.COLOR),
    AnsiCode("MAGENTA", "\033[35m", "Magenta", Category.COLOR),
    AnsiCode("CYAN", "\033[36m", "Cyan", Category.COLOR),
    AnsiCode("WHITE", "\033[37m", "White", Category.COLOR),

    AnsiCode("BLACK", "\033[40m", "Black", Category.BG_COLOR),
    AnsiCode("RED", "\033[41m", "Red", Category.BG_COLOR),
    AnsiCode("GREEN", "\033[42m", "Green", Category.BG_COLOR),
    AnsiCode("YELLOW", "\033[43m", "Yellow", Category.BG_COLOR),
    AnsiCode("BLUE", "\033[44m", "Blue", Category.BG_COLOR),
    AnsiCode("MAGENTA", "\033[45m", "Magenta", Category.BG_COLOR),
    AnsiCode("CYAN", "\033[46m", "Cyan", Category.BG_COLOR),
    AnsiCode("WHITE", "\033[47m", "White", Category.BG_COLOR),

    AnsiCode("CLEARSCREEN", "\033[2J ", "Clear screen", Category.SCREEN),
    AnsiCode("CLEARLNF", "\033[K  ", "Clear line (to right)", Category.SCREEN),
    AnsiCode("CLEARLNB", "\033[1K ", "Clear line (to left)", Category.SCREEN),
    AnsiCode("CLEARLN", "\033[2K ", "Clear entire line", Category.SCREEN),

    AnsiCode("UP", "\033[A", "Cursor up", Category.CURSOR),
    AnsiCode("DOWN", "\033[B", "Cursor down", Category.CURSOR),
    AnsiCode("RIGHT", "\033[C", "Cursor right", Category.CURSOR),
    AnsiCode("LEFT", "\033[D", "Cursor left", Category.CURSOR),
    AnsiCode("HOME", "\033[H", "Move to home", Category.CURSOR),
    AnsiCode("POS", "\033[row;colH", "Move to position", Category.CURSOR),
]


def output(s: str):
    print(s.join(" " * 10))


def print_javascript(code: AnsiCode):
    print(f'const {code.name} = "{
          code.seq.encode('unicode_escape').decode()}";')


def print_python(code: AnsiCode):
    print(f'{code.name} = "{code.seq.encode('unicode_escape').decode()}"')


def print_csharp(code: AnsiCode):
    print(f'private const string {code.name} = "{
          code.seq.encode('unicode_escape').decode()}";')


def print_constants(lang: Lang, codes: list[AnsiCode]):
    for code in codes:
        match lang:
            case Lang.CSHARP:
                print_csharp(code)
            case Lang.PYTHON:
                print_python(code)
            case Lang.JAVASCRIPT:
                print_javascript(code)


def print_code(code: AnsiCode):
    print(f'{code.seq.encode('unicode_escape').decode():<15} {
          code.description:<25}')


def print_code_group(label: str, codes: list[AnsiCode]):
    print(label)
    print()
    for code in codes:
        print_code(code)
    print()
    print()


def print_codes(codes: list[AnsiCode]):
    print()
    print()
    if any(code.category == Category.COLOR for code in codes):
        print_code_group("Foreground Color:",
                         [code for code in codes if code.category == Category.COLOR])

    if any(code.category == Category.BG_COLOR for code in codes):
        print_code_group("Background Color:",
                         [code for code in codes if code.category == Category.BG_COLOR])

    if any(code.category == Category.TEXT for code in codes):
        print_code_group("Text Formatting:",
                         [code for code in codes if code.category == Category.TEXT])

    if any(code.category == Category.CURSOR for code in codes):
        print_code_group("Cursor Movement:",
                         [code for code in codes if code.category == Category.CURSOR])

    if any(code.category == Category.SCREEN for code in codes):
        print_code_group("Screen Control:",
                         [code for code in codes if code.category == Category.SCREEN])


def filter_codes(codes: list[AnsiCode], args) -> list[AnsiCode]:
    filtered_codes = []
    if (not args.text and not args.screen and not args.pointer and not args.color and not args.bg_color):
        args.color = True

    if args.text:
        filtered_codes.extend(
            [code for code in codes if code.category == Category.TEXT])
    if args.screen:
        filtered_codes.extend(
            [code for code in codes if code.category == Category.SCREEN])
    if args.pointer:
        filtered_codes.extend(
            [code for code in codes if code.category == Category.CURSOR])
    if (args.color):
        filtered_codes.extend(
            [code for code in codes if code.category == Category.COLOR])
    if (args.bg_color):
        filtered_codes.extend(
            [code for code in codes if code.category == Category.BG_COLOR])

    return filtered_codes


def main():
    parser = argparse.ArgumentParser(
        "argparse",
        description="ansicodes - Display ANSI escape codes for text formatting and colors.")

    subparsers = parser.add_subparsers(dest="command", required=False)
    constants = subparsers.add_parser(
        "constants", help="Display ANSI escape codes as constants")
    constants.add_argument(
        "--lang", "-l", choices=["python", "csharp", "javascript"], default="python", help="Output language")

    parser.add_argument("-c", "--color", action="store_true",
                        help="Display foreground color codes (default)")
    parser.add_argument("-a", "--all", action="store_true",
                        help="Display all ANSI codes")
    parser.add_argument("-bg", "--bg-color", action="store_true",
                        help="Display background color codes")
    parser.add_argument("-t", "--text", action="store_true",
                        help="Display text formatting codes")
    parser.add_argument("-s", "--screen", action="store_true",
                        help="Display screen clearing codes")
    parser.add_argument("-p", "--pointer", action="store_true",
                        help="Display cursor movement codes")

    args = parser.parse_args()

    codes = []
    if args.all:
        codes = ANSI_CODES
    else:
        codes = filter_codes(ANSI_CODES, args)

    if args.command == "constants":
        print_constants(Lang[args.lang.upper()], codes)
    else:
        print_codes(codes)

    exit(0)


if __name__ == "__main__":
    main()
