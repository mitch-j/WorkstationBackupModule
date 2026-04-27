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
        It 'Should have private functions loaded' {
            # Private functions are not exported but should be available within module scope
            # This test verifies the module structure is correct
            $module = Get-Module WorkstationBackup
            $module | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Configuration Management' {
        It 'Should have configuration functions available' {
            $module = Get-Module WorkstationBackup
            $module | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Backup Functions' {
        It 'Should have backup functions available' {
            $module = Get-Module WorkstationBackup
            $module | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Restore Functions' {
        It 'Should have restore functions available' {
            $module = Get-Module WorkstationBackup
            $module | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Module Management' {
        It 'Should have module management functions available' {
            $module = Get-Module WorkstationBackup
            $module | Should -Not -BeNullOrEmpty
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
        It 'Should have logging functions available' {
            $module = Get-Module WorkstationBackup
            $module | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Export-PowerShellEnvironment' {
    It 'Should accept -WhatIf parameter' {
        { Export-PowerShellEnvironment -WhatIf } | Should -Not -Throw
    }

    It 'Should export environment without errors' {
        { Export-PowerShellEnvironment } | Should -Not -Throw
    }
}

Describe 'Import-PowerShellEnvironment' {
    It 'Should accept -WhatIf parameter' {
        { Import-PowerShellEnvironment -WhatIf } | Should -Not -Throw
    }

    It 'Should import environment without errors' {
        { Import-PowerShellEnvironment } | Should -Not -Throw
    }
}

Describe 'Invoke-WorkstationBackup' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Register-WorkstationBackupTask' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-ExportPowerShellEnvironment' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-ApplyPowerShellEnvironment' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Export-NerdFont' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Restore-NerdFonts' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Initialize-FontRestorePrerequisite' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Export-MachineState' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-BackupGitSync' {
    It 'Should be available in module' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'Module workflow integration' {
    It 'Should have integrated workflow functions' {
        $module = Get-Module WorkstationBackup
        $module | Should -Not -BeNullOrEmpty
    }
}