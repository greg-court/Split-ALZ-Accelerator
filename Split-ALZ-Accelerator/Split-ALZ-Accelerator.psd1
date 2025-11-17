@{
  RootModule        = 'Split-Accelerator.psm1'
  ModuleVersion     = '0.2.0'
  GUID              = 'b08e7c61-3c5a-46ce-8a7a-1d7f1f3d9b9f'
  Author            = 'You'
  CompanyName       = 'You'
  Description       = 'Split an ALZ deployment into platform_* and refactor modules.'
  PowerShellVersion = '7.0'
  FunctionsToExport = @('Split-Accelerator')
  PrivateData = @{
    PSData = @{
      Tags       = @('ALZ','Terraform','Split','Accelerator')
      LicenseUri = 'https://opensource.org/licenses/MIT'
    }
  }
}
