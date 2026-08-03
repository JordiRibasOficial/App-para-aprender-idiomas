#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web (remote) environments.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

SKILLS_DIR="$HOME/.claude/skills/superpowers"
REPO_URL="https://github.com/obra/superpowers.git"

if [ -d "$SKILLS_DIR/.git" ]; then
  git -C "$SKILLS_DIR" fetch --depth 1 origin main
  git -C "$SKILLS_DIR" reset --hard origin/main
else
  mkdir -p "$HOME/.claude/skills"
  rm -rf "$SKILLS_DIR"
  git clone --depth 1 "$REPO_URL" "$SKILLS_DIR"
fi
