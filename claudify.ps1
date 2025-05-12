# Place this in your PowerShell profile (e.g. $PROFILE)
function claudify {
    [CmdletBinding(DefaultParameterSetName='Run')]
    param(
        [Parameter(Mandatory=$false, ParameterSetName='Run', ValueFromRemainingArguments=$true)]
        [string[]]$Args,
        [switch]$Help
    )

    if ($Help) {
        @"
Usage: claudify [command]

If you provide a COMMAND, it will be re-run and its output sent to Claude Code.
Otherwise, claudify will re-run your previous PowerShell command.

Options:
  -Help    Show this help message and exit.

Examples:
  claudify           # re-run last command and fix
  claudify npm test  # re-run 'npm test' and fix
"@ | Write-Host
        return
    }

    # Determine command
    if ($Args.Count -gt 0) {
        $cmd = $Args -join ' '
        Write-Verbose "[claudify] using explicit cmd: $cmd"
    } else {
        $history = Get-History -Count 2
        if ($history.Count -lt 2) {
            Write-Error "[claudify] error: no previous command found. Provide a command explicitly or run more commands in this session."
            return
        }
        $cmd = $history[0].CommandLine
        Write-Verbose "[claudify] grabbed last cmd: $cmd"
    }

    Write-Verbose "[claudify] re-running → $cmd"
    $output = Invoke-Expression $cmd 2>&1 | Out-String
    $len = $output.Length
    Write-Verbose "[claudify] captured output ($len bytes)"

    $prompt = "Please fix this:`n`n`$ $cmd`n$output"

    Write-Verbose "[claudify] invoking Claude Code now..."
    claude -p $prompt `
           --print `
           --output-format stream-json `
           --allowedTools "Edit Write" `
           --debug 2> "$env:TEMP\claudify-debug.log" |
      ConvertFrom-Json |
      ForEach-Object { $_.content | ForEach-Object { $_.text } }
}
