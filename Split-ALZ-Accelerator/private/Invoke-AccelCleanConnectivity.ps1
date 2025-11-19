function Invoke-AccelCleanConnectivity {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    $root = Resolve-AccelPath -Path $Path
    $pc   = Join-Path $root 'platform_connectivity'
    if (-not (Test-Path -LiteralPath $pc -PathType Container)) { return 0 }

    # 1) Line-based cleanup for .tf and simple references
    $patterns = @(
        'var\.management_',
        '\bmodule\.management_resources\b',
        'management_groups_enabled',
        'management_resources_enabled'
    )

    Remove-AccelLines -Directory $pc -RegexPatterns $patterns -Confirm:$false
}