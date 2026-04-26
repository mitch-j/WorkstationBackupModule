function Invoke-BackupGitSync {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot,

        [Parameter()]
        [string]$CommitMessage,

        [Parameter()]
        [switch]$SkipPull,

        [Parameter()]
        [switch]$SkipPush
    )

    Test-RequiredCommand -CommandName 'git' | Out-Null

    Push-Location -LiteralPath $RepoRoot
    try {
        if (-not $SkipPull) {
            if ($PSCmdlet.ShouldProcess($RepoRoot, 'Run git pull --rebase --autostash')) {
                Write-BackupLog 'Running git pull --rebase --autostash'
                & git pull --rebase --autostash
                if ($LASTEXITCODE -ne 0) {
                    throw 'git pull failed.'
                }
            }
        }

        if ($PSCmdlet.ShouldProcess($RepoRoot, 'Run git add --all')) {
            Write-BackupLog 'Running git add --all'
            & git add --all
            if ($LASTEXITCODE -ne 0) {
                throw 'git add failed.'
            }
        }

        $status = if ($WhatIfPreference) { 'simulated-change' } else { & git status --porcelain }
        if ($LASTEXITCODE -ne 0 -and -not $WhatIfPreference) {
            throw 'Failed to query git status.'
        }

        if ([string]::IsNullOrWhiteSpace(($status | Out-String))) {
            Write-BackupLog 'No git changes detected after backup stages.'
            return
        }

        if (-not $CommitMessage) {
            $identity = Get-WorkstationIdentity
            $CommitMessage = 'Workstation backup from {0} on {1}' -f $identity.ComputerName, $identity.DateStamp
        }

        if ($PSCmdlet.ShouldProcess($RepoRoot, "Run git commit with message '$CommitMessage'")) {
            Write-BackupLog "Running git commit -m '$CommitMessage'"
            & git commit -m $CommitMessage
            if ($LASTEXITCODE -ne 0) {
                throw 'git commit failed.'
            }
        }

        if (-not $SkipPush) {
            if ($PSCmdlet.ShouldProcess($RepoRoot, 'Run git push')) {
                Write-BackupLog 'Running git push'
                & git push
                if ($LASTEXITCODE -ne 0) {
                    throw 'git push failed.'
                }
            }
        }
    }
    finally {
        Pop-Location
    }
}
