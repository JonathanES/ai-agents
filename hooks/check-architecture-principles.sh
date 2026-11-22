#!/bin/bash
# Pre-commit hook: Check code against architecture principles

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Checking architecture principles in staged code..."

VIOLATIONS=0
WARNINGS=0

# Get staged Python and TypeScript files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|ts|tsx|js|jsx)$' || true)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No code files to check"
    exit 0
fi

# Check 1: No boolean parameters (except Optional[bool])
echo "→ Checking for boolean parameters..."
for file in $STAGED_FILES; do
    # Python: def func(..., param: bool)
    if echo "$file" | grep -q "\.py$"; then
        if git diff --cached "$file" | grep -E "^\+.*def " | grep -E ": ?bool[ ),]" | grep -v "Optional\[bool\]"; then
            echo -e "${YELLOW}⚠️  Warning: Boolean parameter in $file${NC}"
            echo "   Consider: two functions, enum, original value, or options dataclass"
            echo "   See: referentiel/principes-architectures.md#no-boolean-parameters"
            echo ""
            ((WARNINGS++))
        fi
    fi

    # TypeScript/JavaScript: function func(..., param: boolean)
    if echo "$file" | grep -qE '\.(ts|tsx|js|jsx)$'; then
        if git diff --cached "$file" | grep -E "^\+.*function " | grep -E ": ?boolean[ ),]"; then
            echo -e "${YELLOW}⚠️  Warning: Boolean parameter in $file${NC}"
            echo "   Consider: two functions, enum, original value, or options interface"
            echo "   See: referentiel/principes-architectures.md#no-boolean-parameters"
            echo ""
            ((WARNINGS++))
        fi
    fi
done

# Check 2: No business logic in models (Python-specific)
echo "→ Checking business logic placement..."
for file in $STAGED_FILES; do
    if echo "$file" | grep -q "models\.py$"; then
        # Look for business logic methods in Model classes
        if git diff --cached "$file" | grep -A 20 "class.*Model" | grep -E "^\+.*def (calculate|process|apply|validate|handle)"; then
            echo -e "${RED}❌ Error: Business logic detected in model: $file${NC}"
            echo "   Business logic belongs in logic.py/service.ts"
            echo "   See: referentiel/principes-architectures.md#business-logic-placement"
            echo ""
            ((VIOLATIONS++))
        fi
    fi
done

# Check 3: Mystery booleans in function calls
echo "→ Checking for mystery booleans..."
for file in $STAGED_FILES; do
    # Python: func(arg, True) or func(arg, False)
    if echo "$file" | grep -q "\.py$"; then
        if git diff --cached "$file" | grep -E "^\+" | grep -E "\(.*,\s*(True|False)\s*\)" | grep -v "="; then
            echo -e "${YELLOW}⚠️  Warning: Mystery boolean in function call: $file${NC}"
            echo "   Use named parameter: func(arg, param_name=True)"
            echo "   See: referentiel/principes-architectures.md#code-smells"
            echo ""
            ((WARNINGS++))
        fi
    fi

    # TypeScript/JavaScript: func(arg, true) or func(arg, false)
    if echo "$file" | grep -qE '\.(ts|tsx|js|jsx)$'; then
        if git diff --cached "$file" | grep -E "^\+" | grep -E "\(.*,\s*(true|false)\s*\)"; then
            echo -e "${YELLOW}⚠️  Warning: Mystery boolean in function call: $file${NC}"
            echo "   Use object parameter: func(arg, { paramName: true })"
            echo "   See: referentiel/principes-architectures.md#code-smells"
            echo ""
            ((WARNINGS++))
        fi
    fi
done

# Check 4: None/null used to change behavior
echo "→ Checking for None/null behavior switching..."
for file in $STAGED_FILES; do
    # Python: if param is None:
    if echo "$file" | grep -q "\.py$"; then
        if git diff --cached "$file" | grep -A 3 -E "^\+.*if .* is None:" | grep -qE "return|else"; then
            echo -e "${YELLOW}⚠️  Warning: None used to change behavior: $file${NC}"
            echo "   Consider: separate functions for different behaviors"
            echo "   See: referentiel/principes-architectures.md#code-smells"
            echo ""
            ((WARNINGS++))
        fi
    fi

    # TypeScript/JavaScript: if (param === null)
    if echo "$file" | grep -qE '\.(ts|tsx|js|jsx)$'; then
        if git diff --cached "$file" | grep -A 3 -E "^\+.*if.*===\s*(null|undefined)" | grep -qE "return|else"; then
            echo -e "${YELLOW}⚠️  Warning: null/undefined used to change behavior: $file${NC}"
            echo "   Consider: separate functions for different behaviors"
            echo "   See: referentiel/principes-architectures.md#code-smells"
            echo ""
            ((WARNINGS++))
        fi
    fi
done

echo ""
echo "Architecture principles check complete:"
echo -e "  Errors:   ${RED}$VIOLATIONS${NC}"
echo -e "  Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $VIOLATIONS -gt 0 ]; then
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Commit blocked: Architecture violations detected         ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Fix the errors above before committing."
    echo "See referentiel/principes-architectures.md for guidance."
    echo ""
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $WARNINGS warning(s)${NC}"
    echo "Consider addressing these to improve code quality"
    echo ""
fi

echo "✅ Architecture principles check passed"
exit 0
