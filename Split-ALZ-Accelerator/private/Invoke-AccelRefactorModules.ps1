function Invoke-AccelRefactorModules {
    <#
    .SYNOPSIS
    Phase 2: rename 'modules' → '_modules-accelerator', create '_modules-custom',
             rewrite module sources in .tf, and add .auto.tfvars symlinks.
    .EXAMPLE
    Invoke-AccelRefactorModules -Path '../alz-mgmt' -WhatIf -Verbose
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    $root = Resolve-AccelPath -Path $Path
    if (-not $PSCmdlet.ShouldProcess($root, "Refactor modules & add symlinks")) { return }

    $oldModules = Join-Path $root 'modules'
    $newModules = Join-Path $root '_modules-accelerator'
    $customMods = Join-Path $root '_modules-custom'

    $summary = [ordered]@{
        ModulesRenamed     = $false
        CustomModulesReady = $false
        FilesRewritten     = 0
        SymlinksCreated    = 0
        Skipped            = 0
    }

    try {
        $res = Invoke-AccelOperation -Action Move -Source $oldModules -Destination $newModules -Force:$Force -Confirm:$false
        if ($res -eq 'Moved' -or (Test-Path $newModules)) { $summary.ModulesRenamed = $true } else { $summary.Skipped++ }
    } catch { Write-Warning "Rename modules failed: $($_.Exception.Message)"; $summary.Skipped++ }

    try {
        New-AccelDirectory -Path $customMods -Confirm:$false | Out-Null
        $summary.CustomModulesReady = $true
    } catch { Write-Warning "Create _modules-custom failed: $($_.Exception.Message)"; $summary.Skipped++ }

    try {
        $rewritten = Update-AccelModuleSources -Root $root -Confirm:$false
        $summary.FilesRewritten = $rewritten
    } catch { Write-Warning "Update module sources failed: $($_.Exception.Message)"; $summary.Skipped++ }

    try {
        Split-AccelLandingZoneAutoTfvars -Path $root -Force:$Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
    } catch {
        Write-Warning "Split platform-landing-zone.auto.tfvars failed: $($_.Exception.Message)"
        $summary.Skipped++
    }

    $sharedTfvarsName = 'platform.shared.auto.tfvars'
    $platformDirs = @('platform_connectivity','platform_management') | ForEach-Object { Join-Path $root $_ }
    foreach ($pd in $platformDirs) {
        try {
            if (-not (Test-Path -LiteralPath $pd -PathType Container)) {
                Write-Verbose "Skip symlink, missing dir: $pd"
                $summary.Skipped++
                continue
            }
            $link   = Join-Path $pd $sharedTfvarsName
            $target = (Join-Path '..' $sharedTfvarsName)  # relative target from inside platform_* to root
            New-AccelSymlink -LinkPath $link -TargetPath $target -Force:$Force -Confirm:$false | Out-Null
            $summary.SymlinksCreated++
        }
        catch {
            Write-Warning "Symlink create failed for '$pd': $($_.Exception.Message)"
            $summary.Skipped++
        }
    }

    [pscustomobject]$summary
}
