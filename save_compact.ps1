# PreCompact hook: reads transcript_path from payload and saves full conversation.

$raw = $input | Out-String
$baseDir = "D:\ClaudeCompactedDiscussions"

try {
    $data      = $raw | ConvertFrom-Json -ErrorAction Stop
    $sessionId = if ($data.session_id) { $data.session_id } else { "unknown-session" }
    $transcript = $data.transcript_path

    # ── Read and parse JSONL ──────────────────────────────────────────────────
    $entries = @()
    if ($transcript -and (Test-Path $transcript)) {
        $entries = Get-Content $transcript -Encoding UTF8 | ForEach-Object {
            try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { $null }
        } | Where-Object { $_ -ne $null }
    }

    # ── Derive title from first human-typed user message ──────────────────────
    $firstUserMsg = $entries | Where-Object {
        $_.type -eq "user" -and $_.origin.kind -eq "human" -and
        $_.message.content -is [string] -and $_.message.content.Trim() -ne ""
    } | Select-Object -First 1

    $rawTitle = if ($firstUserMsg) {
        $firstUserMsg.message.content.Trim() -replace '\r?\n.*', ''  # first line only
    } else { "" }
    # Truncate to 60 chars, sanitize for filename
    if ($rawTitle.Length -gt 60) { $rawTitle = $rawTitle.Substring(0, 60) }
    $safeTitle  = ($rawTitle -replace '[\\/:*?"<>|]', '' -replace '\s+', '-').Trim('-')
    $fileSuffix = if ($safeTitle) { "-$safeTitle" } else { "" }

    # ── Output path ───────────────────────────────────────────────────────────
    $timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $sessionDir = Join-Path $baseDir $sessionId
    if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null }
    $outPath = Join-Path $sessionDir "compact-$timestamp$fileSuffix.md"

    # ── Build markdown ────────────────────────────────────────────────────────
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# Claude Compacted Session")
    $lines.Add("")
    $lines.Add("**Session ID:** $sessionId")
    $lines.Add("**Compacted at:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $lines.Add("**Trigger:** $($data.hook_event_name) / $($data.trigger)")
    if ($transcript) { $lines.Add("**Transcript:** $transcript") }
    $lines.Add("")
    $lines.Add("---")
    $lines.Add("")

    if ($entries.Count -gt 0) {
        $lines.Add("## Full Conversation")
        $lines.Add("")

        foreach ($entry in $entries) {
            if ($entry.type -eq "user" -and $entry.origin.kind -eq "human") {
                $lines.Add("### User")
                $lines.Add("")
                $text = if ($entry.message.content -is [string]) {
                    $entry.message.content
                } elseif ($entry.message.content -is [array]) {
                    ($entry.message.content | Where-Object { $_.type -eq "text" } | ForEach-Object { $_.text }) -join "`n"
                } else { "" }
                if ($text.Trim()) { $lines.Add($text.Trim()) }
                $lines.Add("")
            }
            elseif ($entry.type -eq "assistant") {
                # Collect only text blocks, skip thinking/tool_use
                $textParts = @()
                if ($entry.message.content -is [array]) {
                    foreach ($part in $entry.message.content) {
                        if ($part.type -eq "text" -and $part.text.Trim()) {
                            $textParts += $part.text.Trim()
                        }
                    }
                }
                if ($textParts.Count -gt 0) {
                    $lines.Add("### Assistant")
                    $lines.Add("")
                    $lines.Add($textParts -join "`n`n")
                    $lines.Add("")
                }
            }
        }
    } else {
        # Fallback: dump raw payload
        $lines.Add("## Raw Payload")
        $lines.Add("")
        $lines.Add('```json')
        $lines.Add($raw.Trim())
        $lines.Add('```')
    }

    $lines | Out-File -FilePath $outPath -Encoding utf8
} catch {
    # Silent fail — compaction must never be blocked
}
