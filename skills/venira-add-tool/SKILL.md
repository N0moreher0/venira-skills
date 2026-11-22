---
name: venira-add-tool
description: End-to-end guide for adding a new tool to a Venira-style MCP server codebase (tool file, registration, input schema, verification script, docs, changelog). Use this skill whenever the user wants to add, extend, rename, or register a tool, a bare tool command, or an MCP endpoint in the Venira server, even if they just say "thêm tool" or "new tool" without more detail.
---

# Add a tool to the Venira MCP server

New tools must look and behave like the existing ones, because clients and agents rely on consistent descriptions, schemas, and error shapes. Several checks fail CI when a tool is added half-way, so learn the conventions from the code, then copy them.

## 1. Learn the conventions first

- Read the repo's `AGENTS.md` (section "Contracts that break CI") and `README.md` before the first edit. `CONTRIBUTING.md` "Adding a tool" is older: when it disagrees with `AGENTS.md` or the code, follow the code.
- `recent_files` and `list_files` on the `tools/`, `lib/`, and `scripts/` folders.
- Tools register in `tools/project-register-<group>.ts` (files, shell, ops, codeintel, workflow, vcs), wired from `tools/project.ts`. Find the neighbours with `search` (kind `literal_content`) for an existing tool name, then read one small read-only tool and one mutating tool with `read_file` (`requests[]`).
- Note the shared helpers: `config()` and the zod fragments in `tools/project-schema.ts`, envelopes from `lib/output.ts` (`buildEnvelope`, `errorEnvelope`, `batchEnvelope`; never hand-roll one), workspace path validation, audit logging, output-mode trimming.

## 2. Design the tool

- Name: bare `<verb>_<noun>` (no `project_` prefix) or one noun when it has an `action` parameter, like `git`, `snapshot` and `memory`. Prefer folding a variant into an existing tool with `action`: every tool costs schema tokens on every prompt, and `scripts/schema-budget.json` ratchets the ceilings.
- Description: do not put it in `config()`. The model-facing wording lives in `TOOL_DOCS` (`tools/project-docs.ts`) as `about`, `use`, `avoid` and `out`: one sentence of what it does with the one limit that matters, the trigger, the better sibling tool by name, and the fields the caller reads. Say a thing once. No speed or batch commentary.
- Input schema (zod v4): bounded numbers (min/max), flags advertised as booleans (`flag01`, `backgroundFlag` in `project-schema.ts`; the parser still accepts `1`/`0`), a non-empty description on every parameter, and an optional `reason` (max 400 characters, audit-logged) on anything that mutates.
- Decide read-only vs mutating up front. Mutating tools need path safety, the same audit path and cache invalidation as `write_file`, and snapshot or rollback advice in their description.
- Decide which modes get it. `core` is an allowlist (`CORE_TOOLS` in `tools/project-tool-mode.ts`) and stays small on purpose; `default` is everything except `SHIPPING_EXCLUDES` (PR/CI tools and the diagnostics kit); `expert` has all.

## 3. Implement

Checkpoint first with `snapshot`, with `paths` covering the registry file, `tools/project-docs.ts`, `tools/project-tool-mode.ts`, `scripts/schema-budget.json`, `scripts/check-docs.ts`, README and CHANGELOG. Then create the tool code with `write_file` (`mode=create`) and register it with `edit_file`. Reuse shared helpers instead of re-implementing path checks or error handling. ESM: relative imports end in `.js` even though the source is `.ts`. Any script under `scripts/` that touches `VENIRA_*` must `import "./clean-env.js"` first.

## 4. Contracts CI enforces

1. Registered in the right `tools/project-register-*.ts` through `config()`.
2. A `TOOL_DOCS` entry in `tools/project-docs.ts` (`test:tool-schema` fails without it).
3. Its `tools/list` size recorded in `scripts/schema-budget.json`: `npm run test:schema-budget -- --update --allow-increase`. A tool with no ceiling fails, and ceilings otherwise only ratchet down.
4. Tool counts changed: update the README count strings and `EXPECTED_DEFAULT_TOOLS` / `EXPECTED_EXPERT_TOOLS` in `scripts/check-docs.ts` together (`check:docs` fails otherwise). A new `core` tool also changes the core count.
5. A new `VENIRA_*` variable goes into `ENV_REGISTRY` (`lib/env-registry.ts`) and the README env table.
6. If it belongs in the agent flow, one line in the `INSTRUCTIONS` block of `server.ts`.
7. Releasing: the version must agree in `package.json`, `package-lock.json` (`version` and `packages[""].version`), `server.json` (`version` and `packages[]`) and `lib/version.ts`.

## 5. Verify

- Add a check to the matching section under `scripts/verify/`, or a dedicated `scripts/test-<name>.ts` with a `test:<name>` script in `package.json`, and wire it into the `verify` chain. Cover success, a not-found or invalid input, and any size limits.
- `npm run build` first: `scripts/verify.ts` and `scripts/doctor.ts` launch `node dist/server.js`, so they test the build, not your source. Then `npx tsc --noEmit`, the narrowest `npm run test:<name>`, and finally `npm run check:docs`, `npm run check:source-shape` and `npm run verify`. Run `npm run doctor` on host-sensitive changes. Use `shell_run` and read `command_status` and `exit_code`; feed failures to `explain_error` when it is in your tool list (expert mode).
- Remember that a running MCP client keeps serving the old build until it restarts.

## 6. Document and report

Update the README tool table and the section for the tool's family, and add a CHANGELOG entry (schema budget changes included). Then review everything with `git action=diff` and report: tool name, files touched, snapshot id, and which checks passed.
