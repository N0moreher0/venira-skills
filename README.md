# Venira Skills

The full Venira coding-agent bundle: five Anthropic-style skills plus the venira-mcp MCP server (files, search, shell, git, CI, PRs, checkpoints, audit — 38 tools in `default` mode), packaged as a plugin. One install gives a client both the tools and the workflow discipline.

| Shape | Use | Path |
|---|---|---|
| `skills/<name>/SKILL.md` | Claude Code / Cowork plugin | repo root |
| `.claude-plugin/plugin.json` | plugin manifest | repo root |
| `.claude-plugin/marketplace.json` | install catalog (repo is its own marketplace) | repo root |
| `.mcp.json` | bundled MCP server connector (`npx -y venira-mcp@latest`) | repo root |
| `local-mcp/` | manual MCP setup guide (local build, for developing the server itself) | repo root |
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
| `venira-memory` | read the workspace handoff note at the start, write it before you finish or run out of context |

## Install — Claude Code (one install: server + skills)

```powershell
claude plugin marketplace add N0moreher0/venira-skills   # from GitHub
# or, from a local clone:
cd G:\Venira\Venira-mcp-skills
claude plugin marketplace add ./
claude plugin install venira-mcp@venira-skills
```

The plugin carries the five skills and a stdio MCP entry for `venira-mcp@latest` with an end-user-safe default env (`TOOL_MODE=default`, `SECURITY_PROFILE=balanced`, `OUTPUT_MODE=compact`, `JS_EXEC_MODE=off`, `UNRESTRICTED=0`, `ALLOW_SELF_INSTALL=0`, `DYNAMIC_WORKSPACE=1`). With `VENIRA_DYNAMIC_WORKSPACE=1` the agent can call `switch_workspace` to re-root the server to whatever project folder is active — no client restart needed.

If you develop the server itself on this machine, prefer the manual local install instead and do not install both: see [`local-mcp/README.md`](local-mcp/README.md).

Uninstall:

```powershell
claude plugin uninstall venira-mcp@venira-skills
claude plugin marketplace remove venira-skills
```

## Install — Claude Desktop / Cowork (one install)

Same files. Either drop the folder into the app via **Add > Upload plugin** (accepts a `.zip` or `.plugin`; zip the folder first) or place it in the per-org plugins directory:

| Platform | Path |
|---|---|
| macOS | `/Library/Application Support/Claude/org-plugins/venira-mcp/` |
| Windows | `C:\Program Files\Claude\org-plugins\venira-mcp\` |

Cowork sessions will see all five skills, and the `venira-mcp` connector will be available from the Connectors tab after sign-in. No per-machine npm pre-install is needed — the connector runs `npx -y venira-mcp@latest` (Node ≥ 20 required).

Zip first (Windows):

```powershell
Compress-Archive -Path .\skills,.\.claude-plugin,.\.mcp.json,.\local-mcp,.\README.md,.\LICENSE -DestinationPath venira-mcp.plugin -Force
```

## Install — everything else

```powershell
.\install\install.ps1 -Client all -Apply -Path C:\path\to\project
```

This writes `AGENTS.md` (opencode + Codex), `GEMINI.md` (Antigravity / Gemini CLI), and mirrors the five skills into `~/.claude/skills/`. For the MCP server on those clients, follow [`local-mcp/README.md`](local-mcp/README.md).

For Claude Desktop / Cowork GUI upload, a pre-built plugin bundle is at `venira-mcp.plugin` (git-ignored; rebuild with: `Compress-Archive -Path @('.claude-plugin','skills','.mcp.json','local-mcp','README.md','LICENSE') -DestinationPath venira-mcp.plugin -Force`).

## Repo layout

```
skills/<name>/SKILL.md      source of truth (edit these; clients/ and .skill are built)
.claude-plugin/             plugin.json + marketplace.json (install via `claude plugin install venira-mcp@venira-skills`)
.mcp.json                   bundled MCP server connector (npx venira-mcp@latest)
local-mcp/                  manual MCP setup guide (local build; for server development)
clients/                    per-client artefacts (AGENTS.md / GEMINI.md)
install/install.ps1         installer for opencode / Codex / Antigravity / Claude Code (skills-only)
build-clients.ps1           rebuild clients/ from skills/ (run after editing skills/)
rebuild.ps1                 repack + SHA-256 verify .skill zips
clients/README.md           per-client matrix
```

## Rules every skill assumes

- Tool names are written as the stable part (`read_file`); the client may prefix them (e.g. `mcp__venira__read_file`).
- Plain fast-forward `git push` is allowed without approval; force/delete/URL pushes still need one.
- Decisions are cached; external edits bypass the cache, so call `cache_clear` after touching files outside the server.
- Snapshots carry the recovery path; `action=restore` with `dry_run=1` first, `paths` to restore a subset.
- Approvals are human-only; a skill never grants one itself.

## Updating a skill

1. Edit `skills/<name>/SKILL.md`. Tool names must stay spelled without the `project_` prefix (e.g. `read_file`) and exist in `TOOL_DOCS` of the server (`tools/project-docs.ts`) or the skill will read as documentation for something that isn't there.
2. `.\rebuild.ps1 -Verify` — repack and SHA-256 check the `.skill` zips.
3. `.\build-clients.ps1` — rebuild `clients/` (opencode / Codex / Antigravity).
4. Anything already installed locally needs re-running (`install/install.ps1 -Apply`) or reinstalling the plugin to pick up the update.
