# Venira MCP Skills

Four Anthropic-style skills (`.skill` files are zip archives containing `<name>/SKILL.md`). They tell the agent how to use the `project_*` tools the right way — the same conventions you expect the MCP server itself to follow.

## Layout

```
.skill            distributable zip, forward-slash entry name <name>/SKILL.md
src/<name>/SKILL.md   source of truth for the matching .skill
rebuild.ps1         repack + verify everything; -Verify SHA-256 checks zip == src
```

## Skills

| Skill | Use when the user wants to… |
|---|---|
| `venira-coding-workflow` | write, fix, review, refactor or delete code — the standard orient → checkpoint → edit → verify → roll back loop |
| `venira-add-tool` | add/extend/register a tool in the server |
| `venira-debug-ci` | diagnose a red build, test or CI run from logs |
| `venira-git-pr` | commit, branch, push, open/maintain a PR, merge |

## Rules every skill assumes

- Tool names are written as the stable part (`project_read_file`); the client may prefix them (e.g. `mcp__venira__project_read_file`).
- Plain fast-forward `git push` is allowed without approval; force/delete/URL pushes still need one.
- `project_*` tools are cache-aware; mutations outside the server bypass that cache, so after external edits call `project_cache_clear`.
- Snapshots are the recovery mechanism; `action=restore` with `dry_run=1` first, `paths` to restore a subset.
- Approvals are human-only; a skill never grants one.

## Updating a skill

1. Edit `src/<name>/SKILL.md`. Tool names must stay spelled `project_*` and exist in `TOOL_DOCS` of the server (`tools/project-docs.ts`) or the skill will read as documentation for something that isn't there.
2. Run `powershell -NoProfile -File .\rebuild.ps1 -Verify`. It packs `<name>/SKILL.md` into `<name>.skill` and SHA-256-compares the entries against `src/`.
3. Keep each `SKILL.md` under ~4 KB. If the front-matter `description` stops containing the trigger phrases (`"sửa code"`, `"tạo PR"`, `"CI fail"`…) activation will miss.
