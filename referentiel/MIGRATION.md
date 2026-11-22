# Migration Guide

Guide for refactoring existing components to follow the ai-agents architecture.

## Overview

This guide helps you:
1. Refactor agents to reference referentiel instead of duplicating rules
2. Convert commands that execute work into proper orchestrators
3. Update skills to avoid rule duplication
4. Add proper boundaries and tool restrictions to agents

## Before You Start

1. **Run validation**: `bash scripts/validate-architecture.sh`
2. **Read architecture**: `referentiel/architecture-systeme.md`
3. **Check examples**: Look at refactored skills in `skills/`

## Migration Checklist

### For Each Component

- [ ] Backup original file
- [ ] Apply refactoring
- [ ] Run validation script
- [ ] Test component works correctly
- [ ] Update documentation if needed

## 1. Migrating an Agent

### Problem: Agent Duplicates Rules

**Before** (anti-pattern):
```markdown
# agents/my-agent.md

## Principles

### DRY: Don't Repeat Yourself

Every piece of knowledge must have a single representation...
[Full DRY explanation copied from somewhere]

### SRP: Single Responsibility Principle

A module should have one reason to change...
[Full SRP explanation copied from somewhere]
```

**After** (correct pattern):
```markdown
# agents/my-agent.md
---
name: my-agent
role: Clear single responsibility
tools: [Read, Grep, Bash]
boundaries:
  - "ONLY [what this agent does]"
  - "NEVER [what it doesn't do]"
---

## Role

[One sentence describing the single responsibility]

## Principles Source

**ALWAYS read** `referentiel/principes-architectures.md` before executing.

This agent applies:
- **DRY** - `referentiel/principes-architectures.md#dry`
- **SRP** - `referentiel/principes-architectures.md#srp`

## Process

1. Read `referentiel/principes-architectures.md`
2. [Agent-specific steps...]
```

### Steps to Refactor

1. **Identify duplicated rules**
   ```bash
   grep -n "Don't Repeat Yourself\|Single Responsibility\|YAGNI" agents/my-agent.md
   ```

2. **Remove duplicated definitions**
   - Delete full explanations of principles
   - Keep only references to referentiel

3. **Add "Principles Source" section**
   ```markdown
   ## Principles Source

   **ALWAYS read** `referentiel/principes-architectures.md` before executing.

   This agent applies:
   - **[Principle]** - `referentiel/principes-architectures.md#section`
   ```

4. **Add "Read referentiel" to process**
   ```markdown
   ## Process

   1. Read `referentiel/principes-architectures.md`
   2. [Rest of agent process...]
   ```

5. **Keep agent-specific guidance**
   - Framework-specific examples (FastAPI, React)
   - Agent-specific workflow
   - Tool usage patterns

### Problem: Agent Missing Boundaries

**Before** (anti-pattern):
```markdown
# agents/my-agent.md

This agent reviews code and fixes issues.
```

**After** (correct pattern):
```markdown
# agents/my-agent.md
---
name: my-agent
role: Review code against principles
tools: [Read, Grep, Bash]
boundaries:
  - "ONLY analyze code, never modify"
  - "ONLY use git commands for inspection"
  - "NEVER post comments directly"
---

## Boundaries

### NEVER

- Modify code (use Write/Edit tools)
- Call other agents (only commands orchestrate)
- Exceed tool restrictions

### ALWAYS

- Reference referentiel files
- Output structured data
- Stay within role
```

### Steps to Add Boundaries

1. **Add frontmatter** with tools and boundaries
2. **Add Boundaries section** with NEVER/ALWAYS lists
3. **Document tool restrictions** clearly
4. **Specify output format** (structured data)

## 2. Migrating a Command

### Problem: Command Does Work Instead of Orchestrating

**Before** (anti-pattern):
```markdown
# commands/review-code.md

## Process

1. Read the code files
2. Check for DRY violations
3. Check for SRP violations
4. Format findings as comments
5. Post comments to MR
```

This command is doing all the work itself!

**After** (correct pattern):
```markdown
# commands/review-code.md

## Orchestration

### Step 1: code-reviewer Agent

**Purpose**: Analyze code against principles
**Input**: Branch or MR number
**Output**: findings.json

### Step 2: comment-formatter Agent

**Purpose**: Format findings according to referentiel template
**Input**: findings.json
**Output**: formatted_comments.json

### Step 3: mr-publisher Agent

**Purpose**: Post comments to MR
**Input**: formatted_comments.json
**Output**: Comment URLs

## Flow Control

- Steps run sequentially
- If code-reviewer finds 0 issues → skip steps 2-3
- If mr-publisher fails → retry once
```

### Steps to Refactor

1. **Identify work being done**
   - Look for tool usage (Read, Write, Bash, etc.)
   - Look for logic implementation

2. **Extract into agents**
   - Each distinct responsibility → one agent
   - Define agent roles, tools, boundaries

3. **Rewrite command as orchestration**
   - Define agent sequence
   - Specify inputs/outputs between steps
   - Add flow control logic

4. **Remove tool usage from command**
   - Commands should not use tools directly
   - Delegate all work to agents

## 3. Migrating a Skill

### Problem: Skill Duplicates Referentiel Rules

**Before** (anti-pattern):
```markdown
# skills/my-skill/SKILL.md

## DRY Principle

Don't Repeat Yourself means...
[Full explanation]

## SRP Principle

Single Responsibility means...
[Full explanation]
```

**After** (correct pattern):
```markdown
# skills/my-skill/SKILL.md

## Principles Source

**ALWAYS read** `referentiel/principes-architectures.md` before applying this skill.

This skill applies:
- **DRY** - `referentiel/principes-architectures.md#dry`
- **SRP** - `referentiel/principes-architectures.md#srp`

## Skill-Specific Process

[How to apply these principles in this context]
[Examples specific to this skill's domain]
```

### Steps to Refactor

1. **Remove principle definitions**
   - Delete explanations that exist in referentiel
   - Keep only skill-specific application guidance

2. **Add referentiel references**
   - Link to specific sections
   - Instruct to read at runtime

3. **Keep skill value-add**
   - Application process
   - Domain-specific examples
   - Tool scripts if applicable

## 4. Adding Tool Restrictions

### Problem: Agent Has Too Many Tools

**Before** (anti-pattern):
```markdown
tools: [Read, Write, Edit, Bash, Grep, WebFetch]
```

An agent with all tools is probably doing too much!

**After** (correct pattern):
```markdown
---
tools: [Read, Grep, Bash]
boundaries:
  - "ONLY use Bash for git commands (diff, log, show, status)"
  - "NEVER use Write or Edit"
---

## Tools

### Allowed

- **Read**: For reading referentiel and source files
- **Grep**: For searching codebase patterns
- **Bash**: Git commands ONLY (diff, log, show, status)

### Forbidden

- Write, Edit (this agent only reads)
- WebFetch (no external calls)
```

### Steps to Add Restrictions

1. **Audit agent role**
   - What is the single responsibility?
   - What tools are absolutely necessary?

2. **Remove unnecessary tools**
   - Start with zero, add only what's needed
   - If you need all tools, split the agent

3. **Document restrictions**
   - Specific commands allowed (e.g., "git diff only")
   - Explicit forbidden list
   - Rationale for restrictions

4. **Add validation**
   - Hooks can enforce tool boundaries
   - See `hooks/README.md` for examples

## 5. Common Patterns

### Pattern: Extracting Duplicated Rules

```bash
# Find potential duplication
grep -r "Single Responsibility\|Don't Repeat" agents/ skills/

# For each match:
# 1. Is this a detailed explanation? → Remove, reference referentiel
# 2. Is this a passing mention? → Keep, add referentiel reference
# 3. Is this application guidance? → Keep, it's value-add
```

### Pattern: Splitting a Multi-Role Agent

```markdown
# Before: one agent doing everything
agents/mega-agent.md
  - Analyzes code
  - Formats comments
  - Posts to MR

# After: three focused agents
agents/code-analyzer.md (Read, Grep, Bash)
agents/comment-formatter.md (Read)
agents/mr-publisher.md (Bash - gh CLI only)

# Plus: one command orchestrating them
commands/review.md
```

### Pattern: Command to Agent Delegation

```markdown
# Before (command doing work)
1. Use Read tool to get code
2. Apply business logic
3. Use Write tool to output

# After (command orchestrating)
1. Run analyzer-agent (uses Read, outputs analysis)
2. If analysis found issues:
   3. Run formatter-agent (formats output)
   4. Run publisher-agent (uses Write)
```

## Validation After Migration

### 1. Run Validation Script

```bash
bash scripts/validate-architecture.sh
```

Should show:
- 0 errors
- Minimal warnings

### 2. Test Component

**For agents**:
```bash
# Try using the agent
"Use the [agent-name] to [task]"
```

**For commands**:
```bash
/ai-agents:[command-name] [args]
```

**For skills**:
```bash
# Skills are loaded by agents, test indirectly
"Use [agent] with [skill] to [task]"
```

### 3. Check References

Verify referentiel files are actually read:
```bash
# Should see referentiel/ in the agent's execution
# Check that it references current rules, not stale copies
```

## Troubleshooting

### "Agent still has duplicated rules"

- Search for detailed explanations (not just mentions)
- Look for quoted definitions
- Check for copied examples from referentiel

**Fix**: Replace with references, keep only application guidance

### "Command still using tools directly"

- Look for tool call patterns: `Read(`, `Write(`, etc.
- Look for logic implementation in command

**Fix**: Extract to agents, rewrite command as orchestration

### "Agent needs too many tools"

- Review agent's role - is it too broad?
- Check if agent is doing multiple things

**Fix**: Split into multiple focused agents

### "Validation script shows warnings"

- Each warning indicates potential non-compliance
- Read warning message for specific issue
- Apply relevant migration pattern above

**Fix**: Address each warning, re-run validation

## Migration Priority

Recommend this order:

1. **Skills first** - They're referenced by agents
2. **Agents second** - They're orchestrated by commands
3. **Commands last** - They depend on agents

## Examples

See these migrated components for reference:

- ✅ `skills/clean-code-review/` - References referentiel
- ✅ `skills/architecture-implement/` - References referentiel
- ✅ `skills/tdd/` - References referentiel

## Need Help?

1. Check `referentiel/QUICKREF.md` for decision trees
2. Check `referentiel/architecture-systeme.md` for detailed patterns
3. Look at templates in `templates/`
4. Run validation script for specific issues

## Post-Migration

After migrating all components:

- [ ] All validation checks pass
- [ ] All components tested
- [ ] Documentation updated
- [ ] Team trained on new patterns
- [ ] Hooks installed (optional but recommended)
- [ ] CI/CD updated with validation checks
