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

NAPKIN_DIR="$HOME/.claude/skills/napkin"
NAPKIN_REPO="https://github.com/blader/napkin.git"

if [ -d "$NAPKIN_DIR/.git" ]; then
  git -C "$NAPKIN_DIR" fetch --depth 1 origin main
  git -C "$NAPKIN_DIR" reset --hard origin/main
else
  mkdir -p "$HOME/.claude/skills"
  rm -rf "$NAPKIN_DIR"
  git clone --depth 1 "$NAPKIN_REPO" "$NAPKIN_DIR"
fi

# markitdown: convert documents/audio/video to markdown.
if command -v ffmpeg >/dev/null 2>&1; then
  : # already installed
elif command -v apt-get >/dev/null 2>&1 && [ "$(id -u)" = "0" ]; then
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends ffmpeg
fi

MARKITDOWN_DIR="$HOME/markitdown"
MARKITDOWN_REPO="https://github.com/microsoft/markitdown.git"

if [ -d "$MARKITDOWN_DIR/.git" ]; then
  git -C "$MARKITDOWN_DIR" fetch --depth 1 origin main
  git -C "$MARKITDOWN_DIR" reset --hard origin/main
else
  rm -rf "$MARKITDOWN_DIR"
  git clone --depth 1 "$MARKITDOWN_REPO" "$MARKITDOWN_DIR"
fi

if command -v uv >/dev/null 2>&1; then
  uv pip install --system -q -e "$MARKITDOWN_DIR/packages/markitdown[all]"
fi
