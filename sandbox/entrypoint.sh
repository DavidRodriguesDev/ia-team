#!/usr/bin/env bash
# Prepara o HOME (tmpfs, descartável) e abre o comando pedido.
set -euo pipefail

TEAM="${TEAM:-ollama}"
H="$HOME"

mkdir -p "$H/.openclaude/agents" "$H/.openclaude/commands"
cp "/ia-team/teams/$TEAM/settings.json" "$H/.openclaude/settings.json"
cp /ia-team/agents/*.md "$H/.openclaude/agents/"
cp /ia-team/commands/*.md "$H/.openclaude/commands/"

# Pula o onboarding e confia na pasta de trabalho (o container é o isolamento)
cat > "$H/.openclaude.json" <<JSON
{"hasCompletedOnboarding": true, "theme": "dark", "projects": {"/work": {"hasTrustDialogAccepted": true}}}
JSON

git config --global user.name "ia-team"
git config --global user.email "ia-team@localhost"
git config --global --add safe.directory /work
echo ".auto/" > "$H/.gitignore_global"
git config --global core.excludesFile "$H/.gitignore_global"

exec "$@"
