---
description: Review the current branch, an MR/PR number, or a path with the code-reviewer agent
argument-hint: "[MR/PR number | branch | path]"
---

Use the `code-reviewer` subagent to review: $ARGUMENTS

If no argument is given, review the current branch against its merge base with the default
branch, plus uncommitted changes.

Return the agent's output unchanged: the summary line followed by one templated comment per
finding.
