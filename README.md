# ai-agents

A Claude Code plugin with TDD coding agents, clean-code reviewer, and architecture-driven development.

## Architecture

Built with clear separation of responsibilities. See `referentiel/architecture-systeme.md` for full details.

```
commands/              Entry points (orchestration only)
  review.md           /ai-agents:review [MR | branch | path]
  implement.md        /ai-agents:implement [--tdd] <task>

agents/                Workers (single role, restricted tools)
  fastapi-engineer.md Python/FastAPI engineer (loads tdd skill)
  nextjs-engineer.md  React/Next.js engineer (loads tdd skill)
  code-reviewer.md    MR reviewer (references referentiel)

skills/                Know-how and scripts (reusable)
  tdd/                Fowler/Beck TDD: test list → red → green → refactor
  clean-code-review/  DRY · SRP · Strategy pattern guidance
  architecture-implement/ Architecture principles application

referentiel/           Single source of truth (rules)
  architecture-systeme.md       System architecture documentation
  principes-architectures.md    SRP, DRY, YAGNI, patterns, no booleans

hooks/                 Safety rules (mechanical enforcement)
  (to be implemented)

templates/             Reusable templates
  command/            Template for new commands
  agent/              Template for new agents
  skill/              Template for new skills
  code-review-comment.md
  implementation-report.md
```

## Install in a project

From inside Claude Code in any repo:

```
/plugin marketplace add ~/Documents/Coding\ Projects/ai-agents
/plugin install ai-agents@ai-agents
```

(Or push this repo and use `/plugin marketplace add <github-user>/ai-agents`.)

To try it without installing: `claude --plugin-dir ~/Documents/Coding\ Projects/ai-agents`.

## Use

- `/ai-agents:implement --tdd add pagination to GET /orders` (drop `--tdd` for a normal pass)
- `/ai-agents:review` (current branch) or `/ai-agents:review 123` (MR/PR)
- Or just ask: "use the fastapi-engineer to … with TDD", "have the code-reviewer look at my diff".

## Architecture Principles

This plugin follows strict architectural principles:

1. **Commands orchestrate, never execute**: Commands decide which agents run and in what order
2. **Agents are single-purpose workers**: Each has one role, restricted tools, clear boundaries
3. **Skills hold reusable know-how**: Processes, scripts, domain knowledge
4. **Referentiel is the single source of truth**: All rules live here, agents reference them
5. **Hooks make safety mechanical**: Validation is automated, not trusted to documentation
6. **Quality control prevents regression**: Golden tests and metrics ensure agent behavior

See `referentiel/architecture-systeme.md` for complete documentation.

## Contributing

### Adding a Command

1. Copy `templates/command/COMMAND.md` to `commands/your-command/`
2. Define orchestration: which agents, in what order
3. Keep it focused on coordination, not execution
4. Test end-to-end flow

### Adding an Agent

1. Copy `templates/agent/AGENT.md` to `agents/your-agent/`
2. Define single clear role
3. Specify allowed tools only
4. Document boundaries (NEVER/ALWAYS)
5. Reference referentiel files, don't copy rules
6. Add tests with golden cases

### Adding a Skill

1. Copy `templates/skill/SKILL.md` to `skills/your-skill/`
2. Document reusable knowledge or provide deterministic script
3. Include examples
4. Reference referentiel when applicable

### Updating Rules

1. Edit files in `referentiel/` only
2. Never duplicate rules in agents/skills
3. Update version/date in affected referentiel files
4. Test that agents still reference correctly

## Development

### Running Tests

```bash
pytest tests/
```

### Quality Checks

```bash
# Check agent tool boundaries
pytest tests/agents/ -k boundaries

# Run golden tests
pytest tests/golden/

# Check referentiel references
pytest tests/integration/ -k referentiel
```
