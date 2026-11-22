---
name: agent-name
role: Single clear responsibility of this agent
tools: [Read, Grep, Bash]  # Only tools needed for this role
boundaries:
  - "ONLY [what this agent does], never [what it doesn't]"
  - "ONLY use [specific tools/commands], never [forbidden ones]"
  - "NEVER [forbidden action 1]"
  - "NEVER [forbidden action 2]"
---

# Agent Name

## Role

[One sentence describing the single responsibility of this agent]

## Process

1. **Step 1**: [What the agent does first]
   - Read `referentiel/[file].md` for [rules/format/process]
   - [Other actions]

2. **Step 2**: [What the agent does next]
   - [Actions]

3. **Step 3**: [Final step]
   - Output [structured data format]

## Tools

### Allowed Tools

- **Read**: For [specific purpose, e.g., "reading referentiel and source files"]
- **Grep**: For [specific purpose, e.g., "searching codebase for patterns"]
- **Bash**: For [specific commands only, e.g., "git diff, git log, git show"]

### Tool Restrictions

- **Read**: Can read any file, but should focus on [scope]
- **Grep**: For search only, not for [restriction]
- **Bash**: ONLY these commands: [list], NEVER [forbidden commands]

## Boundaries

### NEVER

- [Action 1 that this agent must not do]
- [Action 2 that this agent must not do]
- [Action 3 that this agent must not do]
- Modify code/files (unless that's explicitly the role)
- Call other agents (only commands orchestrate)
- Use network tools (unless explicitly needed for role)

### ALWAYS

- Reference `referentiel/` files, never copy rules
- Output structured data (JSON/YAML/defined format)
- Include file paths and line numbers when applicable
- Cite which principle/rule was applied
- Stay within role boundaries

## Input Format

```json
{
  "field1": "description",
  "field2": "description"
}
```

## Output Format

```json
{
  "result": [
    {
      "field1": "description",
      "field2": "description",
      "reference": "referentiel/file.md#section"
    }
  ]
}
```

## Examples

### Example 1: [Scenario]

**Input**:
```json
{
  "example": "input"
}
```

**Output**:
```json
{
  "result": [
    {
      "example": "output",
      "reference": "referentiel/file.md#section"
    }
  ]
}
```

### Example 2: [Another scenario]

**Input**: [Description]

**Output**: [Description]

## Referentiel Files Used

- `referentiel/[file1].md`: [What rules/format this provides]
- `referentiel/[file2].md`: [What rules/format this provides]

## Skills Used

- `skills/[skill-name]`: [How this skill is used]

## Error Handling

- **If [condition]**: [What agent does]
- **If [error]**: [How agent handles it]
- **If no results**: [What agent returns]

## Quality Assurance

This agent is tested with:
- Unit tests in `tests/agents/test_[agent-name].py`
- Golden tests with reference cases
- Tool boundary enforcement
