@{
    RootModule        = 'Split-Accelerator.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b08e7c61-3c5a-46ce-8a7a-1d7f1f3d9b9f'
    Author            = 'You'
    CompanyName       = 'You'
    Copyright         = '(c) You. MIT License.'
    Description       = 'Splits an ALZ accelerator deployment into platform_* units. Phase 1: Move files.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Split-Accelerator','Invoke-AccelMoveFiles')
    PrivateData = @{
        PSData = @{
            Tags        = @('ALZ','Terraform','Split','Accelerator')
            ProjectUri  = 'https://example.invalid/split-accelerator'
            LicenseUri  = 'https://opensource.org/licenses/MIT'
        }
    }
}
