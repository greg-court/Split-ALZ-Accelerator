function Split-Accelerator {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    Write-Verbose "Split-Accelerator starting at $(Get-Date -Format o)"

    if ($PSCmdlet.ShouldProcess($Path, "Split ALZ into platform_*; refactor modules; clean configs")) {

        $move      = Invoke-AccelMoveFiles        -Path $Path -Force:$Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
        $refactor  = Invoke-AccelRefactorModules  -Path $Path -Force:$Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
        $cleanConn = Invoke-AccelCleanConnectivity -Path $Path -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
        $cleanMgmt = Invoke-AccelCleanManagement   -Path $Path -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
        $simplOK   = Simplify-AccelStarterLocations -Path $Path -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference

        # plain, minimal summary (no fancy objects)
        Write-Host ("Move: Moved={0} Copied={1} Deleted={2} Skipped={3}" -f $move.Moved,$move.Copied,$move.Deleted,$move.Skipped)
        Write-Host ("Refactor: RenamedModules={0} CustomModules={1} Rewritten={2} Symlinks={3} Skipped={4}" -f $refactor.ModulesRenamed,$refactor.CustomModulesReady,$refactor.FilesRewritten,$refactor.SymlinksCreated,$refactor.Skipped)
        Write-Host ("CleanConnectivity: FilesChanged={0}" -f $cleanConn)
        Write-Host ("CleanManagement:  FilesChanged={0}" -f $cleanMgmt)
        Write-Host ("StarterLocationsSimplified: {0}" -f $simplOK)

        # no complex return object
        return
    }
}
