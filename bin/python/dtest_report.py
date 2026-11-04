#!/usr/bin/env python3
"""Format VSTest TRX reports as class lists and aggregated failures."""

import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from dataclasses import dataclass
from datetime import timedelta
from pathlib import Path


@dataclass(frozen=True)
class Result:
    class_name: str
    name: str
    outcome: str
    duration: str
    message: str
    stack: str


def child(element: ET.Element | None, name: str) -> ET.Element | None:
    if element is None:
        return None
    return next((node for node in element if node.tag.rsplit('}', 1)[-1] == name), None)


def children(element: ET.Element | None, name: str) -> list[ET.Element]:
    return [] if element is None else [
        node for node in element if node.tag.rsplit('}', 1)[-1] == name
    ]


def text(element: ET.Element | None) -> str:
    return '' if element is None else ''.join(element.itertext())


def read_report(path: Path) -> list[Result]:
    # TRX files do not need DTDs or entity expansion.
    if b'<!DOCTYPE' in path.read_bytes().upper():
        raise ValueError(f'DTD not allowed in {path}')
    root = ET.parse(path).getroot()
    if root.tag.rsplit('}', 1)[-1] != 'TestRun':
        raise ValueError(f'not a TRX TestRun: {path}')
    definitions = {}
    for unit in children(child(root, 'TestDefinitions'), 'UnitTest'):
        method = child(unit, 'TestMethod')
        if method is not None:
            definitions[unit.get('id')] = method.get('className', '')

    results = []
    for unit in children(child(root, 'Results'), 'UnitTestResult'):
        class_name = definitions.get(unit.get('testId')) or '(unknown class)'
        name = unit.get('testName', '')
        for prefix in (class_name + '.', class_name.rsplit('.', 1)[-1] + '.'):
            if name.startswith(prefix):
                name = name[len(prefix):]
                break
        error = child(child(unit, 'Output'), 'ErrorInfo')
        results.append(Result(class_name, name, unit.get('outcome', ''),
                              unit.get('duration', ''), text(child(error, 'Message')),
                              text(child(error, 'StackTrace'))))
    return results


def duration_label(duration: str) -> str:
    match = re.fullmatch(r'(\d+):([0-5]\d):([0-5]\d)(?:\.(\d+))?', duration)
    if not match:
        return ''
    hours, minutes, seconds = (int(value) for value in match.group(1, 2, 3))
    fraction = (match.group(4) or '')[:7].ljust(7, '0')
    total_ms = (timedelta(hours=hours, minutes=minutes, seconds=seconds).total_seconds()
                * 1000 + int(fraction) / 10000)
    return f' ({total_ms:,.0f} ms)'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('reports', type=Path, nargs='+', help='TRX report files')
    args = parser.parse_args()
    try:
        results = [result for path in args.reports for result in read_report(path)]
    except (OSError, ET.ParseError, ValueError) as error:
        print(f'dtest: {error}', file=sys.stderr)
        return 1
    if not results:
        print('No test results found. Check the test runner and filter.', file=sys.stderr)
        return 1

    color = sys.stdout.isatty() and not os.getenv('NO_COLOR')

    def paint(value: str, code: int) -> str:
        return f'\033[{code}m{value}\033[0m' if color else value

    def label(result: Result, *, details: bool = False) -> None:
        passed = result.outcome == 'Passed'
        skipped = result.outcome in ('NotExecuted', 'Skipped')
        icon, shade = ('✓', 32) if passed else (('○', 33) if skipped else ('✗', 31))
        name = (result.class_name + '.' if details else '') + result.name
        print('  ' + paint(icon, shade) + ' ' + paint(
            name + duration_label(result.duration), 90 if passed else shade))
        if details:
            for value in (result.message, result.stack):
                for line in value.splitlines():
                    if line.strip():
                        print(paint('      ' + line, 31))

    groups: dict[str, list[Result]] = defaultdict(list)
    for result in results:
        groups[result.class_name].append(result)
    print()
    for class_name in sorted(groups):
        print(paint(class_name, 36))
        for result in groups[class_name]:
            label(result)
        print()

    failures = [r for r in results if r.outcome not in ('Passed', 'NotExecuted', 'Skipped')]
    if failures:
        print(paint('Failures:', 31))
        for result in failures:
            label(result, details=True)
            print()

    passed = sum(r.outcome == 'Passed' for r in results)
    skipped = sum(r.outcome in ('NotExecuted', 'Skipped') for r in results)
    print('Tests:')
    print('  Passed:  ' + paint(str(passed), 32))
    print('  Failed:  ' + paint(str(len(failures)), 31 if failures else 90))
    print('  Skipped: ' + paint(str(skipped), 33 if skipped else 90))
    print(f'  Total:   {len(results)}')
    print(f'  Classes: {len(groups)}')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
