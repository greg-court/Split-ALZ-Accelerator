function Split-Accelerator {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    Write-Verbose "Split-Accelerator starting at $(Get-Date -Format o)"

    if ($PSCmdlet.ShouldProcess($Path, "Split ALZ into platform_* and refactor modules")) {

        $moveSummary     = Invoke-AccelMoveFiles        -Path $Path -Force:$Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
        $refactorSummary = Invoke-AccelRefactorModules  -Path $Path -Force:$Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference

        return [pscustomobject]@{
            Move     = $moveSummary
            Refactor = $refactorSummary
        }
    }
}
