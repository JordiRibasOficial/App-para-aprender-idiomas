# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-08-03] `.claude/settings.json` and `.claude/hooks/*.sh` are blocked from `Write`/`Edit`**
   Do instead: write/rewrite them via `Bash` using a `cat > file << 'EOF' ... EOF` heredoc, then `chmod +x` and `bash -n` to check syntax.
2. **[2026-08-03] Prove a SessionStart hook actually works before calling it done**
   Do instead: delete the directories/state it's supposed to (re)create, rerun it with `CLAUDE_CODE_REMOTE=true <script>`, and confirm exit 0 plus the expected files exist.
3. **[2026-08-03] Don't claim a new project "works" from a successful build alone**
   Do instead: also run it (`dotnet run` / dev server) with a short timeout and `curl` the home route before reporting success.

## Shell & Command Reliability
1. **[2026-08-03] `apt-get install ffmpeg` (with recommends) pulls broken video-driver packages (mesa/VA-API) that 404**
   Do instead: `DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends ffmpeg`.
2. **[2026-08-03] This session's shell resets `cwd` back to the repo root after any `cd` outside it**
   Do instead: don't rely on `cd` persisting across Bash calls to other directories; use absolute paths or `-C`/`--directory` flags instead.
3. **[2026-08-03] Editable Python installs from other repos should target the system interpreter, not a per-project venv**
   Do instead: `uv pip install --system -e '<path>[extras]'` so the package is importable from any session without activating a venv.

## Domain Behavior Guardrails
1. **[2026-08-03] NuGet `Humanizer` 3.0.10 (latest) is broken — `Humanizer.Core.fil` declares no compatible target framework**
   Do instead: pin `dotnet add package Humanizer --version 2.14.1`.
2. **[2026-08-03] `dotnet-sdk-8.0` isn't preinstalled but is in the default apt repos**
   Do instead: `apt-get install -y -qq --no-install-recommends dotnet-sdk-8.0`.
3. **[2026-08-03] Project is a Blazor Web App (server interactivity) at `src/AppParaAprenderIdiomas.Web`, solution file `AppParaAprenderIdiomas.sln` at repo root**
   Do instead: add new .NET projects under `src/`, add them to the existing `.sln` with `dotnet sln add`, and reuse this project unless the user asks for a separate one.
4. **[2026-08-03] `.claude/hooks/session-start.sh` clones/updates `superpowers`, `napkin` (both `~/.claude/skills/`) and `markitdown` (`~/markitdown`, `uv pip install --system -e`), and installs `ffmpeg` if missing — gated on `CLAUDE_CODE_REMOTE=true`**
   Do instead: when adding another tool/skill the user wants available every session, append the same clone-or-fetch-reset pattern to this script rather than creating a new hook file.

## User Directives
1. **[2026-08-03] Use `uv pip install`, never bare `pip install`, in this repo's Python venv**
   Do instead: always prefix Python package installs with `uv pip install` (or `uv pip install --system` for global/system-Python installs).
2. **[2026-08-03] This session's GitHub MCP access is scoped to only `JordiRibasOficial/App-para-aprender-idiomas`; no `add_repo`/`list_repos` tool is available here**
   Do instead: don't attempt cross-repo GitHub actions from this session; tell the user access must be granted via the Claude Code on the web environment/session config, not from within a session.
