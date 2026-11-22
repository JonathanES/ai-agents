---
description: Implement a feature or fix with the FastAPI or Next.js engineer (add --tdd to work test-first)
argument-hint: "[--tdd] <feature or bug description>"
---

Task: $ARGUMENTS

1. Work out which stack the task touches. Look for `pyproject.toml` / FastAPI imports versus
   `package.json` with `next` / `react`, and at the paths the task mentions.
2. Delegate to the matching subagent:
   - Python / FastAPI → `fastapi-engineer`
   - React / Next.js / TypeScript → `nextjs-engineer`
   - Both → backend first (it defines the API contract), then frontend.
3. Pass the task through without `--tdd`. If the arguments contain `--tdd`, or the task asks
   for TDD / test-first, tell the agent explicitly: "Work in TDD mode: load the `tdd` skill
   and follow it."
4. When the agent finishes, run the `code-reviewer` subagent on the resulting changes and
   show both the implementation report and the review.
