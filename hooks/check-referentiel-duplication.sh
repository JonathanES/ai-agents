#!/bin/bash
# Pre-commit hook: Detect rule duplication from referentiel

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Rules that must only exist in referentiel/
REFERENTIEL_RULES=(
    "Single Responsibility Principle"
    "Don't Repeat Yourself"
    "You Aren't Gonna Need It"
    "Design patterns are a remedy"
    "No boolean parameters"
    "Business logic placement"
    "Feature envy"
    "Code smells"
)

echo "Checking for referentiel rule duplication..."

VIOLATIONS=0

# Check staged files in agents/ and skills/
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E "^(agents|skills)/.*\.md$"); do
    if [ ! -f "$file" ]; then continue; fi

    for rule in "${REFERENTIEL_RULES[@]}"; do
        # Look for detailed explanations of rules (not just mentions)
        if git diff --cached "$file" | grep -E "^\+" | grep -i "$rule" | grep -qE "(means|definition|principle.*:)"; then
            # Make sure it's not just referencing referentiel
            if ! git diff --cached "$file" | grep -E "^\+" | grep -i "$rule" | grep -q "referentiel/"; then
                echo -e "${RED}❌ Error: $file may duplicate rule: '$rule'${NC}"
                echo "   Rules must live in referentiel/ only"
                echo "   Reference instead: 'See referentiel/principes-architectures.md#section'"
                echo ""
                ((VIOLATIONS++))
            fi
        fi
    done
done

# Check that files reference referentiel when mentioning principles
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E "^(agents|skills)/.*\.md$"); do
    if [ ! -f "$file" ]; then continue; fi

    # If file mentions principles but doesn't reference referentiel, warn
    if git diff --cached "$file" | grep -E "^\+" | grep -qiE "(SRP|DRY|YAGNI)"; then
        if ! grep -q "referentiel/" "$file"; then
            echo -e "${YELLOW}⚠️  Warning: $file mentions principles but doesn't reference referentiel/${NC}"
            echo "   Consider adding: 'See referentiel/principes-architectures.md'"
            echo ""
        fi
    fi
done

if [ $VIOLATIONS -gt 0 ]; then
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Commit blocked: Rule duplication detected                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Rules must exist in referentiel/ only."
    echo "Components should reference them, not copy them."
    echo ""
    echo "To fix:"
    echo "  1. Remove duplicated rule definitions"
    echo "  2. Add reference: 'See referentiel/principes-architectures.md#section'"
    echo "  3. See referentiel/MIGRATION.md for guidance"
    echo ""
    exit 1
fi

echo "✅ No rule duplication detected"
exit 0
