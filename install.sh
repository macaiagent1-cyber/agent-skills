#!/usr/bin/env bash
# Merlin's agent-skills bootstrap installer
# One command installs the hub + curated community skill packs.
# Usage: curl -fsSL https://raw.githubusercontent.com/macaiagent1-cyber/agent-skills/main/install.sh | bash

set -e

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RESET='\033[0m'

echo -e "${CYAN}=========================================${RESET}"
echo -e "${CYAN}  Merlin's agent-skills universal hub${RESET}"
echo -e "${CYAN}=========================================${RESET}"
echo ""

# Check prereqs
command -v npx >/dev/null 2>&1 || { echo "npx not found. Install Node.js first (https://nodejs.org/)."; exit 1; }

install_pack() {
  local pack="$1"
  local desc="$2"
  echo -e "${YELLOW}>>> Installing: ${pack}${RESET}  (${desc})"
  npx --yes skills@latest add "$pack" --yes 2>&1 | tail -3 || echo "  (skip — already installed or unreachable)"
  echo ""
}

# Core: Merlin's hub (76 skills bundled)
install_pack "macaiagent1-cyber/agent-skills" "Merlin's full personal arsenal"

# Engineering / dev
install_pack "addyosmani/agent-skills"          "Addy Osmani engineering skills"
install_pack "mattpocock/skills"                "Matt Pocock engineering skills"
install_pack "multica-ai/andrej-karpathy-skills" "Karpathy's CLAUDE.md improvements"
install_pack "obra/superpowers"                 "Superpowers agentic framework"

# Domain skill packs
install_pack "K-Dense-AI/scientific-agent-skills" "Scientific skills (biology/chem/medicine)"
install_pack "Imbad0202/academic-research-skills" "Academic research workflow"
install_pack "yetone/native-feel-skill"           "Native-feeling desktop UI"
install_pack "ComposioHQ/awesome-codex-skills"    "Curated Codex skills"

# Official Anthropic
install_pack "anthropics/claude-plugins-official" "Official Claude Code Plugins"

echo ""
echo -e "${GREEN}=========================================${RESET}"
echo -e "${GREEN}  Done. Installed in ./.agents/skills/${RESET}"
echo -e "${GREEN}=========================================${RESET}"
echo ""
echo "Next steps:"
echo "  - Run 'npx skills list' to see everything"
echo "  - Run 'npx skills update' to keep things fresh"
echo "  - Visit https://github.com/macaiagent1-cyber/agent-skills"
