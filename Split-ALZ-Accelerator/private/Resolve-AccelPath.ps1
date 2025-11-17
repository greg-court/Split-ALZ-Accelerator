function Resolve-AccelPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw "Path '$Path' exists but is not a directory."
    }
    return $resolved.ProviderPath
}
