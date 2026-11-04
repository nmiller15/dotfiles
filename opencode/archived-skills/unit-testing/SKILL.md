---
name: Unit Tests
description: Plan and implement targeted unit tests for new or changed business logic.
---

## Workflow

1. Check whether `UNIT_TEST_PLAN.md` exists in the project root.
2. If it exists, read it and proceed to step 5.
3. If it does not exist:
   - Select the appropriate context.
   - Identify new or changed business logic that warrants unit tests.
   - Create `UNIT_TEST_PLAN.md` with an ordered checklist of targeted tests.
   - Report that a plan has been created and exit.
5. Implement **only the next unfinished checklist item** in `UNIT_TEST_PLAN.md`.
6. Run the relevant tests and verify they pass.
7. Update `UNIT_TEST_PLAN.md` to reflect completion and record any findings that must persist between sessions.
8. Report the work completed, test results, and any remaining work to the user.

## Selecting Context

- If an open GitHub PR exists, analyze the PR's changes.
- Otherwise, analyze local, unmerged changes.
- Focus on new or modified business logic rather than unrelated code.
- If neither context contains relevant changes, report that no suitable work was found.

## Reporting Tests

- Tests should be reported in a table
- Display the test name, description of the behavior, lines of the source code implementation it is testing

## Unit Test Principles

- Test observable behavior: inputs, outputs, state changes, and externally visible side effects where relevant.
- Do not test implementation details or mirror the production code's internal structure.
- Prioritize meaningful business rules, boundary conditions, and failure cases.
- Keep tests targeted; comprehensive coverage is not the goal.
- Prefer property-based testing when it expresses an invariant or general rule more effectively than example-based tests.
- Use example-based tests when specific scenarios communicate the expected behavior more clearly.
- Follow the project's existing testing framework, conventions, and naming patterns.
- Do not modify production code solely to make tests pass without first identifying and reporting the underlying issue.
- Do not mark a checklist item complete until its tests have been run successfully. If tests fail, record the failure and leave the item unfinished.

## Scope

- Create unit tests **only for new or modified business logic** in the selected changeset.
- Do not add tests for pre-existing, unchanged business logic, even if it lacks coverage.
- If the changes contain no new or modified business logic that warrants testing, report that no tests are needed.
- Keep the plan limited to the relevant changes; do not expand into unrelated test coverage.
