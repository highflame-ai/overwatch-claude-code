# Overwatch — Claude Code Plugin

Routes Claude Code hook events directly to the Highflame Cerberus security backend for real-time evaluation (prompt-injection detection, tool-call gating, session auditing).

This is the **daemon-less** install path: no local process, no background service — just the plugin and an API key. If you want the local-daemon path instead, install `@highflame/overwatch` from npm.

## Plugins

| Plugin              | Platform      |
|---------------------|---------------|
| `overwatch-mac`     | macOS / Linux |
| `overwatch-windows` | Windows       |

Each plugin wires the same Claude Code hook events and forwards them to `POST /v1/hooks/evaluate?format=ide` on Cerberus:

- `PreToolUse` (matcher `.*`) — gate tool calls before execution
- `PostToolUse` (matcher `.*`) — audit after tool completes
- `UserPromptSubmit` — inspect user prompts
- `SessionStart` — session-level context
- `Stop` — agent stop signal
- `Notification` — Claude Code notifications (e.g. permission prompts)

Cerberus responds in Claude Code's native hook JSON format (via `?format=ide`), so blocking / allow decisions are handled end-to-end.

## Install

From the Claude Code CLI:

```
/plugin marketplace add highflame/overwatch-claude-code
/plugin install overwatch-mac        # or overwatch-windows
```

For local development, point the marketplace at this checkout:

```
/plugin marketplace add file:///absolute/path/to/overwatch-claude-code
/plugin install overwatch-mac
```

## Configuration

Set these in your shell environment (the Claude Code process must inherit them):

| Variable            | Required | Default                          | Purpose                  |
|---------------------|----------|----------------------------------|--------------------------|
| `HIGHFLAME_API_KEY` | yes      | —                                | Your Highflame API key   |
| `HIGHFLAME_URL`     | no       | `https://cerberus.highflame.ai`  | Cerberus endpoint (override for self-hosted or local dev) |

If `HIGHFLAME_API_KEY` is not set, the hook exits 0 silently (fail-open). Claude Code is never blocked by a missing key or a network failure.

## Alternatives

- **Local daemon** — install `@highflame/overwatch` (npm) and use `~/.overwatch/universal-hook.sh`. The daemon listens on `127.0.0.1:17580` and auto-starts.
- **Manual hooks** — configure `~/.claude/settings.json` directly using the templates in `highflame-ramparts/packages/guardian/hooks/claudecode/`.

## License

Apache-2.0.
