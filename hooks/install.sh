#!/bin/bash
# Install pre-commit hooks for ai-agents

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "Installing ai-agents pre-commit hooks..."
echo ""

# Check if .git directory exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Error: Not a git repository"
    echo "   Run this from the ai-agents project root"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$GIT_HOOKS_DIR"

# Backup existing pre-commit hook if it exists
if [ -f "$GIT_HOOKS_DIR/pre-commit" ]; then
    echo "⚠️  Existing pre-commit hook found"
    echo "   Backing up to pre-commit.backup"
    mv "$GIT_HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit.backup"
fi

# Copy our pre-commit hook
cp "$SCRIPT_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
chmod +x "$GIT_HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "The hook will now run on every commit to validate:"
echo "  - No rule duplication from referentiel/"
echo "  - Architecture principles (no boolean params, etc.)"
echo ""
echo "To bypass (not recommended): git commit --no-verify"
echo ""
echo "To uninstall: rm .git/hooks/pre-commit"
