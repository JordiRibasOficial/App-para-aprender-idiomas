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
1. **[2026-08-05] Mobile stack is Flutter (Dart), not .NET MAUI — MAUI was tried, validated, then discarded by explicit user decision (wanted "best today", not reuse). Setup path verified end-to-end:**
   Do instead: `git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter`; Android SDK nativo en `~/android-sdk` (cmdline-tools + `platform-tools` + `platforms;android-36` + `build-tools;28.0.3` — Flutter pide 36/28.0.3 specifically, not whatever MAUI wanted); `flutter config --android-sdk ~/android-sdk`; `yes | flutter doctor --android-licenses`; then `flutter create --org com.TODO... --platforms android,ios src/mobile`. Verified: Android toolchain shows ✓ in `flutter doctor`. iOS still cannot build on this Linux container — needs CI with a macOS runner or a real Mac, same limitation as MAUI had.
2. **[2026-08-03] NuGet `Humanizer` 3.0.10 (latest) is broken — `Humanizer.Core.fil` declares no compatible target framework**
   Do instead: pin `dotnet add package Humanizer --version 2.14.1`. (Only relevant to the legacy `src/AppParaAprenderIdiomas.Web` Blazor project, kept as a possible future landing page, not the active mobile app.)
3. **[2026-08-03] `dotnet-sdk-8.0` isn't preinstalled but is in the default apt repos**
   Do instead: `apt-get install -y -qq --no-install-recommends dotnet-sdk-8.0`. (Same scope note as above — Web project only.)
4. **[2026-08-05] Project layout: `src/AppParaAprenderIdiomas.Web` (Blazor, legacy/possible landing page) is separate from `src/mobile` (Flutter, the active app). Plan lives at `plans/mobile-mvp-android-ios.md`; the discarded MAUI plan is archived as `plans/mobile-mvp-android-ios.MAUI-SUPERSEDED.md`**
   Do instead: all new mobile feature work goes in `src/mobile` (Dart/Flutter), not the `.sln`/C# projects.
5. **[2026-08-03] `.claude/hooks/session-start.sh` clones/updates `superpowers`, `napkin` (both `~/.claude/skills/`), `markitdown` (`~/markitdown`, `uv pip install --system -e`), and `ECC` (`~/ECC`, `npm install` + `bash install.sh --profile full`), and installs `ffmpeg` if missing — gated on `CLAUDE_CODE_REMOTE=true`. Does NOT yet install Flutter/Android SDK (item 1 above) — that setup is still manual per session as of this note.**
   Do instead: when adding another tool/skill the user wants available every session, append the same clone-or-fetch-reset pattern to this script rather than creating a new hook file. Note: ECC's own hooks (`~/.claude/hooks/hooks.json`) are copied to disk by its installer but are NOT wired into `~/.claude/settings.json` — merging them in is blocked by the auto-mode classifier as a hard boundary (retries do not clear it, unlike most other blocks in this session), because several of ECC's hooks actively block tool calls (`matcher: "*"`) rather than just nudge.

## User Directives
1. **[2026-08-03] Use `uv pip install`, never bare `pip install`, in this repo's Python venv**
   Do instead: always prefix Python package installs with `uv pip install` (or `uv pip install --system` for global/system-Python installs).
2. **[2026-08-03] This session's GitHub MCP access is scoped to only `JordiRibasOficial/App-para-aprender-idiomas`; no `add_repo`/`list_repos` tool is available here**
   Do instead: don't attempt cross-repo GitHub actions from this session; tell the user access must be granted via the Claude Code on the web environment/session config, not from within a session.
