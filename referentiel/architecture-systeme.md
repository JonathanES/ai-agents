# Architecture du Système AI-Agents

Architecture pour construire des agents IA maintenables, avec séparation claire des responsabilités et source unique de vérité pour les règles.

## Vue d'Ensemble

```
ai-agents/
├── commands/          # Points d'entrée (orchestration)
├── agents/            # Travailleurs (exécution)
├── skills/            # Savoir-faire (connaissances et scripts)
├── referentiel/       # Source unique de vérité (règles)
├── hooks/             # Règles de sécurité mécaniques
└── templates/         # Modèles réutilisables
```

## 1. Commands: Points d'Entrée et Orchestration

### Responsabilité

Les commands sont des **orchestrateurs**. Ils décident quels agents exécuter et dans quel ordre. Ils font peu de travail eux-mêmes.

### Principe

- **Une command = un point d'entrée utilisateur**
- Coordonne les agents mais ne fait pas le travail
- Gère le flux: séquentiel, parallèle, conditionnel
- Passe les données entre agents
- Gère les erreurs au niveau orchestration

### Structure d'une Command

```bash
commands/
└── nom-command/
    ├── COMMAND.md           # Description et usage
    └── orchestration.yml    # (optionnel) déclaration du flux
```

### Exemple: Command de Review

```markdown
# commands/review-mr/COMMAND.md
---
name: review-mr
description: Review a merge request following architecture principles
---

# Review MR Command

## Orchestration

1. **code-reviewer agent**: Analyze changes against principles
   - Input: MR number or branch
   - Tools: Read, Grep, Bash (git)
   - Output: findings list

2. **comment-formatter agent**: Format findings as MR comments
   - Input: findings from step 1
   - Tools: Read referentiel/format-commentaire-mr.md
   - Output: formatted comments

3. **mr-publisher agent**: Post comments to MR
   - Input: formatted comments
   - Tools: Bash (gh CLI)
   - Output: posted comment URLs

## Flow Control

- Steps run sequentially
- If code-reviewer finds 0 issues → skip steps 2-3
- If mr-publisher fails → retry once

## Usage

/review-mr [MR-number]
/review-mr feat/new-feature
```

### Anti-Patterns

```markdown
❌ Command qui fait le travail:
def review_command():
    code = read_files()      # Non! Déléguer à un agent
    issues = analyze(code)   # Non! Déléguer à un agent
    post(issues)             # Non! Déléguer à un agent

✅ Command qui orchestre:
def review_command():
    findings = run_agent("code-reviewer", input=mr_number)
    if findings:
        comments = run_agent("comment-formatter", input=findings)
        run_agent("mr-publisher", input=comments)
```

## 2. Agents: Les Travailleurs

### Responsabilité

Les agents sont des **exécutants spécialisés**. Chacun a un rôle unique, des outils restreints à ce rôle, et des frontières claires.

### Principe

- **Un agent = une responsabilité**
- Outils limités au strict nécessaire pour son rôle
- Frontières explicites dans la description
- Peut appeler des skills mais pas d'autres agents
- Stateless: ne garde pas d'état entre invocations

### Structure d'un Agent

```bash
agents/
└── nom-agent/
    ├── AGENT.md        # Description, rôle, frontières
    └── tools.yml       # (optionnel) Liste des outils autorisés
```

### Exemple: Agent Code Reviewer

```markdown
# agents/code-reviewer/AGENT.md
---
name: code-reviewer
role: Analyze code changes against architecture principles
tools: [Read, Grep, Bash]
boundaries:
  - "ONLY analyze code, never modify it"
  - "ONLY use git commands for inspection (diff, log, show)"
  - "NEVER post comments or interact with external systems"
  - "Output findings as structured data, not formatted comments"
---

# Code Reviewer Agent

## Role

Analyze code changes in a branch or MR against principles defined in `referentiel/principes-architectures.md`.

## Process

1. Read `referentiel/principes-architectures.md` to load review criteria
2. Get code changes (git diff)
3. For each changed file:
   - Check against SRP, DRY, YAGNI
   - Detect code smells (boolean params, feature envy, None-switching)
   - Flag pattern usage without named friction
4. Output findings as JSON

## Tools

- **Read**: For reading referentiel and source files
- **Grep**: For searching codebase context
- **Bash**: Git commands only (diff, log, show, status)

## Boundaries

**NEVER**:
- Modify code
- Format output for external systems
- Post comments directly
- Use network tools
- Execute tests

**ALWAYS**:
- Reference referentiel files, never copy rules
- Output structured findings
- Include file path and line numbers
- Cite which principle was violated

## Output Format

```json
{
  "findings": [
    {
      "file": "src/users/logic.py",
      "line": 42,
      "severity": "major",
      "principle": "SRP",
      "description": "Function mixes HTTP handling and business logic",
      "suggestion": "Extract business logic to separate function",
      "reference": "referentiel/principes-architectures.md#srp"
    }
  ]
}
```
```

### Anti-Patterns

```markdown
❌ Agent avec trop d'outils:
tools: [Read, Write, Edit, Bash, WebFetch, Grep, ...]
→ Si un agent a besoin de tous les outils, il fait trop de choses

❌ Agent qui fait plusieurs rôles:
"Analyze code AND format comments AND post to MR"
→ Diviser en 3 agents

❌ Agent qui appelle d'autres agents:
run_agent("other-agent")
→ Seules les commands orchestrent

✅ Agent focalisé:
role: "Analyze code against principles"
tools: [Read, Grep, Bash]
boundaries: "ONLY analyze, never modify"
```

## 3. Skills: Savoir-Faire et Scripts

### Responsabilité

Les skills contiennent:
- **Connaissances de stack**: Comment faire TDD, clean code review, patterns
- **Scripts déterministes**: Profiler backends (silk.py), outils de domaine (ADR)
- **Procédures**: Étapes à suivre pour accomplir une tâche

### Principe

- **Réutilisables** par plusieurs agents
- **Déterministes** quand c'est un script
- **Documentés** avec exemples
- **Testables** quand applicable

### Structure d'un Skill

```bash
skills/
└── nom-skill/
    ├── SKILL.md              # Description et usage
    ├── references/           # Docs de référence
    │   └── examples.md
    └── scripts/              # (optionnel) Scripts exécutables
        └── profiler.py
```

### Types de Skills

#### Knowledge Skill (Connaissances)

```markdown
# skills/tdd/SKILL.md
---
name: tdd
description: Test-Driven Development following Kent Beck / Martin Fowler
type: knowledge
---

# Test-Driven Development

[Process, examples, checklist...]
```

#### Tool Skill (Script/Outil)

```markdown
# skills/backend-profiler/SKILL.md
---
name: backend-profiler
description: Profile Django/FastAPI endpoints using silk or similar
type: tool
---

# Backend Profiler

## Installation

pip install django-silk

## Usage

```python
# skills/backend-profiler/scripts/setup_silk.py
def setup_silk_profiling(project_path):
    # Deterministic setup script
    ...
```

## Output

Profiling data at /silk/
```

### Anti-Patterns

```markdown
❌ Skill qui contient de la logique métier spécifique:
"Calculate user discount" → Ça va dans le code métier, pas un skill

❌ Skill qui duplique des règles du referentiel:
Copier les principes d'architecture → Référencer referentiel/ au lieu

✅ Skill bien défini:
"How to apply TDD" → Procédure réutilisable
"Backend profiling setup" → Script déterministe
```

## 4. Referentiel: Source Unique de Vérité

### Responsabilité

Le référentiel contient **toutes les règles** du système en markdown. Les agents **lisent** ces fichiers, ils ne copient jamais les règles.

### Principe

- **Une règle, un endroit**
- Format markdown pour lisibilité humaine et agent
- Agents pointent vers ces fichiers, ne dupliquent pas
- Modifier une règle = modifier un seul fichier
- Versionné avec git

### Structure

```bash
referentiel/
├── principes-architectures.md     # Architecture principles
├── format-commentaire-mr.md       # MR comment format
├── architecture-systeme.md        # This file
├── conventions-nommage.md         # Naming conventions
└── process-review.md              # Review process
```

### Exemple: Format de Commentaire MR

```markdown
# referentiel/format-commentaire-mr.md

## Format des Commentaires MR

Chaque commentaire suit ce template:

**[SEVERITY]** [PRINCIPLE] @ `file:line`

**Problème**: Description courte

**Suggestion**: Action concrète

**Référence**: `referentiel/principes-architectures.md#section`

## Exemple

**[Major]** SRP @ `src/users/logic.py:42`

**Problème**: Fonction mélange validation et persistence

**Suggestion**: Extraire la persistence dans une fonction séparée

**Référence**: `referentiel/principes-architectures.md#srp`
```

### Usage par les Agents

```markdown
# Dans AGENT.md

## Process

1. **Read** `referentiel/format-commentaire-mr.md` pour connaître le format
2. Formatter chaque finding selon le template
3. Ne JAMAIS copier le template dans le code de l'agent

## Référence

Toujours lire le fichier au runtime pour avoir la version à jour.
```

### Anti-Patterns

```markdown
❌ Agent qui hardcode les règles:
def check_srp():
    # SRP means...  → Non! Lire referentiel/principes-architectures.md

❌ Dupliquer les règles dans plusieurs endroits:
agent.md: "SRP means..."
skill.md: "SRP means..."
→ Une seule source: referentiel/

✅ Référencer la source unique:
"See referentiel/principes-architectures.md#srp for SRP definition"
```

## 5. Hooks: Règles de Sécurité Mécaniques

### Responsabilité

Les hooks rendent les règles de sécurité **mécaniques**, pas une question de confiance. Ils interceptent et valident les actions.

### Principe

- **Prévention automatique** des erreurs
- **Validations** avant exécution
- **Rejets** explicites avec message clair
- **Pas de bypass** possible

### Types de Hooks

#### Pre-commit Hook

```bash
# hooks/pre-commit.sh
#!/bin/bash
# Vérifie que les règles d'architecture sont respectées

# 1. Pas de logique métier dans les models
if git diff --cached | grep -A 5 "class.*Model" | grep -q "def.*business"; then
    echo "❌ Business logic detected in model"
    echo "→ Move to logic.py (referentiel/principes-architectures.md#placement-logique)"
    exit 1
fi

# 2. Pas de paramètres booléens
if git diff --cached | grep -E "def .+\(.+(: ?bool|=True|=False)" | grep -v "Optional\[bool\]"; then
    echo "❌ Boolean parameter detected"
    echo "→ Use alternatives (referentiel/principes-architectures.md#boolean-parameters)"
    exit 1
fi

exit 0
```

#### Tool Restriction Hook

```yaml
# hooks/agent-tools.yml
# Définit les outils autorisés par agent

agents:
  code-reviewer:
    allowed: [Read, Grep, Bash]
    forbidden: [Write, Edit, WebFetch]
    validation: |
      if tool not in allowed:
        raise ToolNotAllowedError(f"{tool} not allowed for code-reviewer")

  code-modifier:
    allowed: [Read, Write, Edit]
    forbidden: [Bash, WebFetch]
```

#### Command Validation Hook

```python
# hooks/validate_command.py
def validate_command_orchestration(command):
    """Vérifie qu'une command orchestre et ne fait pas le travail"""

    # Command ne doit pas avoir de logique métier
    if has_business_logic(command):
        raise ValidationError(
            "Command should orchestrate agents, not do work itself"
        )

    # Command doit appeler au moins un agent
    if not calls_agents(command):
        raise ValidationError(
            "Command must orchestrate at least one agent"
        )

    return True
```

### Anti-Patterns

```markdown
❌ Hook qui peut être contourné:
# Allow bypass with --no-verify
→ Les règles critiques ne doivent pas être bypassables

❌ Hook qui fait confiance à la documentation:
"Please follow rules in X"
→ Vérifier mécaniquement au lieu de demander

✅ Hook qui impose:
if violation: reject_with_clear_message()
```

## 6. Quality Control: Contrôle des Agents

### Responsabilité

Assurer qu'il n'y a **pas de régression** dans le comportement des agents.

### Principe

- **Tests automatisés** pour chaque agent
- **Cas de référence** (golden tests)
- **Métriques** de qualité
- **CI/CD** qui bloque les régressions

### Structure

```bash
tests/
├── agents/
│   ├── test_code_reviewer.py
│   └── fixtures/
│       ├── input_code_with_srp_violation.py
│       └── expected_findings.json
├── commands/
│   └── test_review_mr.py
└── integration/
    └── test_full_review_flow.py
```

### Exemple: Test d'Agent

```python
# tests/agents/test_code_reviewer.py
import pytest
from agents.code_reviewer import analyze_code

def test_detects_srp_violation():
    """Agent détecte violation SRP"""

    # Arrange: code avec violation SRP connue
    code = read_fixture("input_code_with_srp_violation.py")
    expected = read_fixture("expected_findings.json")

    # Act: analyser
    findings = analyze_code(code)

    # Assert: vérifie détection
    assert len(findings) == 1
    assert findings[0]["principle"] == "SRP"
    assert findings[0]["severity"] == "major"
    assert "mixes HTTP handling and business logic" in findings[0]["description"]

def test_references_referentiel():
    """Agent référence le referentiel, ne copie pas"""

    code = read_fixture("input_code_with_dry_violation.py")
    findings = analyze_code(code)

    # Doit pointer vers referentiel
    assert "referentiel/principes-architectures.md" in findings[0]["reference"]

def test_respects_tool_boundaries():
    """Agent ne peut pas utiliser d'outils interdits"""

    with pytest.raises(ToolNotAllowedError):
        agent.use_tool("Write")  # code-reviewer ne peut pas Write
```

### Golden Tests

```python
# tests/golden/test_review_output.py
def test_review_output_format():
    """La sortie de review suit exactement le format attendu"""

    # Cas de référence: code avec 3 violations connues
    input_code = "tests/fixtures/golden_input.py"
    expected_output = "tests/fixtures/golden_output.json"

    # Exécuter review
    actual = run_review(input_code)

    # Doit matcher exactement
    assert actual == load_json(expected_output)

    # Si ce test échoue, c'est une régression ou le golden doit être mis à jour
```

### Métriques

```yaml
# .github/workflows/quality-metrics.yml
name: Agent Quality Metrics

on: [push, pull_request]

jobs:
  measure:
    steps:
      - name: Run agents on test corpus
        run: pytest tests/agents --metrics

      - name: Check metrics
        run: |
          # Précision: détections correctes / total détections
          assert precision >= 0.90

          # Rappel: violations détectées / violations réelles
          assert recall >= 0.85

          # Pas de régression
          assert current_metrics >= baseline_metrics
```

### Anti-Patterns

```markdown
❌ Tester manuellement:
"J'ai vérifié que l'agent marche"
→ Tests automatisés obligatoires

❌ Pas de cas de référence:
"Ça devrait marcher pour tous les cas"
→ Golden tests avec cas connus

❌ Accepter les régressions:
"C'est juste un petit changement"
→ CI bloque toute régression

✅ Quality control systématique:
- Tests automatisés
- Golden tests
- Métriques suivies
- CI qui bloque
```

## Flux de Travail Complet

### Exemple: Review de MR

```
1. Utilisateur: /review-mr 123

2. Command review-mr:
   ├─ Charge orchestration
   └─ Exécute agents dans l'ordre

3. Agent code-reviewer:
   ├─ Lit referentiel/principes-architectures.md
   ├─ Analyse le code (Read, Grep, Bash)
   └─ Output: findings.json

4. Agent comment-formatter:
   ├─ Lit referentiel/format-commentaire-mr.md
   ├─ Formate findings selon template
   └─ Output: comments.json

5. Agent mr-publisher:
   ├─ Lit comments.json
   ├─ Poste via gh CLI
   └─ Output: URLs des commentaires

6. Hooks:
   ├─ Vérifie que code-reviewer n'a pas modifié le code
   ├─ Vérifie que comment-formatter a respecté le format
   └─ Vérifie que mr-publisher a posté correctement

7. Quality Control:
   ├─ Tests vérifient que les findings sont corrects
   ├─ Golden tests vérifient pas de régression
   └─ Métriques vérifient précision/rappel
```

## Principes de Conception

### Séparation des Responsabilités

```
Commands    → Orchestration uniquement
Agents      → Exécution spécialisée
Skills      → Savoir-faire réutilisable
Referentiel → Règles centralisées
Hooks       → Validation mécanique
Tests       → Prévention régression
```

### Single Source of Truth

```
Règle d'architecture     → referentiel/principes-architectures.md
Format de commentaire    → referentiel/format-commentaire-mr.md
Process de review        → referentiel/process-review.md

Agents lisent ces fichiers au runtime
Jamais de copie, toujours une référence
```

### Fail Fast et Fail Safe

```
Hooks bloquent les violations avant exécution
Tests bloquent les régressions avant merge
Agents ont des frontières strictes
Outils restreints par rôle
```

## Checklist de Conformité

Avant d'ajouter un nouveau composant:

### Pour une Command
- [ ] Orchestre, ne fait pas le travail
- [ ] Délègue aux agents appropriés
- [ ] Gère le flux et les erreurs
- [ ] Documentée avec flux clair
- [ ] Testée end-to-end

### Pour un Agent
- [ ] Un seul rôle clairement défini
- [ ] Outils restreints au nécessaire
- [ ] Frontières explicites dans AGENT.md
- [ ] Référence le referentiel, ne copie pas
- [ ] Tests avec cas de référence
- [ ] Golden tests pour non-régression

### Pour un Skill
- [ ] Réutilisable par plusieurs agents
- [ ] Bien documenté avec exemples
- [ ] Déterministe si c'est un script
- [ ] Testé si exécutable

### Pour le Referentiel
- [ ] Une règle = un seul endroit
- [ ] Markdown clair et structuré
- [ ] Versionné
- [ ] Référencé par les agents

### Pour un Hook
- [ ] Validation mécanique, pas documentation
- [ ] Message d'erreur clair avec référence
- [ ] Pas de bypass possible (sauf justification)
- [ ] Testé

## Résumé

Cette architecture garantit:

✅ **Maintenabilité**: Responsabilités claires, couplage faible
✅ **Traçabilité**: Règles centralisées, références explicites
✅ **Sécurité**: Hooks mécaniques, outils restreints
✅ **Qualité**: Tests automatisés, golden tests, métriques
✅ **Évolutivité**: Composants indépendants, ajout facile

**Règle d'or**: Si un agent ou une command fait trop de choses, diviser. Si une règle est dupliquée, centraliser dans le referentiel.
