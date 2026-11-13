# Where the skills go, per client

| Client | How the skills activate | Target file | Installed by |
|---|---|---|---|
| **Claude Code + plugin** | one install: plugin carries the four skills and the MCP connector (`npx venira-mcp@latest`) | `<repo-root>\` as a marketplace | `claude plugin marketplace add ./ && claude plugin install venira-mcp@venira-skills` |
| **Claude Desktop / Cowork** | Add > Upload plugin (.zip or .plugin), or per-org plugin directory | app GUI | manual upload or org-plugins dir |
| **opencode** | opencode loads `AGENTS.md` from the project root (or a parent dir) as standing instructions | `<repo>/AGENTS.md` | `install\install.ps1 -Client opencode -Apply -Path <repo>` |
| **Codex CLI** | codex loads `AGENTS.md` from the current directory upward | `<repo>/AGENTS.md` | `install\install.ps1 -Client codex -Apply -Path <repo>` |
| **Antigravity / Gemini** | gemini-cli loads `GEMINI.md` from the project root | `<repo>/GEMINI.md` | `install\install.ps1 -Client antigravity -Apply -Path <repo>` |
| **Claude Code (skills only, no plugin)** | Claude Code discovers personal skills in `~/.claude/skills/<name>/SKILL.md` | `~/.claude/skills/venira-*/SKILL.md` | `install\install.ps1 -Client claude-code -Apply` |
| **Claude.ai web / desktop (no plugin)** | Customize → Skills → upload each `.skill` | claude.ai/settings or app GUI | manual upload (one-time) |
| **Generic MCP / other LLMs** | no skill mechanism; paste instructions into the system prompt | your client's instructions/system prompt | manually paste `clients/opencode/AGENTS.md` |
| **venira-mcp server** | skills are *not* tools; the MCP server only exposes `project_*`. The plugin bundles it for end users (`npx venira-mcp@latest`); this file covers the manual route, which server developers should prefer | see above | see above |

Notes per target:

- **opencode / codex** share one file: `<repo>/AGENTS.md`. The marked block is replaced on reruns, so re-running the installer after a skill update is safe and does not touch anything outside the markers.
- **GEMINI.md** works the same way with its own markers.
- Claude Code **plus the plugin does not conflict** with the personal-skills mirror: Claude unions both.
- **Claude Code (plugin only)**: skills come from the plugin's own `skills/` directory and load the moment the plugin is installed — nothing to upload, nothing to commit per project.
- **claude.ai / Claude Desktop** skills uploaded manually are the same ones the plugin installs; the difference is delivery (GUI vs plugin bundle), not content.

## One-liner to wire a new project

```powershell
cd G:\Venira\Venira-mcp-skills
.\install\install.ps1 -Client all -Apply -Path C:\path\to\project
```

It writes `AGENTS.md` (opencode + Codex), `GEMINI.md` (Antigravity / Gemini CLI), and mirrors the four skills into `~/.claude/skills/`. For Claude Code / Desktop, install the plugin once — it covers both the skills and the MCP server, and you are done (unless you develop the server on this machine, in which case see [local-mcp/README.md](../local-mcp/README.md)).

## Checking it works

Ask the agent something in scope, e.g. "add a tool to the server" (should load `venira-add-tool`) or "commit these changes" (should load `venira-git-pr`). If it does not, verify the file is in the project root and the agent can read it (or the plugin is installed).
