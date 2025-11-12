function Split-Accelerator {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    Write-Verbose "Split-Accelerator starting at $(Get-Date -Format o)"

    if ($PSCmdlet.ShouldProcess($Path, "Split ALZ into platform_* (move/copy/delete)")) {
        # suppress inner confirmations; WhatIf/Verbose still flow through
        $moveSummary = Invoke-AccelMoveFiles -Path $Path -Force:$Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
        Write-Verbose "Move phase summary: $(($moveSummary | ConvertTo-Json -Compress))"
        return $moveSummary
    }
}
