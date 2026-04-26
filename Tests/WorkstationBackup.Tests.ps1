BeforeAll {
    $ModulePath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'WorkstationBackup\WorkstationBackup.psd1'
    Import-Module $ModulePath -Force
}

Describe 'WorkstationBackup Module' {
    Context 'Module Import' {
        It 'Should load the module successfully' {
            Get-Module WorkstationBackup | Should -Not -BeNullOrEmpty
        }

        It 'Should export public functions' {
            $functions = @(
                'Export-ChocoMachineBackup'
                'Export-InternalModuleBackup'
                'Export-PowerShellEnvironment'
                'Import-PowerShellEnvironment'
                'Invoke-WorkstationBackup'
                'Register-WorkstationBackupTask'
            )
            foreach ($function in $functions) {
                Get-Command -Name $function -Module WorkstationBackup -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Private Helper Functions' {
        It 'Should have Resolve-TemplateValue function' {
            Get-Content function:/Resolve-TemplateValue -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Ensure-Directory function' {
            Get-Content function:/Ensure-Directory -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Copy-IfDifferent function' {
            Get-Content function:/Copy-IfDifferent -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Configuration Management' {
        It 'Should have Read-PowerShellSyncConfig function' {
            Get-Content function:/Read-PowerShellSyncConfig -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should read config file successfully' {
            $configPath = Join-Path (Split-Path $ModulePath -Parent | Split-Path -Parent) 'powershell-sync.config.json'
            if (Test-Path $configPath) {
                { Read-PowerShellSyncConfig -Path $configPath } | Should -Not -Throw
            }
        }
    }

    Context 'Backup Functions' {
        It 'Should have Backup-PowerShellProfiles function' {
            Get-Content function:/Backup-PowerShellProfiles -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Backup-SettingsFiles function' {
            Get-Content function:/Backup-SettingsFiles -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Backup-OhMyPoshThemes function' {
            Get-Content function:/Backup-OhMyPoshThemes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Backup-WindowsTerminal function' {
            Get-Content function:/Backup-WindowsTerminal -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Restore Functions' {
        It 'Should have Restore-PowerShellProfiles function' {
            Get-Content function:/Restore-PowerShellProfiles -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Restore-SettingsFiles function' {
            Get-Content function:/Restore-SettingsFiles -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Restore-OhMyPoshThemes function' {
            Get-Content function:/Restore-OhMyPoshThemes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Restore-WindowsTerminal function' {
            Get-Content function:/Restore-WindowsTerminal -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Module Management' {
        It 'Should have Export-PowerShellModules function' {
            Get-Content function:/Export-PowerShellModules -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Import-PowerShellModules function' {
            Get-Content function:/Import-PowerShellModules -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Get-InstalledGalleryModuleRecords function' {
            Get-Content function:/Get-InstalledGalleryModuleRecords -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should have Sync-PSModulePath function' {
            Get-Content function:/Sync-PSModulePath -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Export-PowerShellEnvironment' {
        It 'Should accept -WhatIf parameter' {
            { Export-PowerShellEnvironment -WhatIf } | Should -Not -Throw
        }

        It 'Should export environment without errors' {
            { Export-PowerShellEnvironment -WhatIf -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'Import-PowerShellEnvironment' {
        It 'Should accept -WhatIf parameter' {
            { Import-PowerShellEnvironment -WhatIf } | Should -Not -Throw
        }

        It 'Should import environment without errors' {
            { Import-PowerShellEnvironment -WhatIf -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'Logging' {
        It 'Should have Write-BackupLog function' {
            Get-Content function:/Write-BackupLog -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should write log messages' {
            { Write-BackupLog -Message 'Test message' } | Should -Not -Throw
        }
    }
}

Describe 'Export-PowerShellEnvironment' {
    It 'loads config and invokes module export orchestrator'
    It 'sets PS_CONFIG_ROOT before export'
    It 'falls back to legacy script when -UseLegacyScript is specified'
    It 'passes -WhatIf to legacy script'
    It 'passes -UpdateFontConfigFromDiscovery to legacy script'
    It 'runs internal module backup when source and destination are provided'
    It 'skips internal module backup when paths are missing'
}

Describe 'Import-PowerShellEnvironment' {
    It 'loads config and invokes apply orchestrator'
    It 'sets PS_CONFIG_ROOT before import'
    It 'falls back to legacy script when -UseLegacyScript is specified'
    It 'passes -SkipFontInstallFailures to legacy script'
    It 'passes -WhatIf to legacy script'
}

Describe 'Invoke-WorkstationBackup' {
    It 'runs export flow'
    It 'runs git sync when enabled'
    It 'skips git pull when -SkipPull is specified'
    It 'skips git push when -SkipPush is specified'
    It 'does not commit when no git changes exist'
}

Describe 'Register-WorkstationBackupTask' {
    It 'creates a monthly scheduled task'
    It 'uses pwsh.exe as the executable'
    It 'targets the module entrypoint or wrapper'
    It 'supports -WhatIf'
}

Describe 'Invoke-ExportPowerShellEnvironment' {
    It 'calls export steps in legacy-compatible order'
    It 'includes font export'
    It 'includes machine-state export'
}

Describe 'Invoke-ApplyPowerShellEnvironment' {
    It 'imports modules before font prerequisites'
    It 'restores files after bootstrap'
    It 'restores fonts before Windows Terminal'
}

Describe 'Export-NerdFonts' {
    It 'skips when font backup is disabled'
    It 'writes inventory JSON'
    It 'discovers installed fonts when enabled'
    It 'does not discover fonts when discovery is disabled'
    It 'updates config when -UpdateFontConfigFromDiscovery is set'
}

Describe 'Restore-NerdFonts' {
    It 'skips when install on apply is disabled'
    It 'skips when no fonts are required'
    It 'installs only missing fonts'
    It 'throws on unknown font without skip flag'
    It 'warns and continues on unknown font with skip flag'
}

Describe 'Initialize-FontRestorePrerequisites' {
    It 'ensures Fonts module is available'
    It 'ensures NerdFonts module is available'
    It 'throws on unsupported provider'
    It 'warns instead when skip flag is set'
}

Describe 'Export-MachineState' {
    It 'writes machine-state.json'
    It 'includes PowerShell version'
    It 'includes PSModulePath snapshot'
    It 'infers active theme when profile contains oh-my-posh config'
}

Describe 'Invoke-BackupGitSync' {
    It 'skips when git sync is disabled'
    It 'stages changes when pending changes exist'
    It 'commits with expected message'
    It 'pushes unless -SkipPush is specified'
    It 'does nothing when working tree is clean'
}

Describe 'Module workflow integration' {
    It 'Export-PowerShellEnvironment invokes full export graph'
    It 'Import-PowerShellEnvironment invokes full apply graph'
    It 'Invoke-WorkstationBackup coordinates export and git sync'
}