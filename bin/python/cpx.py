#!/usr/bin/env python3

import sys
import re


def is_measurement(s: str) -> bool:
    return re.fullmatch(r'(\d+(?:\.\d+)?)([a-zA-Z]+)', s) is not None


def split_measurement(s: str):
    m = re.fullmatch(r'(\d+(?:\.\d+)?)([a-zA-Z]+)', s)
    if not m:
        print(f'invalid argument: {s}', file=sys.stderr)
        sys.exit(1)
    return float(m.group(1)), m.group(2).casefold()


def px_to_em(px: float, base: float) -> float:
    return px / base


def em_to_px(em: float, base) -> float:
    return em * base


def print_conversion(px: float, em: float, base: float):
    print(f'      {px:g}px')
    print(f'      {em:g}em ')
    print(f'      (base font size: {base:g}px)')


def main():
    if len(sys.argv) < 2:
        print('usage: cpx <measurement> [<measurement> ...] [<base font size>]',
              file=sys.stderr)
        sys.exit(1)
    args = sys.argv[1:]
    default_base_font_size = 16.0
    if not is_measurement(sys.argv[-1]):
        default_base_font_size = float(sys.argv[-1])

    for arg in args:
        if not is_measurement(arg) and float(arg) == default_base_font_size:
            continue

        n, unit = split_measurement(arg)

        if (unit == 'px'.casefold()):
            px = n
            em = px_to_em(px, default_base_font_size)
            print_conversion(px, em, default_base_font_size)
        elif (unit == 'em'.casefold() or unit == 'rem'.casefold()):
            em = n
            px = em_to_px(em, default_base_font_size)
            print_conversion(px, em, default_base_font_size)
        else:
            print(f'invalid unit: {unit}', file=sys.stderr)
            sys.exit(1)

    exit(0)


if __name__ == '__main__':
    main()
