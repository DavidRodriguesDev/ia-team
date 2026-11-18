#!/usr/bin/env bash
# Uso: bash install.sh [time]   (padrão: ollama)
# Feche o OpenClaude antes de rodar: ele regrava ~/.openclaude.json ao sair.
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

mkdir -p "$DEST/agents" "$DEST/commands"

if [ -f "$DEST/settings.json" ]; then
  cp "$DEST/settings.json" "$DEST/settings.json.bak.$TS"
fi
cp "$CFG" "$DEST/settings.json"
chmod 600 "$DEST/settings.json"

# Agentes e comandos: symlink. Se já existir um arquivo comum com o mesmo nome, guarda backup.
link_folder() {
  local from="$1" to="$2" f target
  local files=("$from"/*.md)
  [ ${#files[@]} -gt 0 ] || { echo "AVISO: nenhum arquivo em $from"; return 0; }
  for f in "${files[@]}"; do
    target="$to/$(basename "$f")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mv "$target" "$target.bak.$TS"
    fi
    ln -sf "$f" "$target"
  done
}
link_folder "$SRC/agents"   "$DEST/agents"
link_folder "$SRC/commands" "$DEST/commands"

# O modelo mostrado ao abrir o OpenClaude vem do PERFIL de provedor de cada PC,
# não do settings.json. Aqui o perfil ativo é alinhado ao "model" do time.
sync_profile_model() {
  command -v jq >/dev/null 2>&1 || {
    echo "AVISO: 'jq' não encontrado; o modelo padrão do perfil não foi sincronizado."
    return 0
  }
  local model main prof tmp cur
  model="$(jq -r '.model // empty' "$CFG")"
  [ -n "$model" ] || return 0
  main="$HOME/.openclaude.json"
  prof="$DEST/.openclaude-profile.json"

  # Perfil ativo existe e tem outro modelo? Só então altera (e guarda backup).
  if [ -f "$main" ]; then
    cur="$(jq -r '(.activeProviderProfileId // "") as $id
                  | [.providerProfiles[]? | select(.id == $id)] | if length == 0 then "NONE" else (.[0].model // "") end' "$main" 2>/dev/null || echo NONE)"
    if [ "$cur" != "NONE" ] && [ "$cur" != "$model" ]; then
      tmp="$(mktemp)"
      jq --arg m "$model" '(.activeProviderProfileId // "") as $id
          | .providerProfiles |= map(if .id == $id then .model = $m else . end)' "$main" > "$tmp"
      cp "$main" "$main.bak.$TS"
      mv "$tmp" "$main"
      echo "Modelo padrão do perfil ativo em ~/.openclaude.json: ${cur:-vazio} -> $model"
    fi
  fi

  if [ -f "$prof" ]; then
    cur="$(jq -r '.env.OPENAI_MODEL // "NONE"' "$prof" 2>/dev/null || echo NONE)"
    if [ "$cur" != "NONE" ] && [ "$cur" != "$model" ]; then
      tmp="$(mktemp)"
      jq --arg m "$model" '.env.OPENAI_MODEL = $m' "$prof" > "$tmp"
      cp "$prof" "$prof.bak.$TS"
      mv "$tmp" "$prof"
      echo "OPENAI_MODEL em .openclaude-profile.json: $cur -> $model"
    fi
  fi
}
sync_profile_model

echo "Time '$TEAM' instalado em $DEST (backup do settings anterior salvo)."

# Verificações que já causaram problema
command -v ollama >/dev/null 2>&1 || echo "AVISO: 'ollama' não encontrado no PATH."

for P in "$HOME/.openclaude.json" "$DEST/.openclaude-profile.json"; do
  if [ -f "$P" ] && grep -q 'ollama run' "$P"; then
    echo "AVISO: $P tem 'ollama run' no nome do modelo."
    echo "       Deixe só o nome (ex.: deepseek-v4.1-flash:cloud), com o OpenClaude fechado."
  fi
done
