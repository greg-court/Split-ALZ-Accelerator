function Invoke-AccelRefactorModules {
    <#
    .SYNOPSIS
    Phase 2: rename 'modules' → 'accelerator-modules', create 'custom-modules',
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
    $newModules = Join-Path $root 'accelerator-modules'
    $customMods = Join-Path $root 'custom-modules'

    $summary = [ordered]@{
        ModulesRenamed     = $false
        CustomModulesReady = $false
        FilesRewritten     = 0
        SymlinksCreated    = 0
        Skipped            = 0
    }

    # 1) rename modules -> accelerator-modules (idempotent)
    try {
        $res = Invoke-AccelOperation -Action Move -Source $oldModules -Destination $newModules -Force:$Force -Confirm:$false
        if ($res -eq 'Moved' -or (Test-Path $newModules)) { $summary.ModulesRenamed = $true } else { $summary.Skipped++ }
    } catch { Write-Warning "Rename modules failed: $($_.Exception.Message)"; $summary.Skipped++ }

    # 2) ensure custom-modules/
    try {
        New-AccelDirectory -Path $customMods -Confirm:$false | Out-Null
        $summary.CustomModulesReady = $true
    } catch { Write-Warning "Create custom-modules failed: $($_.Exception.Message)"; $summary.Skipped++ }

    # 3) rewrite module sources in all .tf files
    try {
        $rewritten = Update-AccelModuleSources -Root $root -Confirm:$false
        $summary.FilesRewritten = $rewritten
    } catch { Write-Warning "Update module sources failed: $($_.Exception.Message)"; $summary.Skipped++ }

    # 4) symlinks for platform-landing-zone.auto.tfvars into both platform_* dirs
    $autoTfvarsName = 'platform-landing-zone.auto.tfvars'
    $platformDirs = @('platform_connectivity','platform_management') | ForEach-Object { Join-Path $root $_ }
    foreach ($pd in $platformDirs) {
        try {
            if (-not (Test-Path -LiteralPath $pd -PathType Container)) { Write-Verbose "Skip symlink, missing dir: $pd"; $summary.Skipped++; continue }
            $link   = Join-Path $pd $autoTfvarsName
            $target = (Join-Path '..' $autoTfvarsName)  # relative target from inside platform_* to root
            New-AccelSymlink -LinkPath $link -TargetPath $target -Force:$Force -Confirm:$false | Out-Null
            $summary.SymlinksCreated++
        } catch {
            Write-Warning "Symlink create failed for '$pd': $($_.Exception.Message)"
            $summary.Skipped++
        }
    }

    [pscustomobject]$summary
}
