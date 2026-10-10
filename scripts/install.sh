#!/usr/bin/env bash
# Instala a parte do workflow que um plugin não consegue instalar:
# o CLAUDE.md global e a distribuição de modelos no settings.json.
# Skills e agentes vêm pelo plugin (/plugin install claude-workflow@claude-workflow).
set -euo pipefail

claude_dir="$HOME/.claude"
repo_config="$(cd "$(dirname "$0")/../config" && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$claude_dir"

# CLAUDE.md: nunca sobrescreve o que a pessoa já escreveu.
if [ ! -s "$claude_dir/CLAUDE.md" ]; then
  cp "$repo_config/CLAUDE.md" "$claude_dir/CLAUDE.md"
  echo "CLAUDE.md global instalado."
else
  cp "$repo_config/CLAUDE.md" "$claude_dir/CLAUDE.workflow.md"
  echo "Você já tem um CLAUDE.md global. O do workflow foi salvo em $claude_dir/CLAUDE.workflow.md - junte os dois à mão."
fi

# settings.json: só as chaves de modelo, com backup; o resto do arquivo fica intacto.
settings="$claude_dir/settings.json"
if ! command -v jq >/dev/null 2>&1; then
  echo "jq não encontrado. Copie as chaves de $repo_config/settings.example.json para $settings à mão."
  exit 0
fi
[ -f "$settings" ] && cp "$settings" "$settings.bak-$stamp" || echo '{}' > "$settings"
jq -s '.[0] * .[1]' "$settings" "$repo_config/settings.example.json" > "$settings.tmp"
mv "$settings.tmp" "$settings"
echo "settings.json atualizado (backup em $settings.bak-$stamp, se existia)."
echo "Abra uma sessão nova do Claude Code e confira com /model, /effort e /agents."
