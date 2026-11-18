#!/usr/bin/env bash
# Uso: bash install.sh [time]   (padrão: ollama)
set -euo pipefail
shopt -s nullglob

TEAM="${1:-ollama}"
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.openclaude"
TS="$(date +%s)"

# settings.local.json (ignorado pelo git, pode ter chaves) tem prioridade
CFG="$SRC/teams/$TEAM/settings.local.json"
[ -f "$CFG" ] || CFG="$SRC/teams/$TEAM/settings.json"
[ -f "$CFG" ] || { echo "Time '$TEAM' não encontrado em $SRC/teams"; exit 1; }

# Nome de modelo com espaço (ex.: "ollama run x") é erro de digitação
if grep -Eq '"model"[[:space:]]*:[[:space:]]*"[^"]* [^"]*"' "$CFG"; then
  echo "ERRO: há um modelo com espaço em $CFG. Use só o nome (ex.: deepseek-v4.1-flash:cloud)."
  exit 1
fi

mkdir -p "$DEST/agents"

if [ -f "$DEST/settings.json" ]; then
  cp "$DEST/settings.json" "$DEST/settings.json.bak.$TS"
fi
cp "$CFG" "$DEST/settings.json"
chmod 600 "$DEST/settings.json"

# Agentes: symlink. Se já existir um arquivo comum com o mesmo nome, guarda backup.
AGENTS=("$SRC"/agents/*.md)
[ ${#AGENTS[@]} -gt 0 ] || echo "AVISO: nenhum agente em $SRC/agents"
for f in "${AGENTS[@]}"; do
  target="$DEST/agents/$(basename "$f")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak.$TS"
  fi
  ln -sf "$f" "$target"
done

for f in "$SRC"/commands/*.md; do mkdir -p "$DEST/commands"; ln -sf "$f" "$DEST/commands/$(basename "$f")"; done
echo "Time '$TEAM' instalado em $DEST (backup do settings anterior salvo)."

# Verificações que já causaram problema
command -v ollama >/dev/null 2>&1 || echo "AVISO: 'ollama' não encontrado no PATH."

for P in "$HOME/.openclaude.json" "$DEST/.openclaude-profile.json"; do
  if [ -f "$P" ] && grep -q 'ollama run' "$P"; then
    echo "AVISO: $P tem 'ollama run' no nome do modelo."
    echo "       Deixe só o nome (ex.: deepseek-v4.1-flash:cloud), com o OpenClaude fechado."
  fi
done