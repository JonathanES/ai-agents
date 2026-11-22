---
name: clean-code-review
description: Review checklist for DRY, the Single Responsibility Principle, and replacing if/else / switch chains with the Strategy pattern. Use when reviewing a diff or MR, or when refactoring during the TDD refactor step.
---

# Clean-code review: DRY · SRP · Strategy

Check each changed hunk against architecture principles. Only report a finding when you
can point to concrete lines **and** describe a better shape for them. Taste alone is not a
finding.

## Principles Source

**ALWAYS read** `referentiel/principes-architectures.md` before reviewing to load the current rules.

This skill applies:
- **DRY** (Don't Repeat Yourself) - `referentiel/principes-architectures.md#dry`
- **SRP** (Single Responsibility Principle) - `referentiel/principes-architectures.md#srp`
- **Strategy Pattern** - `referentiel/principes-architectures.md#design-patterns`
- **Code Smells** - `referentiel/principes-architectures.md#code-smells`
- **Boolean Parameters** - `referentiel/principes-architectures.md#no-boolean-parameters`
- **Business Logic Placement** - `referentiel/principes-architectures.md#business-logic-placement`

Code examples for Python/FastAPI and TypeScript/React: [references/examples.md](references/examples.md).

## Review Process

### 1. Load Principles

```
Read referentiel/principes-architectures.md
```

This ensures you're using the current, authoritative definitions.

### 2. Check Each Changed Hunk

For each code change, ask:

#### DRY Check
- Same logic/validation/query in 2+ places?
- **Search the codebase** first - may duplicate existing helper
- Magic values repeated instead of constant/enum?
- Schemas redefined when they could be derived?
- Test setup copy-pasted where fixture belongs?

**Don't flag**: Code that looks alike but represents different knowledge (wait for rule of three)

#### SRP Check
- Function mixes layers (HTTP + business + DB)?
- Needs "and" to describe what it does?
- Takes boolean/flag that changes behavior?
- Too long to read on one screen?
- Changes for unrelated reasons?

**Framework-specific splits**:
- **FastAPI**: router (HTTP) → service (logic) → repository (DB)
- **React/Next.js**: server components (data) → presentational (props) → plain TS (logic)

#### Strategy Pattern Check
- Branches on type/kind/status/provider (3+ branches)?
- Same discriminator branched in multiple places?
- Nesting more than 2 levels deep?

**Suggested fix**: Interface + implementations + registry (dict/Record)

**Don't flag**: 2 trivial branches, guard clauses, early returns

#### Code Smells Check
- **Duplicated knowledge**: Same rule in multiple places?
- **Mystery boolean**: `func(data, True)` - what does True mean?
- **None for behavior**: `func(filter=None)` changes what function does?
- **Feature envy**: Accessing another app's data to apply logic?
- **Business logic in model**: Logic that belongs in logic.py?

#### Boolean Parameters Check
- Any boolean parameters that could be:
  - Two separate functions?
  - An enum?
  - Original value (archived=True vs include_archived=True)?
  - Options dataclass?

### 3. Report Findings

For each issue found, cite the specific referentiel section violated.

## Severity

- 🔴 **Blocker**: duplication or mixed responsibilities that will cause bugs (e.g. two
  divergent copies of a validation rule).
- 🟠 **Major**: clear SRP violation or a type-switch spread across several places.
- 🟡 **Minor**: local duplication or a small branch chain that is worth cleaning up now.
