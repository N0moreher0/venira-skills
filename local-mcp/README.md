# Local MCP setup (manual, separate from the plugin)

The `venira-mcp` plugin (`.claude-plugin/`) ships **skills only**. The MCP server is deliberately NOT bundled: if you already have a manual venira entry in your client config, installing the plugin must not spawn a second server.

Install the MCP **once per client**, manually, using one of the two options below.

## Option A — local build (recommended while developing / always up to date)

Requires `G:\Venira\venira-mcp-coding-standalone` built (`npm run build`; `dist/server.js` present) and Node >= 20.

### Claude Desktop / Cowork (`claude_desktop_config.json`)

Config location:
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "venira": {
      "command": "node",
      "args": ["G:\\Venira\\venira-mcp-coding-standalone\\dist\\server.js"],
      "env": {
        "VENIRA_TOOL_MODE": "default",
        "VENIRA_SECURITY_PROFILE": "balanced",
        "VENIRA_OUTPUT_MODE": "compact",
        "VENIRA_UNRESTRICTED": "0",
        "VENIRA_JS_EXEC_MODE": "off",
        "VENIRA_ALLOW_SELF_INSTALL": "0"
      }
    }
  }
}
```

### Claude Code (user scope)

```powershell
claude mcp add venira --scope user -- node G:\Venira\venira-mcp-coding-standalone\dist\server.js
```

Or edit `~/.claude.json` / project `.mcp.json` with the same `command`/`args`/`env` block.

### opencode (`opencode.json`)

```json
{
  "mcp": {
    "venira": {
      "type": "local",
      "command": ["node", "G:\\Venira\\venira-mcp-coding-standalone\\dist\\server.js"],
      "environment": {
        "VENIRA_TOOL_MODE": "default",
        "VENIRA_SECURITY_PROFILE": "balanced",
        "VENIRA_OUTPUT_MODE": "compact"
      },
      "enabled": true
    }
  }
}
```

## Option B — npm (`venira-mcp@latest`, for machines without the repo)

```powershell
claude mcp add venira --scope user -- npx -y venira-mcp@latest
```

or the same JSON block with:

```json
"command": "npx",
"args": ["-y", "venira-mcp@latest"],
```

Same env defaults as Option A apply (`default` / `balanced` / `compact`, JS exec off, self-install off).

## Rules

- Keep exactly ONE venira MCP entry per client. If the plugin ever grows an MCP connector again, remove the manual entry instead of running both.
- Skills (via the plugin or `~/.claude/skills/`) and the MCP server are independent: skills teach the workflow, the server exposes `project_*`.
- After updating the server repo (`git pull` + `npm run build`), a manual local install picks up changes on the client's next launch — the plugin route would not.
