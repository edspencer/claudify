# Place this in your PowerShell profile (e.g. $PROFILE)
function claudify {
    [CmdletBinding()]
    param(
        [Alias('h','help','?')]
        [switch]$Help,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Header
    )

    if ($Help) {
        @"
Usage: claudify [prompt]

Re-run your previous shell command and send its output to Claude Code,
using an optional custom prompt header instead of the default.

Options:
  -Help, -h, -?   Show this help message and exit.

Examples:
  claudify                   # re-run last command with default header
  claudify "Explain this error:"  # custom prompt header
"@ | Write-Host
        return
    }

    # Determine prompt header
    if ($Header.Count -gt 0) {
        $header = $Header -join ' '
        Write-Verbose "[claudify] using custom prompt header: $header"
    } else {
        $header = 'Please fix this:'
        Write-Verbose "[claudify] using default prompt header: $header"
    }

    # Get last command from history
    $history = Get-History -Count 2
    if ($history.Count -lt 2) {
        Write-Error "[claudify] no previous command found; please run a command first or provide one explicitly."
        return
    }
    $cmd = $history[0].CommandLine
    Write-Verbose "[claudify] grabbed last cmd: $cmd"

    # Re-run and capture output
    Write-Verbose "[claudify] re-running → $cmd"
    $output = Invoke-Expression $cmd 2>&1 | Out-String
    Write-Verbose "[claudify] captured output ($($output.Length) bytes)"

    # Build prompt
    $prompt = "$header`n`n`$ $cmd`n$output"

    # Invoke Claude Code
    Write-Verbose "[claudify] invoking Claude Code now..."
    Write-Host
    Write-Host "[Response from Claude]:"
    claude -p $prompt `
           --output-format stream-json `
           --allowedTools "Edit Write" `
           --debug 2> "$env:TEMP\claudify-debug.log" |
      ConvertFrom-Json |
      ForEach-Object { $_.content } |
      ForEach-Object { $_.text }
}
