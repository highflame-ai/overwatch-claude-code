# Highflame Overwatch — IDE hook script (Windows / PowerShell)
# Sends IDE hook events to Cerberus for real-time security evaluation.
#
# Usage: highflame-hook.ps1 <source> <event>
#   source: cursor | claudecode | github_copilot
#   event:  IDE-specific event name (e.g., PreToolUse, beforeSubmitPrompt)
#
# Environment:
#   HIGHFLAME_API_KEY  (required) Your Highflame API key.
#   HIGHFLAME_URL      (optional) Cerberus endpoint. Default: https://cerberus.highflame.ai

param(
    [string]$Source = "unknown",
    [string]$Event  = "unknown"
)

$ErrorActionPreference = "Stop"

$ApiKey  = $env:HIGHFLAME_API_KEY
$BaseUrl = if ($env:HIGHFLAME_URL) { $env:HIGHFLAME_URL } else { "https://cerberus.highflame.ai" }

# Fail-open: no API key → allow
if (-not $ApiKey) { exit 0 }

# Read IDE payload from stdin
$payload = [Console]::In.ReadToEnd()
if (-not $payload) { $payload = "{}" }

# Cross-IDE dedup: skip if Cursor fires a non-cursor hook
if ($Source -ne "cursor" -and $payload -match '"cursor_version"') { exit 0 }

# Wrap payload for Cerberus: {"source":"...","event":"...","payload":...}
# String concat (no re-serialization) preserves original payload bytes.
$body = '{"source":"' + $Source + '","event":"' + $Event + '","payload":' + $payload + '}'

try {
    $resp = Invoke-WebRequest `
        -Uri "$BaseUrl/v1/hooks/evaluate?format=ide" `
        -Method Post `
        -TimeoutSec 10 `
        -Headers @{ "Authorization" = "Bearer $ApiKey" } `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing
    if ($resp.Content) { Write-Output $resp.Content }
} catch {
    # Fail-open: network/HTTP failure → allow
}

exit 0
