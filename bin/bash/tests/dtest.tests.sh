#!/bin/bash
set -euo pipefail

root="$(dirname "${BASH_SOURCE[0]}")/../.."
wrapper="$root/bash/dtest"
fixtures="$root/pwsh/tests"
export DTEST_FIXTURES="$fixtures"
export DTEST_DOTNET="$(dirname "${BASH_SOURCE[0]}")/mock-dotnet"
export DTEST_PYTHON="${DTEST_PYTHON:-python3}"

check() {
    local expected="$1" text="$2"
    [[ "$text" == *"$expected"* ]] || { printf 'Missing: %s\n%s\n' "$expected" "$text" >&2; exit 1; }
}

code=0
output="$(bash "$wrapper" --report "$fixtures/dtest-sample.trx")" || code=$?
[[ "$code" == 1 ]] || exit 1
check 'Expected: 2' "$output"
check 'Other failure' "$output"
check 'Failed:  2' "$output"
[[ "${output%%Failures:*}" != *'Expected: 2'* ]] || exit 1
[[ "${output%%Tests:*}" == *'Example.Tests.OtherTests.OtherFails'* ]] || exit 1
[[ "${output##*Tests:}" != *'Failures:'* ]] || exit 1

output="$(bash "$wrapper" --report "$fixtures/dtest-passing.trx")"
check 'Passed:  1' "$output"
[[ "$output" != *'Failures:'* ]] || exit 1

code=0
output="$(bash "$wrapper" --filter 'Name~Example with spaces')" || code=$?
[[ "$code" == 0 ]] || { printf '%s\n' "$output" >&2; exit 1; }
for stage in 'Preparing test run' 'Restoring' 'Building' 'Running tests'; do check "$stage" "$output"; done
check 'Passed:  1' "$output"

export DTEST_MOCK_FAILURE=tests
code=0
output="$(bash "$wrapper")" || code=$?
[[ "$code" == 1 ]] || exit 1
check 'Failures:' "$output"
check 'Failed:  2' "$output"

export DTEST_MOCK_FAILURE=build
code=0
output="$(bash "$wrapper" 2>&1)" || code=$?
[[ "$code" == 1 ]] || exit 1
check 'Build FAILED.' "$output"
check 'No test results found.' "$output"

code=0
output="$(bash "$wrapper" --report "$fixtures/does-not-exist.trx" 2>&1)" || code=$?
[[ "$code" == 1 ]] || exit 1
check 'dtest:' "$output"

printf 'Bash dtest checks passed.\n'
