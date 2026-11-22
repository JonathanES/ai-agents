---
name: skill-name
description: Brief description of what this skill provides
type: knowledge | tool | hybrid
---

# Skill Name

[Brief introduction to what this skill is and when to use it]

## Type

**[Knowledge | Tool | Hybrid]**

- **Knowledge**: Process, methodology, or domain expertise
- **Tool**: Executable script or deterministic tool
- **Hybrid**: Both knowledge and executable components

## Purpose

[Detailed explanation of what problem this skill solves and when to use it]

## Usage

### By Agents

This skill should be used when:
- [Scenario 1]
- [Scenario 2]
- [Scenario 3]

### Prerequisites

- [Required dependencies]
- [Required setup]
- [Required knowledge]

## Content

### [Section 1: For Knowledge Skills]

[Detailed process, steps, methodology]

**Example**:
```
[Code or process example]
```

### [Section 2: For Tool Skills]

**Installation**:
```bash
pip install dependency
```

**Script Location**: `skills/[skill-name]/scripts/[script-name].py`

**Usage**:
```python
from skills.skill_name.scripts import tool_function

result = tool_function(input_data)
```

**Output**:
```
[Description of what the tool produces]
```

## Examples

### Example 1: [Use Case]

**Input**: [What you start with]

**Process**: [Steps followed]

**Output**: [What you get]

### Example 2: [Another Use Case]

**Input**: [What you start with]

**Process**: [Steps followed]

**Output**: [What you get]

## Referentiel References

This skill references:
- `referentiel/[file1].md`: [What it uses from this file]
- `referentiel/[file2].md`: [What it uses from this file]

**Important**: This skill does NOT duplicate referentiel content. It references it.

## Testing

### For Tool Skills

Tests are located in: `tests/skills/test_[skill-name].py`

```python
def test_skill_function():
    result = skill_function(test_input)
    assert result == expected_output
```

### For Knowledge Skills

Validation checklist:
- [ ] Process is documented clearly
- [ ] Examples are correct and runnable
- [ ] References to referentiel are accurate
- [ ] No duplication of referentiel rules

## Determinism (For Tool Skills)

- [ ] Given same input, always produces same output
- [ ] No side effects unless documented
- [ ] No external API calls unless documented
- [ ] Error handling is predictable

## Notes

- [Important information about this skill]
- [Limitations or constraints]
- [Known issues or edge cases]

## Related Skills

- `skills/[related-skill-1]`: [How they relate]
- `skills/[related-skill-2]`: [How they relate]
