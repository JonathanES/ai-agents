# Hooks: Mechanical Safety Rules

Hooks enforce architecture rules automatically. They validate actions before execution and reject violations.

## Principle

**Safety is mechanical, not a matter of trust.**

Hooks ensure:
- Agents cannot exceed their tool boundaries
- Rules in referentiel are not duplicated
- Commands orchestrate instead of executing
- Architecture principles are followed

## Hook Types

### 1. Tool Restriction Hooks

Prevent agents from using tools outside their boundaries.

**Example**: `hooks/agent-tools-validator.py`

```python
# Agent tool boundaries (references agents/*/AGENT.md)
AGENT_TOOLS = {
    "code-reviewer": {
        "allowed": ["Read", "Grep", "Bash"],
        "bash_commands": ["git diff", "git log", "git show", "git status"],
        "forbidden": ["Write", "Edit", "WebFetch"]
    },
    "code-modifier": {
        "allowed": ["Read", "Write", "Edit"],
        "forbidden": ["Bash", "WebFetch"]
    }
}

def validate_tool_use(agent_name, tool_name, tool_args):
    """Validate before tool execution"""
    rules = AGENT_TOOLS.get(agent_name)
    if not rules:
        raise ValueError(f"Unknown agent: {agent_name}")

    if tool_name not in rules["allowed"]:
        raise ToolNotAllowedError(
            f"{agent_name} cannot use {tool_name}. "
            f"Allowed tools: {rules['allowed']}. "
            f"See agents/{agent_name}/AGENT.md for boundaries."
        )

    # Specific command validation for Bash
    if tool_name == "Bash" and "bash_commands" in rules:
        command = tool_args.get("command", "")
        allowed_prefixes = rules["bash_commands"]
        if not any(command.startswith(prefix) for prefix in allowed_prefixes):
            raise ToolNotAllowedError(
                f"{agent_name} can only use Bash for: {allowed_prefixes}. "
                f"Attempted: {command}"
            )
```

### 2. Referentiel Duplication Hooks

Prevent copying rules from referentiel into agent/skill files.

**Example**: `hooks/check-referentiel-duplication.sh`

```bash
#!/bin/bash
# Pre-commit hook: detect rule duplication

REFERENTIEL_RULES=(
    "Single Responsibility Principle"
    "Don't Repeat Yourself"
    "You Aren't Gonna Need It"
    "Design patterns are a remedy"
    "No boolean parameters"
)

# Check agents/ and skills/ for copied rules
for rule in "${REFERENTIEL_RULES[@]}"; do
    matches=$(git diff --cached agents/ skills/ | grep -i "$rule" | grep -v "referentiel/")
    if [ -n "$matches" ]; then
        echo "❌ Rule duplication detected: '$rule'"
        echo "   Rules must live in referentiel/ only"
        echo "   Reference the file instead: 'See referentiel/principes-architectures.md'"
        exit 1
    fi
done

# Ensure referentiel files are referenced, not copied
if git diff --cached agents/ skills/ | grep -E "SRP|DRY|YAGNI" | grep -v "referentiel/"; then
    echo "⚠️  Warning: Mention of architecture principle without referentiel reference"
    echo "   Always reference: 'See referentiel/principes-architectures.md#section'"
fi
```

### 3. Command Orchestration Hooks

Ensure commands orchestrate instead of executing work.

**Example**: `hooks/validate-command.py`

```python
def validate_command(command_file):
    """Ensure command orchestrates, doesn't execute"""

    content = read_file(command_file)

    # Commands should delegate to agents
    if not contains_agent_calls(content):
        raise ValidationError(
            f"{command_file}: Command must orchestrate agents. "
            "See referentiel/architecture-systeme.md#commands"
        )

    # Commands shouldn't have direct tool use
    tool_patterns = ["Read(", "Write(", "Edit(", "Bash(", "Grep("]
    for pattern in tool_patterns:
        if pattern in content:
            raise ValidationError(
                f"{command_file}: Command should not use tools directly. "
                f"Delegate to agents instead. Found: {pattern}"
            )

def contains_agent_calls(content):
    """Check if command delegates to agents"""
    agent_patterns = [
        "run_agent(",
        "execute_agent(",
        "Task(subagent_type=",
        "agents/",
    ]
    return any(pattern in content for pattern in agent_patterns)
```

### 4. Architecture Principles Hooks

Enforce principles from `referentiel/principes-architectures.md`.

**Example**: `hooks/check-architecture-principles.sh`

```bash
#!/bin/bash
# Check changed code against architecture principles

echo "Checking architecture principles..."

# 1. No boolean parameters (except Optional[bool])
echo "→ Checking for boolean parameters..."
if git diff --cached "*.py" | grep -E "def .+\(.+(: ?bool|=True|=False)" | grep -v "Optional\[bool\]"; then
    echo "❌ Boolean parameter detected"
    echo "   Use alternatives: referentiel/principes-architectures.md#no-boolean-parameters"
    exit 1
fi

# 2. No business logic in models
echo "→ Checking business logic placement..."
if git diff --cached "*/models.py" | grep -A 10 "class.*Model" | grep -E "def (calculate|process|apply|validate)"; then
    echo "❌ Business logic detected in model"
    echo "   Move to logic.py: referentiel/principes-architectures.md#business-logic-placement"
    exit 1
fi

# 3. Check for feature envy (accessing other app's data)
echo "→ Checking for feature envy..."
# This is more complex, would need actual parsing

echo "✅ Architecture principles check passed"
```

## Hook Installation

### Git Hooks

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run all architecture validation hooks

HOOKS_DIR="hooks"

echo "Running architecture validation hooks..."

# 1. Check referentiel duplication
bash $HOOKS_DIR/check-referentiel-duplication.sh || exit 1

# 2. Check architecture principles
bash $HOOKS_DIR/check-architecture-principles.sh || exit 1

# 3. Validate commands
python $HOOKS_DIR/validate-command.py || exit 1

echo "✅ All hooks passed"
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

### CI/CD Integration

```yaml
# .github/workflows/architecture-validation.yml
name: Architecture Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Check referentiel duplication
        run: bash hooks/check-referentiel-duplication.sh

      - name: Check architecture principles
        run: bash hooks/check-architecture-principles.sh

      - name: Validate commands
        run: python hooks/validate-command.py

      - name: Validate agent tool boundaries
        run: python hooks/agent-tools-validator.py --check-all
```

## Writing New Hooks

### Checklist

- [ ] Hook validates mechanically, doesn't just warn
- [ ] Clear error message with referentiel reference
- [ ] No bypass possible (unless explicitly designed)
- [ ] Fast execution (< 1 second)
- [ ] Tested with positive and negative cases
- [ ] Documented in this README

### Template

```python
def validate_[rule_name](target):
    """
    Validate [what rule] from referentiel/[file].md

    Args:
        target: What to validate

    Raises:
        ValidationError: If rule is violated, with clear message

    Examples:
        >>> validate_rule(good_case)  # passes
        >>> validate_rule(bad_case)   # raises ValidationError
    """

    if violates_rule(target):
        raise ValidationError(
            f"❌ [Rule name] violation\n"
            f"   Problem: [describe what's wrong]\n"
            f"   Fix: [how to fix it]\n"
            f"   Reference: referentiel/[file].md#[section]"
        )
```

## Hook Examples from This Repo

None yet - hooks to be implemented.

**Priority hooks to implement**:
1. Agent tool boundary validation
2. Referentiel duplication detection
3. Boolean parameter detection
4. Business logic placement validation
5. Command orchestration validation

## Testing Hooks

```bash
# Test hook with good input
python hooks/validate-command.py commands/review.md
# Should pass

# Test hook with bad input
python hooks/validate-command.py tests/fixtures/bad-command.md
# Should fail with clear message

# Test all hooks
bash hooks/run-all-tests.sh
```

## Notes

- Hooks are **preventive**, not advisory
- Error messages must be **actionable** and reference **referentiel**
- Hooks should be **fast** - they run on every commit/push
- Critical rules **cannot be bypassed** without explicit justification
- Hooks are tested like any other code

## See Also

- `referentiel/architecture-systeme.md#hooks` - Architecture documentation
- `referentiel/principes-architectures.md` - Principles to enforce
- Templates for validation patterns (to be created)
