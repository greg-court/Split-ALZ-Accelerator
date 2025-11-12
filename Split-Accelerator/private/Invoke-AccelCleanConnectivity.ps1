function Invoke-AccelCleanConnectivity {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    $root = Resolve-AccelPath -Path $Path
    $pc   = Join-Path $root 'platform_connectivity'
    if (-not (Test-Path -LiteralPath $pc -PathType Container)) { return 0 }

    $patterns = @(
        'var\.management_',
        '\bmodule\.management_resources\b'
    )
    Remove-AccelLines -Directory $pc -RegexPatterns $patterns -Confirm:$false
}
