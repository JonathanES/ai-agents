# Component Index

Automatically generated index of all available components in this ai-agents library.

**Last updated**: Run `scripts/generate-index.sh` to update

## Commands

Entry points that orchestrate agents to accomplish user-facing tasks.

| Command | Description | Parallel | Location |
|---------|-------------|----------|----------|
| **implement** | Routes to appropriate engineer (FastAPI or Next.js), optionally with TDD, then reviews code | No | `commands/implement.md` |
| **implement-fullstack** | ⚡ **NEW** - Runs FastAPI and Next.js engineers in parallel, then integrates and reviews | Yes | `commands/implement-fullstack.md` |
| **review** | Reviews code changes (branch, MR/PR, or path) against architecture principles | No | `commands/review.md` |

## Agents

Specialized workers with single roles and restricted tools.

| Agent | Role | Tools | Location |
|-------|------|-------|----------|
| **code-reviewer** | Analyze code changes against architecture principles | Read, Grep, Bash (git only) | `agents/code-reviewer.md` |
| **fastapi-engineer** | Python/FastAPI backend development with optional TDD | Read, Write, Edit, Bash, Grep | `agents/fastapi-engineer.md` |
| **nextjs-engineer** | React/Next.js/TypeScript frontend development with optional TDD | Read, Write, Edit, Bash, Grep | `agents/nextjs-engineer.md` |

## Skills

Reusable knowledge and deterministic scripts.

| Skill | Type | Description | Location |
|-------|------|-------------|----------|
| **architecture-implement** | Knowledge | Implement features following architecture principles (SRP, DRY, YAGNI, business logic placement, no boolean parameters, design patterns as remedy) | `skills/architecture-implement/` |
| **clean-code-review** | Knowledge | Review checklist for DRY, SRP, and Strategy pattern. Detect code smells and boolean parameters | `skills/clean-code-review/` |
| **tdd** | Knowledge | Test-Driven Development following Kent Beck / Martin Fowler (test list → red → green → refactor) | `skills/tdd/` |
| **sql-profiler** | Tool + Knowledge | Profile SQL queries to detect and fix N+1 issues in Python (Django, SQLAlchemy, FastAPI) and TypeScript (Prisma, TypeORM, Sequelize) | `skills/sql-profiler/` |

## Referentiel Files

Single source of truth for all rules and architecture documentation.

### Core Architecture

| File | Purpose |
|------|---------|
| `architecture-systeme.md` | Complete system architecture: commands, agents, skills, referentiel, hooks, quality control |
| `principes-architectures.md` | Architecture principles: SRP, DRY, YAGNI, business logic placement, code smells, boolean parameters, design patterns |
| `tensions-architecturales.md` | ⚡ **NEW** - Conflicts between principles and how to resolve them (DRY vs YAGNI, SRP vs Performance, etc.) |
| `QUICKREF.md` | Quick reference guide with decision trees and common patterns |
| `MIGRATION.md` | Guide for refactoring existing components to follow architecture |

### Frontend Development

| File | Purpose |
|------|---------|
| `atomic-design-frontend.md` | Atomic Design methodology: Atoms → Molecules → Organisms → Templates → Pages |
| `nextjs-project-structure.md` | Scalable React/Next.js project structure with feature-based architecture |
| `nextjs-14-patterns.md` | Next.js 14+ patterns: App Router, Server Components, Server Actions, ISR |
| `react-design-patterns.md` | React design patterns: Custom Hooks, Compound Components, Context, HOC, Render Props |

### Performance & Optimization

**Decision order**: Choose pattern first, then eviction algorithm, then tool.

| Order | File | Purpose |
|-------|------|---------|
| **1st** | `caching-patterns.md` | Caching patterns (Cache-Aside, Write-Through, Write-Behind, Read-Through, Write-Around, Refresh-Ahead) - **HOW** to use cache |
| **2nd** | `caching-strategies.md` | Eviction algorithms (FIFO, LRU, LFU, MRU, ARC, CLOCK, 2Q, SLRU, TTL, LRFU) - **WHAT** to evict when full |
| **3rd** | `caching-tools.md` | Caching tools (Redis, TanStack Query, TanStack DB, IndexedDB, localStorage) - **WHERE** to cache |

### System Design Trade-offs

| File | Purpose |
|------|---------|
| `system-design-tradeoffs.md` | Fundamental trade-offs in distributed systems: Sync vs Async, Latency vs Throughput, SQL vs NoSQL, Strong vs Eventual Consistency, and more |

### Other

| File | Purpose |
|------|---------|
| `INDEX.md` | This file - component index |

## Templates

Boilerplates for creating new components.

| Template | Purpose | Location |
|----------|---------|----------|
| **Command Template** | Create a new command with proper orchestration structure | `templates/command/COMMAND.md` |
| **Agent Template** | Create a new agent with boundaries and tool restrictions | `templates/agent/AGENT.md` |
| **Skill Template** | Create a new skill (knowledge or tool) | `templates/skill/SKILL.md` |
| **Code Review Comment** | Format for MR/PR review comments | `templates/code-review-comment.md` |
| **Implementation Report** | Final report from coding agents | `templates/implementation-report.md` |

## Usage Examples

### Running a Command

```bash
# Implement a feature with TDD
/ai-agents:implement --tdd add pagination to GET /orders

# Review current branch
/ai-agents:review

# Review specific MR/PR
/ai-agents:review 123
```

### Using an Agent Directly

```bash
# Ask to use an agent
"Use the fastapi-engineer to add error handling with TDD"
"Have the code-reviewer look at my diff"
```

### Referencing a Skill

Skills are loaded by agents automatically, or you can reference them:
```bash
# Apply TDD methodology
"Follow the tdd skill to implement this feature"

# Use architecture principles
"Apply the architecture-implement skill when writing this"
```

## Component Relationships

```
User Request
    ↓
Command (orchestrates)
    ↓
Agent(s) (execute with restricted tools)
    ↓
Skill(s) (provide knowledge/process)
    ↓
Referentiel (single source of truth for rules)
```

## Adding New Components

1. **Command**: Copy `templates/command/COMMAND.md` → Define orchestration
2. **Agent**: Copy `templates/agent/AGENT.md` → Define role, tools, boundaries
3. **Skill**: Copy `templates/skill/SKILL.md` → Document knowledge or script
4. **Rule**: Edit `referentiel/*.md` → Never duplicate in components

See `referentiel/architecture-systeme.md` for detailed guidance.

## Validation

Run architecture validation:
```bash
bash scripts/validate-architecture.sh
```

This checks:
- Agents/skills reference referentiel (no duplication)
- Commands orchestrate (don't execute)
- Components have proper structure
- Required files exist

## See Also

- **Architecture documentation**: `referentiel/architecture-systeme.md`
- **Quick reference**: `referentiel/QUICKREF.md`
- **Contributing guide**: `README.md#contributing`
