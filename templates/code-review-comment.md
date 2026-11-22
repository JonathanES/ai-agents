<!--
Template for ONE review comment (one finding). The code-reviewer agent outputs one of these
per finding, ordered by severity (🔴 → 🟠 → 🟡).

Rules:
- 3 to 5 bullets in "Why", no more and no less.
- Both <details> blocks are required. Keep the blank line after <summary> so the
  markdown inside renders on GitLab and GitHub.
- The fix prompt must be self-contained: an agent with no other context must be able to
  apply it.
Delete this comment block from the output.
-->
### {{severity_emoji}} {{title}} · `{{file_path}}:{{line}}`

**Principle:** {{DRY | SRP | Strategy over if/else | TDD | Correctness}}

- {{what the code does now, and where}}
- {{which principle or rule it breaks and why that matters here}}
- {{concrete risk: bug, drift, cost of the next change, untested path}}
- {{optional: related places in the codebase that show the same problem}}
- {{optional: what "good" looks like in one sentence}}

<details>
<summary>💡 Potential fix</summary>

{{one or two sentences describing the change}}

```{{language}}
{{suggested code: minimal, compilable, matching the project's style}}
```

</details>

<details>
<summary>🤖 Prompt for an agent to fix it</summary>

```text
In {{file_path}} (around line {{line}}), {{problem in one sentence}}.

Goal: {{target design, e.g. "extract a PaymentStrategy protocol with one implementation
per provider and select it from a registry"}}.

Steps:
1. Following TDD, first add or adjust a test in {{test_file_path}} that pins the current
   behaviour of {{unit}} (it must pass before the refactor).
2. {{refactor step}}
3. {{refactor step}}
4. Update the callers: {{list of call sites}}.
5. Run {{test command}} and make sure the whole suite is green.

Constraints: don't change public behaviour or API contracts; keep the change limited
to {{scope}}.
```

</details>
