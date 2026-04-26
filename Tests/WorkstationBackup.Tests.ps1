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
