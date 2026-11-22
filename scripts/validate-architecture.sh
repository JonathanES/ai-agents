#!/bin/bash
# Architecture Validation Script
# Verifies that components follow architecture rules from referentiel/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "🔍 Validating ai-agents architecture..."
echo ""

# =============================================================================
# 1. CHECK: Agents reference referentiel, don't duplicate rules
# =============================================================================
echo "📋 Checking agents reference referentiel (no rule duplication)..."

RULE_KEYWORDS=(
    "Single Responsibility Principle"
    "Don't Repeat Yourself"
    "You Aren't Gonna Need It"
    "Design patterns are a remedy"
    "No boolean parameters"
)

for agent in agents/*.md; do
    if [ ! -f "$agent" ]; then continue; fi

    agent_name=$(basename "$agent")

    # Check if agent references referentiel
    if ! grep -q "referentiel/" "$agent"; then
        echo -e "${YELLOW}⚠️  Warning: $agent_name doesn't reference referentiel/${NC}"
        ((WARNINGS++))
    fi

    # Check for duplicated rules (definitions, not just mentions)
    for rule in "${RULE_KEYWORDS[@]}"; do
        # Look for rule definitions (with explanation/detail), not just passing mentions
        if grep -A 3 "$rule" "$agent" | grep -qE "(means|principle|when|definition)" | grep -v "referentiel/"; then
            echo -e "${RED}❌ Error: $agent_name appears to duplicate rule: '$rule'${NC}"
            echo "   Rules must live in referentiel/ only"
            ((ERRORS++))
        fi
    done
done

# =============================================================================
# 2. CHECK: Skills reference referentiel, don't duplicate rules
# =============================================================================
echo ""
echo "📚 Checking skills reference referentiel (no rule duplication)..."

for skill_dir in skills/*/; do
    if [ ! -d "$skill_dir" ]; then continue; fi

    skill_file="${skill_dir}SKILL.md"
    if [ ! -f "$skill_file" ]; then continue; fi

    skill_name=$(basename "$skill_dir")

    # Check if skill references referentiel
    if ! grep -q "referentiel/" "$skill_file"; then
        echo -e "${YELLOW}⚠️  Warning: skills/$skill_name doesn't reference referentiel/${NC}"
        ((WARNINGS++))
    fi

    # Check for duplicated rules
    for rule in "${RULE_KEYWORDS[@]}"; do
        # Look for detailed explanations, not just passing mentions
        if grep -A 5 "$rule" "$skill_file" | grep -qE "(\*\"|definition|means|principle)" | grep -v "referentiel/"; then
            echo -e "${RED}❌ Error: skills/$skill_name may duplicate rule: '$rule'${NC}"
            echo "   Rules must live in referentiel/ only"
            ((ERRORS++))
        fi
    done
done

# =============================================================================
# 3. CHECK: Commands orchestrate, don't execute
# =============================================================================
echo ""
echo "🎯 Checking commands orchestrate (don't execute work)..."

for command in commands/*.md commands/*/*.md; do
    if [ ! -f "$command" ]; then continue; fi

    command_name=$(basename "$command")

    # Check if command appears to call agents (orchestration)
    if ! grep -qE "(agent|Task|subagent|orchestrat)" "$command"; then
        echo -e "${YELLOW}⚠️  Warning: $command_name may not orchestrate agents${NC}"
        ((WARNINGS++))
    fi

    # Check if command appears to do work directly (anti-pattern)
    # Looking for tool usage patterns
    if grep -qE "(Read\(|Write\(|Edit\(|Bash\(|Grep\()" "$command"; then
        echo -e "${RED}❌ Error: $command_name appears to use tools directly${NC}"
        echo "   Commands should orchestrate agents, not use tools"
        ((ERRORS++))
    fi
done

# =============================================================================
# 4. CHECK: Agents have clear boundaries and tool restrictions
# =============================================================================
echo ""
echo "🛡️  Checking agents have boundaries and tool restrictions..."

for agent in agents/*.md; do
    if [ ! -f "$agent" ]; then continue; fi

    agent_name=$(basename "$agent")

    # Check for boundaries section
    if ! grep -qiE "(boundaries|NEVER|ALWAYS)" "$agent"; then
        echo -e "${YELLOW}⚠️  Warning: $agent_name missing boundaries section${NC}"
        ((WARNINGS++))
    fi

    # Check for tools section
    if ! grep -qiE "(tools|Tools)" "$agent"; then
        echo -e "${YELLOW}⚠️  Warning: $agent_name missing tools section${NC}"
        ((WARNINGS++))
    fi

    # Check for single responsibility in role/description
    if ! grep -qE "(role|Role|description)" "$agent"; then
        echo -e "${YELLOW}⚠️  Warning: $agent_name missing clear role definition${NC}"
        ((WARNINGS++))
    fi
done

# =============================================================================
# 5. CHECK: Referentiel files exist and are properly structured
# =============================================================================
echo ""
echo "📖 Checking referentiel structure..."

REQUIRED_REFERENTIEL=(
    "referentiel/principes-architectures.md"
    "referentiel/architecture-systeme.md"
    "referentiel/QUICKREF.md"
)

for ref_file in "${REQUIRED_REFERENTIEL[@]}"; do
    if [ ! -f "$ref_file" ]; then
        echo -e "${RED}❌ Error: Required file missing: $ref_file${NC}"
        ((ERRORS++))
    fi
done

# =============================================================================
# 6. CHECK: Templates exist and are properly structured
# =============================================================================
echo ""
echo "📄 Checking templates..."

REQUIRED_TEMPLATES=(
    "templates/command/COMMAND.md"
    "templates/agent/AGENT.md"
    "templates/skill/SKILL.md"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
    if [ ! -f "$template" ]; then
        echo -e "${RED}❌ Error: Required template missing: $template${NC}"
        ((ERRORS++))
    fi
done

# =============================================================================
# 7. CHECK: Component frontmatter/metadata
# =============================================================================
echo ""
echo "🏷️  Checking component metadata..."

# Check agents have proper frontmatter
for agent in agents/*.md; do
    if [ ! -f "$agent" ]; then continue; fi

    agent_name=$(basename "$agent")

    if ! grep -q "^---" "$agent"; then
        echo -e "${YELLOW}⚠️  Warning: $agent_name missing frontmatter${NC}"
        ((WARNINGS++))
    fi
done

# Check skills have proper frontmatter
for skill_dir in skills/*/; do
    if [ ! -d "$skill_dir" ]; then continue; fi

    skill_file="${skill_dir}SKILL.md"
    if [ ! -f "$skill_file" ]; then continue; fi

    skill_name=$(basename "$skill_dir")

    if ! grep -q "^---" "$skill_file"; then
        echo -e "${YELLOW}⚠️  Warning: skills/$skill_name/SKILL.md missing frontmatter${NC}"
        ((WARNINGS++))
    fi
done

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All architecture validations passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Validations passed with warnings${NC}"
    echo "Consider addressing warnings to improve architecture compliance"
    exit 0
else
    echo -e "${RED}❌ Validation failed with $ERRORS error(s)${NC}"
    echo "Fix errors before proceeding"
    exit 1
fi
