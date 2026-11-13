# Where the skills go, per client

| Client | How the skills activate | Target file | Installed by |
|---|---|---|---|
| **opencode** | opencode loads `AGENTS.md` from the project root (or a parent dir) as standing instructions | `<repo>/AGENTS.md` | `install\install.ps1 -Client opencode -Apply -Path <repo>` |
| **Codex CLI** | codex loads `AGENTS.md` from the current directory upward | `<repo>/AGENTS.md` | `install\install.ps1 -Client codex -Apply -Path <repo>` |
| **antigravity / Gemini** | gemini-cli loads `GEMINI.md` from the project root | `<repo>/GEMINI.md` | `install\install.ps1 -Client antigravity -Apply -Path <repo>` |
| **Claude Code** | Claude Code discovers personal skills in `~/.claude/skills/<name>/SKILL.md` | `~/.claude/skills/venira-*/SKILL.md` | `install\install.ps1 -Client claude-code -Apply` |
| **Claude.ai web / desktop** | Customize → Skills → upload each `.skill` | claude.ai/settings or app GUI | manual upload (one-time) |
| **Claude Desktop (any OS)** | same GUI flow as Claude.ai desktop | app GUI | manual upload |
| **Generic MCP / other LLMs** | no skill mechanism; paste instructions into the system prompt | your client's instructions/system prompt | manually paste `clients/opencode/AGENTS.md` |
| **venira-mcp server** | skills are *not* tools; the MCP server only exposes `project_*`. Installing here means the *agent using the server* behaves the same on every client | n/a | see the table above |

## How the `.skill` upload actually works

Each `.skill` is a **single skill**: a zip archive containing exactly one `SKILL.md` (frontmatter `name` + `description`, then the body). Claude's upload UI accepts one file per action — so you upload each of the four files separately. That is not a limit of these skills; it is the format.

```text
venira-coding-workflow.skill        upload once
venira-add-tool.skill               upload once
venira-debug-ci.skill               upload once
venira-git-pr.skill                 upload once
```

If you want everything in one skill, that is technically possible (merge the four `SKILL.md` into one with one `name`/`description`) — but don't: Claude picks skills by matching the task to `description`, and one merged skill fires for everything, so you lose the targeted activation each of the four is designed for.

Notes per target:

- **opencode / codex** share one file: `<repo>/AGENTS.md`. The marked block is replaced on reruns, so re-running the installer after a skill update is safe and does not touch anything outside the markers.
- **GEMINI.md** works the same way with its own markers.
- **Claude Code** ignores `-Path`; it always writes `~/.claude/skills/`. The four `.skill` files are never referenced by Claude Code itself — only the uncompressed `SKILL.md` files matter.
- **claude.ai / Claude Desktop** skills uploaded manually are the same ones that `claude-code` uses; the difference is delivery (GUI vs filesystem), not content.

## One-liner to wire a new project

```powershell
cd G:\Venira\Venira-mcp-skills
.\install\install.ps1 -Client all -Apply -Path C:\path\to\project
```

It writes `AGENTS.md` (opencode + codex), `GEMINI.md` (antigravity), and mirrors the four skills into `~/.claude/skills/`. Nothing is overwritten outside the `<!-- venira-skills:begin --> ... <!-- venira-skills:end -->` block; anything replaced is backed up to `.bak`.

## Checking it works

Ask the agent something in scope, e.g. "add a tool to the server" (should load `venira-add-tool`) or "commit these changes" (should load `venira-git-pr`). If it does not, verify the file is in the project root and the agent can read it.
