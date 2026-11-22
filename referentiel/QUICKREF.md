# Quick Reference: Architecture Rules

Condensed version of architecture rules for quick lookup. See full docs in respective files.

## Component Responsibilities

| Component | Does | Doesn't |
|-----------|------|---------|
| **Command** | Orchestrates agents, manages flow | Execute work, use tools directly |
| **Agent** | Executes one specific role | Orchestrate, call other agents, exceed tool boundaries |
| **Skill** | Provides reusable knowledge/scripts | Contain business logic, duplicate referentiel |
| **Referentiel** | Single source of truth for rules | Get copied into agents/skills |
| **Hook** | Mechanically enforce rules | Rely on documentation/trust |

## Decision Trees

### "Should this be a Command, Agent, or Skill?"

```
Is it a user entry point?
├─ Yes → Command
│  └─ Does it orchestrate multiple steps?
│     ├─ Yes → Good command
│     └─ No → Maybe too simple, consider single agent
│
└─ No → Is it reusable knowledge/script?
   ├─ Yes → Skill
   └─ No → Agent (single execution role)
```

### "Where does this rule go?"

```
Is it a rule that agents need to follow?
├─ Yes → referentiel/
│  └─ Agents will Read this file at runtime
│
└─ No → Is it a process/methodology?
   ├─ Yes → skills/
   └─ No → Specific to one agent → agents/AGENT.md
```

### "What tools should this agent have?"

```
Start with zero tools.

For each tool you consider adding:
├─ Is it absolutely necessary for the agent's role?
│  ├─ No → Don't add it
│  └─ Yes → Can it be restricted?
│     ├─ Yes → Document restrictions (e.g., "Bash: git only")
│     └─ No → Reconsider if agent's role is too broad
```

## Common Patterns

### Command Structure

```markdown
1. Load context (what agents need)
2. Run Agent 1 → get output
3. If condition: run Agent 2 with Agent 1's output
4. Run Agent 3 with combined results
5. Return final result to user
```

### Agent Structure

```markdown
1. Read referentiel/[rules].md
2. Execute role-specific work
3. Output structured data
4. NEVER: modify if not role, call other agents, exceed tools
```

### Skill Structure

```markdown
# Knowledge Skill
- Document process/methodology
- Include examples
- Reference referentiel

# Tool Skill
- Provide deterministic script
- Document inputs/outputs
- Include tests
```

## Anti-Patterns to Avoid

| ❌ Anti-Pattern | ✅ Correct Pattern |
|----------------|-------------------|
| Command does the work | Command orchestrates agents |
| Agent with all tools | Agent with minimal tools for role |
| Copy rules into agent | Reference referentiel/ |
| Agent calls other agents | Only commands orchestrate |
| Skill with business logic | Business logic in app code |
| Rules in multiple places | Rules in referentiel/ only |
| Hope hooks are followed | Hooks enforce mechanically |
| Manual testing | Golden tests + CI |

## Checklist: Before Adding Component

### Command
- [ ] Orchestrates, doesn't execute
- [ ] Clear agent sequence defined
- [ ] Error handling specified
- [ ] End-to-end test exists

### Agent
- [ ] Single clear role
- [ ] Minimal tools (only what's needed)
- [ ] Boundaries explicit (NEVER/ALWAYS)
- [ ] References referentiel, doesn't copy
- [ ] Golden tests with reference cases

### Skill
- [ ] Reusable by multiple agents
- [ ] Well documented with examples
- [ ] Deterministic (if script)
- [ ] No duplication of referentiel

### Referentiel Update
- [ ] Rule in one place only
- [ ] Clear, structured markdown
- [ ] Version/date updated
- [ ] Agents tested after change

## Common Questions

**Q: Command or Agent?**
A: User entry point that coordinates = Command. Worker that executes = Agent.

**Q: Agent or Skill?**
A: Specific execution for one task = Agent. Reusable knowledge = Skill.

**Q: Where do architecture rules go?**
A: Always `referentiel/`. Never copied elsewhere.

**Q: Can an agent call another agent?**
A: No. Only commands orchestrate agents.

**Q: Can an agent modify the rules?**
A: No. Referentiel is read-only for agents.

**Q: How do I add a new tool to an agent?**
A: Question if it's really needed. If yes, document restrictions clearly.

**Q: Should I duplicate this small rule?**
A: No. Single source of truth in referentiel, always.

**Q: How do I enforce a new safety rule?**
A: Add a hook that validates mechanically, not documentation.

## File References

- Full architecture: `referentiel/architecture-systeme.md`
- Architecture principles: `referentiel/principes-architectures.md`
- Templates: `templates/{command,agent,skill}/`

## Examples in This Repo

**Command**: `commands/review.md` - Orchestrates code review flow
**Agent**: `agents/code-reviewer.md` - Single role: analyze code
**Skill**: `skills/tdd/` - Reusable TDD methodology
**Referentiel**: `referentiel/principes-architectures.md` - Architecture rules
