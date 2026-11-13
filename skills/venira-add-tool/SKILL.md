---
name: venira-add-tool
description: End-to-end guide for adding a new tool to a Venira-style MCP server codebase (tool file, registration, input schema, verification script, docs, changelog). Use this skill whenever the user wants to add, extend, rename, or register a tool, a project_* command, or an MCP endpoint in the Venira server, even if they just say "thêm tool" or "new tool" without more detail.
---

# Add a tool to the Venira MCP server

New tools must look and behave like the existing ones, because clients and agents rely on consistent descriptions, schemas, and error shapes. Learn the conventions from the code, then copy them.

## 1. Learn the conventions first

- `project_recent_files` and `project_list_files` on the `tools/`, `lib/`, and `scripts/verify/` folders.
- Read one or two tools close to the new one (for example a small read-only tool and a mutating one) with `project_read_batch`.
- Find where tools are registered: `project_search` (kind `literal_content`) for an existing tool name, and follow it to the registry.
- Note the helpers the existing tools share: workspace path validation, error codes, audit logging, output-mode trimming.

## 2. Design the tool

- Name: `project_<verb>_<noun>`, consistent with neighbours.
- Description: follow the house style seen in existing tools: one line of what it does, then `Use when:`, `Avoid when:`, and `Output:`.
- Input schema: bounded numbers (min/max), `0/1` flags the way existing tools do them, and an optional `reason` for the audit log if the tool mutates anything.
- Decide read-only vs mutating up front. Mutating tools need path safety and snapshot or rollback advice in their description.

## 3. Implement

Checkpoint first with `project_snapshot` (include the registry file, README, and CHANGELOG in `paths`). Then create the tool file with `project_write_file` (`mode=create`) and register it with `project_edit_file`. Reuse shared helpers instead of re-implementing path checks or error handling.

## 4. Verify

- Add a case to the matching script under `scripts/verify/` (or a dedicated test script) covering success, a not-found or invalid input, and any size limits.
- Run the type-check/build and the verify script with `project_shell_run`. Feed failures to `project_explain_error`.
- Run the project's doctor or consistency script if one exists, since it often cross-checks the tool list against docs.

## 5. Document

Update the README tool list and add a CHANGELOG entry. Then review everything with `project_git_diff` and report: tool name, files touched, snapshot id, and which checks passed.
