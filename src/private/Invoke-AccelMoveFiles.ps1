function Invoke-AccelMoveFiles {
    <#
    .SYNOPSIS
    Phase 1: create platform_* dirs and move/copy/delete files per your plan.
    .EXAMPLE
    Invoke-AccelMoveFiles -Path '/Users/gregc/.../alz-mgmt' -WhatIf -Verbose
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    $root = Resolve-AccelPath -Path $Path
    $pc   = Join-Path $root 'platform_connectivity'
    $pm   = Join-Path $root 'platform_management'

    New-AccelDirectory -Path $pc | Out-Null
    New-AccelDirectory -Path $pm | Out-Null

    # build the operation list (order matters) — use HASHTABLES for splatting
    $ops = @()

    # Moves
    $ops += @{ Action='Move'; Source=(Join-Path $root 'lib'); Destination=(Join-Path $pm 'lib') }
    $ops += @{ Action='Move'; Source=(Join-Path $root 'main.connectivity.hub.and.spoke.virtual.network.tf'); Destination=(Join-Path $pc 'main.connectivity.hub.and.spoke.virtual.network.tf') }
    $ops += @{ Action='Move'; Source=(Join-Path $root 'main.connectivity.virtual.wan.tf'); Destination=(Join-Path $pc 'main.connectivity.virtual.wan.tf') }
    $ops += @{ Action='Move'; Source=(Join-Path $root 'main.management.tf'); Destination=(Join-Path $pm 'main.management.tf') }
    $ops += @{ Action='Move'; Source=(Join-Path $root 'main.resource.groups.tf'); Destination=(Join-Path $pc 'main.resource.groups.tf') }

    # Move with glob for variables.connectivity*
    Get-ChildItem -Path (Join-Path $root 'variables.connectivity*') -File -ErrorAction SilentlyContinue | ForEach-Object {
        $ops += @{ Action='Move'; Source=$_.FullName; Destination=(Join-Path $pc $_.Name) }
    }
    # variables.management.tf
    $ops += @{ Action='Move'; Source=(Join-Path $root 'variables.management.tf'); Destination=(Join-Path $pm 'variables.management.tf') }

    # Copies
    $ops += @{ Action='Copy'; Source=(Join-Path $root 'terraform.tfvars.json'); Destination=(Join-Path $pc 'terraform.tfvars.json') }
    $ops += @{ Action='Copy'; Source=(Join-Path $root 'terraform.tfvars.json'); Destination=(Join-Path $pm 'terraform.tfvars.json') }
    $ops += @{ Action='Copy'; Source=(Join-Path $root 'terraform.tf'); Destination=(Join-Path $pc 'terraform.tf') }
    $ops += @{ Action='Copy'; Source=(Join-Path $root 'terraform.tf'); Destination=(Join-Path $pm 'terraform.tf') }

    # Deletes (after copies)
    $ops += @{ Action='Delete';   Source=(Join-Path $root 'terraform.tfvars.json') }
    $ops += @{ Action='Delete';   Source=(Join-Path $root 'terraform.tf') }
    $ops += @{ Action='DeleteDir';Source=(Join-Path $root 'scripts') }

    $summary = [ordered]@{Moved=0; Copied=0; Deleted=0; Skipped=0}

    foreach ($op in $ops) {
        try {
            $result = Invoke-AccelOperation @op -Force:$Force
        }
        catch {
            Write-Warning ("Failed {0} '{1}' -> '{2}': {3}" -f $op.Action,$op.Source,$op.Destination,$_.Exception.Message)
            $result = 'Skipped'
        }

        switch ($result) {
            'Moved'   { $summary.Moved++ }
            'Copied'  { $summary.Copied++ }
            'Deleted' { $summary.Deleted++ }
            default   { $summary.Skipped++ }
        }
    }

    if ($WhatIfPreference) {
        $planned = [ordered]@{
            MovedPlanned   = ($ops | Where-Object { $_.Action -eq 'Move' }).Count
            CopiedPlanned  = ($ops | Where-Object { $_.Action -eq 'Copy' }).Count
            DeletedPlanned = ($ops | Where-Object { $_.Action -in @('Delete','DeleteDir') }).Count
            TotalPlanned   = $ops.Count
        }
        return [pscustomobject]$planned
    }

    # otherwise, return executed summary
    [pscustomobject]$summary
}
