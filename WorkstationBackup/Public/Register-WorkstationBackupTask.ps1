<#
.SYNOPSIS
    Registers a Windows scheduled task to run workstation backups.

.DESCRIPTION
    Creates a Windows Scheduled Task that invokes the public backup wrapper script
    with the configured backup repository root. This allows periodic, unattended
    backup execution using the module's standard workflow.

.PARAMETER RepoRoot
    Root directory of the backup repository. If not specified, the repository root is
    resolved from the module location.

.PARAMETER TaskName
    Name of the scheduled task to register.

.PARAMETER ScheduledDayOfMonth
    Day of month on which the monthly backup task runs.

.PARAMETER ScheduledTime
    Time of day when the task should execute, in HH:mm format.

.PARAMETER PwshPath
    Path to the PowerShell executable used by the scheduled task.

.PARAMETER SkipGit
    Skip Git sync when the scheduled backup runs.

.PARAMETER SkipPowerShellBackup
    Skip the PowerShell environment backup stage when the task runs.

.PARAMETER SkipChocoBackup
    Skip the Chocolatey package backup stage when the task runs.

.EXAMPLE
    Register-WorkstationBackupTask -RepoRoot 'C:\Dev\work\backup-repo' -ScheduledDayOfMonth 1 -ScheduledTime '02:00'

    Registers a monthly backup task for the backup repo.

.NOTES
    - Only supported on Windows.
    - The task runs the wrapper script at `$RepoRoot\Scripts\Invoke-WorkstationBackup.ps1`.
    - The scheduled task is created with Highest run level and Interactive logon type.

.INPUTS
    None.

.OUTPUTS
    None.
#>
function Register-WorkstationBackupTask {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$TaskName = 'WorkstationBackup',

        [Parameter()]
        [ValidateRange(1, 28)]
        [int]$ScheduledDayOfMonth = 1,

        [Parameter()]
        [ValidatePattern('^\d{2}:\d{2}$')]
        [string]$ScheduledTime = '09:00',

        [Parameter()]
        [string]$PwshPath = 'pwsh.exe',

        [Parameter()]
        [switch]$SkipGit,

        [Parameter()]
        [switch]$SkipPowerShellBackup,

        [Parameter()]
        [switch]$SkipChocoBackup
    )

    if ($IsLinux -or $IsMacOS) {
        throw 'Scheduled task registration is implemented only for Windows.'
    }

    Test-RequiredCommand -CommandName 'Register-ScheduledTask' | Out-Null

    $RepoRoot = Get-WorkstationBackupRoot -RepoRoot $RepoRoot -ModuleRoot $PSScriptRoot
    $entryScriptPath = Join-Path $RepoRoot 'Scripts\Invoke-WorkstationBackup.ps1'

    if (-not (Test-Path -LiteralPath $entryScriptPath)) {
        throw "Expected public entry script at '$entryScriptPath'."
    }

    $parsedTime = [datetime]::ParseExact($ScheduledTime, 'HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
    $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $entryScriptPath), '-RepoRoot', ('"{0}"' -f $RepoRoot))
    if ($SkipGit) { $argumentList += '-SkipGit' }
    if ($SkipPowerShellBackup) { $argumentList += '-SkipPowerShellBackup' }
    if ($SkipChocoBackup) { $argumentList += '-SkipChocoBackup' }

    $action = New-ScheduledTaskAction -Execute $PwshPath -Argument ($argumentList -join ' ')
    $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth $ScheduledDayOfMonth -At $parsedTime.TimeOfDay
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

    if ($PSCmdlet.ShouldProcess($TaskName, 'Register scheduled workstation backup task')) {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
        Write-BackupLog "Registered scheduled task '$TaskName' to run monthly on day $ScheduledDayOfMonth at $ScheduledTime."
    }
}
