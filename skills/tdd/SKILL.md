---
name: tdd
description: Test-Driven Development following Kent Beck / Martin Fowler (test list, then red → green → refactor, one test at a time). Use when asked to work test-first, do TDD or red-green-refactor, or when a coding agent is told to implement a feature or fix with TDD.
---

# Test-Driven Development

Source: https://martinfowler.com/bliki/TestDrivenDevelopment.html

TDD drives the design of the software by writing tests first. It has three steps, repeated
one small piece of behaviour at a time:

1. **Red**: write a test for the next bit of functionality you want to add.
2. **Green**: write the functional code until the test passes.
3. **Refactor**: clean up both the new and the old code so it's well structured.

You also need to **write the test list first** and **never skip the refactor step**.

## 0. Write the test list first

Before you write any code, list the test cases the change needs, in plain language. Put the
list in your working notes (or a TODO in the test file) and keep it up to date:

- Include the happy paths, edge cases, error cases and boundaries.
- **Order matters.** Pick the next test so it drives the design forward: start with the
  simplest case that makes you create the interface, then work toward the harder cases.
- Whenever a new case comes to mind, **add it to the list** instead of jumping to it right away.
- When fixing a bug, the first test on the list is one that reproduces the bug.

## 1. Red: one failing test

- Write **exactly one** test, the next one on the list.
- Write it from the caller's point of view. This is the moment to design the **interface**
  (names, arguments, return shape). Keep the interface separate from the implementation.
- Run it and **watch it fail for the expected reason** (an assertion failure, not an import or
  syntax error). If it passes right away, it isn't testing anything new: fix the test or
  cross it off the list.

## 2. Green: the simplest code that passes

- Write only as much production code as you need to make that test pass. Hard-coded values
  and obvious shortcuts are fine here; later tests will force them to become general.
- Don't add behaviour that no test asks for.
- Run the **whole** relevant suite, not just the new test. Every test must be green before
  you move on.

## 3. Refactor: mandatory, never skipped

Fowler: *"The most common way that I hear to screw up TDD is neglecting the third step."*
If you skip it, you end up with "a messy aggregation of code fragments".

With all tests green:

- Remove duplication, in both the production code and the tests (DRY).
- Improve names, split functions or classes that have more than one responsibility (SRP),
  and replace growing `if/elif`/`switch` chains on a type or kind with a Strategy.
  See `referentiel/principes-architectures.md` for principles and the `clean-code-review` skill for review process.
- Clean up **old code the new code touches**, not just the lines you just wrote.
- Change structure only, never behaviour. Run the tests after each refactoring move and keep
  them green.

Then cross the test off the list and go back to **Red** for the next one.

## Rules

- Never write production code without a failing test that needs it.
- One test per cycle. Small steps. If a step feels big, split the test.
- A red suite is a stop sign: don't start a new test until everything is green.
- Test behaviour through public interfaces, not private helpers or implementation details,
  so that refactoring doesn't break the tests.
- Tests must be fast, deterministic and isolated. Fake time, network, randomness and the
  database boundary where needed.
- The result is **self-testing code**: every piece of functional code exists because a test
  asked for it.

## Reporting

When you finish, report the test list with each item checked off, and point out any items
you deliberately left open. Use the `implementation-report` template if the caller asks for a
structured summary.
