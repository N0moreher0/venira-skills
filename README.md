# Venira MCP Skills

Four Anthropic-style skills (`.skill` files are zip archives containing `<name>/SKILL.md`). They tell the agent how to use the `project_*` tools the right way — the same conventions you expect the MCP server itself to follow.

Every skill ships in three equivalent shapes:

| Shape | Use | Path |
|---|---|---|
| `<name>.skill` (zip) | claude.ai / Claude Desktop GUI upload, Claude Code | repo root |
| `src/<name>/SKILL.md` | source of truth | repo root |
| combined instruction file | opencode / codex / antigravity | `clients/<name>/` |

## Skills

| Skill | Use when the user wants to… |
|---|---|
| `venira-coding-workflow` | write, fix, review, refactor or delete code — the standard orient → checkpoint → edit → verify → roll back loop |
| `venira-add-tool` | add/extend/register a tool in the server |
| `venira-debug-ci` | diagnose a red build, test or CI run from logs |
| `venira-git-pr` | commit, branch, push, open/maintain a PR, merge |

## Repo layout

```
src/<name>/SKILL.md      source of truth (edit these; everything else is built)
clients/                   per-client artefacts
  opencode/AGENTS.md       instructions block for opencode / Codex (shared)
  codex/AGENTS.md          same content as opencode/AGENTS.md
  antigravity/GEMINI.md    instructions block for Antigravity / Gemini CLI
  claude-code/skills/      uncompressed drop-ins for ~/.claude/skills/
  README.md                per-client table (how to install / activate)
install/install.ps1        single-command installer, dry-run by default
build-clients.ps1          rebuild clients/ from src/ (run after editing src/)
rebuild.ps1                 repack + SHA-256 verify .skill zips
```

## Install

```powershell
cd G:\Venira\Venira-mcp-skills

# dry-run; inspect what would change
.\install\install.ps1 -Client all -Path C:\path\to\project

# apply
.\install\install.ps1 -Client all -Apply -Path C:\path\to\project
```

This writes the marked block into `<project>/AGENTS.md` (used by both opencode and Codex) and `<project>/GEMINI.md` (Antigravity / Gemini CLI), and mirrors the four skills into `~/.claude/skills/`. For claude.ai / Claude Desktop, upload the `.skill` files via `Customize → Skills`.

Content outside the `<!-- venira-skills:begin --> ... <!-- venira-skills:end -->` markers is never touched. Files are backed up to `.bak` before any edit.

## Rules every skill assumes

- Tool names are written as the stable part (`project_read_file`); the client may prefix them (e.g. `mcp__venira__project_read_file`).
- Plain fast-forward `git push` is allowed without approval; force/delete/URL pushes still need one.
- Decisions are cached; external edits bypass the cache, so call `project_cache_clear` after touching files outside the server.
- Snapshots carry the recovery path; `action=restore` with `dry_run=1` first, `paths` to restore a subset.
- Approvals are human-only; a skill never grants one itself.

## Updating a skill

1. Edit `src/<name>/SKILL.md`. Tool names must stay spelled `project_*` and exist in `TOOL_DOCS` of the server (`tools/project-docs.ts`) or the skill will read as documentation for something that isn't there.
2. `.\build-clients.ps1` — rebuild `clients/` (AGENTS.md / GEMINI.md / claude-code drop-ins).
3. `.\rebuild.ps1 -Verify` — repack and SHA-256 check the `.skill` zips.
4. Anything already installed locally needs the installer re-run with `-Apply` to pick up the update. The marked block is replaced wholesale.
