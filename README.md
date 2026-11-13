# Venira Skills

Four Anthropic-style skills teaching any Claude client the Venira coding-agent workflow. This repo packages the skills; the **venira-mcp MCP server is installed separately** and is intentionally not bundled, so it never duplicates a manually configured local MCP.

| Shape | Use | Path |
|---|---|---|
| `skills/<name>/SKILL.md` | Claude Code / Cowork plugin | repo root |
| `.claude-plugin/plugin.json` | plugin manifest (skills only) | repo root |
| `.claude-plugin/marketplace.json` | install catalog (no git host needed) | repo root |
| `local-mcp/` | manual MCP setup guide (local build preferred, npm option) | repo root |
| `clients/` | opencode / Codex / Antigravity instructions (drop-in) | repo root |
| `install/` | one-command installer for non-plugin clients | repo root |
| `<name>.skill` | claude.ai GUI upload | repo root |

## Skills

| Skill | Use when the user wants to… |
|---|---|
| `venira-coding-workflow` | write, fix, review, refactor or delete code — the standard orient → checkpoint → edit → verify → roll back loop |
| `venira-add-tool` | add/extend/register a tool in the server |
| `venira-debug-ci` | diagnose a red build, test or CI run from logs |
| `venira-git-pr` | commit, branch, push, open/maintain a PR, merge |

## Install — Claude Code (skills via plugin; MCP separately)

```powershell
cd G:\Venira\Venira-mcp-skills
claude plugin marketplace add ./              # repo is its own marketplace
claude plugin install venira-mcp@venira-skills
```

The plugin carries the four skills only. Install the venira-mcp server once per client as described in [`local-mcp/README.md`](local-mcp/README.md) (local `dist/server.js` recommended; `npx -y venira-mcp@latest` for machines without the repo). Installing both does **not** duplicate anything, because the plugin registers no MCP connector.

Uninstall:

```powershell
claude plugin uninstall venira-mcp@venira-skills
claude plugin marketplace remove venira-skills
```

## Install — Claude Desktop / Cowork GUI upload

Same files. Either drop the folder into the app via **Add > Upload plugin** (accepts a `.zip` or `.plugin`; zip the folder first) or place it in the per-org plugins directory:

| Platform | Path |
|---|---|
| macOS | `/Library/Application Support/Claude/org-plugins/venira-mcp/` |
| Windows | `C:\Program Files\Claude\org-plugins\venira-mcp\` |

Cowork sessions will see all four skills. The venira-mcp connector is **not** part of the plugin — configure it manually in `claude_desktop_config.json` per [`local-mcp/README.md`](local-mcp/README.md).

Zip first (Windows):

```powershell
Compress-Archive -Path .\skills,.\.claude-plugin,.\local-mcp,.\README.md,.\LICENSE -DestinationPath venira-mcp.plugin -Force
```

## Install — everything else

```powershell
.\install\install.ps1 -Client all -Apply -Path C:\path\to\project
```

This writes `AGENTS.md` (opencode + Codex), `GEMINI.md` (Antigravity / Gemini CLI), and mirrors the four skills into `~/.claude/skills/`. For the MCP server, see [`local-mcp/README.md`](local-mcp/README.md).

For Claude Desktop / Cowork GUI upload, a pre-built plugin bundle is at `venira-mcp.plugin` (git-ignored; rebuild with: `Compress-Archive -Path @('.claude-plugin','skills','local-mcp','README.md','LICENSE') -DestinationPath venira-mcp.plugin -Force`).

## Repo layout

```
skills/<name>/SKILL.md      source of truth (edit these; clients/ and .skill are built)
.claude-plugin/             plugin.json + marketplace.json (skills-only plugin)
local-mcp/                  manual MCP setup guide, separate from the plugin
clients/                    per-client artefacts (AGENTS.md / GEMINI.md)
install/install.ps1         installer for opencode / Codex / Antigravity / Claude Code (skills-only)
build-clients.ps1           rebuild clients/ from skills/ (run after editing skills/)
rebuild.ps1                 repack + SHA-256 verify .skill zips
clients/README.md           per-client matrix
```

## Rules every skill assumes

- Tool names are written as the stable part (`project_read_file`); the client may prefix them (e.g. `mcp__venira__project_read_file`).
- Plain fast-forward `git push` is allowed without approval; force/delete/URL pushes still need one.
- Decisions are cached; external edits bypass the cache, so call `project_cache_clear` after touching files outside the server.
- Snapshots carry the recovery path; `action=restore` with `dry_run=1` first, `paths` to restore a subset.
- Approvals are human-only; a skill never grants one itself.

## Updating a skill

1. Edit `skills/<name>/SKILL.md`. Tool names must stay spelled `project_*` and exist in `TOOL_DOCS` of the server (`tools/project-docs.ts`) or the skill will read as documentation for something that isn't there.
2. `.\rebuild.ps1 -Verify` — repack and SHA-256 check the `.skill` zips.
3. `.\build-clients.ps1` — rebuild `clients/` (opencode / Codex / Antigravity).
4. Anything already installed locally needs re-running (`install/install.ps1 -Apply`) or reinstalling the plugin to pick up the update.
