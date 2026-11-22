---
name: command-name
description: Brief description of what this command does
---

# Command Name

## Purpose

[Describe the user-facing goal this command achieves]

## Orchestration

### Step 1: [Agent Name]

**Purpose**: [What this agent does]

**Input**: [What data it receives]

**Tools**: [List of tools this agent uses]

**Output**: [What data it produces]

### Step 2: [Agent Name]

**Purpose**: [What this agent does]

**Input**: [What data it receives from previous step]

**Tools**: [List of tools this agent uses]

**Output**: [What data it produces]

### Step 3: [Agent Name]

**Purpose**: [What this agent does]

**Input**: [What data it receives]

**Tools**: [List of tools this agent uses]

**Output**: [Final output to user]

## Flow Control

- [ ] Steps run sequentially / in parallel / conditionally
- [ ] If [condition] → skip steps X-Y
- [ ] If [agent] fails → retry [N] times / skip / fail command
- [ ] Data passed between steps: [describe how]

## Error Handling

- **[Agent] fails**: [What happens]
- **Invalid input**: [What happens]
- **Partial completion**: [What happens]

## Usage

```bash
/command-name [arguments]
```

**Examples**:
```bash
/command-name example-arg
/command-name --option value
```

## Notes

- [Any important information about this command]
- [Limitations or constraints]
- [References to referentiel files if applicable]
