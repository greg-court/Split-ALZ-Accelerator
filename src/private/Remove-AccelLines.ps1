function Remove-AccelLines {
    <#
      .SYNOPSIS
      Remove entire lines from all *.tf files under a directory if they match any given regex patterns.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string[]]$RegexPatterns
    )

    $dirPath = Resolve-AccelPath -Path $Directory
    if (-not (Test-Path -LiteralPath $dirPath -PathType Container)) { return 0 }

    $files = Get-ChildItem -Path $dirPath -Recurse -Filter '*.tf' -File -ErrorAction SilentlyContinue
    if (-not $files) { return 0 }

    # combine to single case-insensitive regex
    $rx = [regex]::new('(' + ($RegexPatterns -join '|') + ')', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    $changedCount = 0
    foreach ($f in $files) {
        try {
            $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
            $eol = ($raw -match "`r`n") ? "`r`n" : "`n"
            $lines = $raw -split "`r?`n"

            $modified = $false
            $kept = foreach ($ln in $lines) {
                if ($rx.IsMatch($ln)) { $modified = $true; continue }
                $ln
            }

            if ($modified) {
                $new = [string]::Join($eol, $kept)
                if ($PSCmdlet.ShouldProcess($f.FullName, "Remove lines matching patterns")) {
                    Set-Content -LiteralPath $f.FullName -Value $new -Encoding UTF8 -ErrorAction Stop
                    $changedCount++
                }
            }
        }
        catch {
            Write-Warning "Line cleanup failed for '$($f.FullName)': $($_.Exception.Message)"
            continue
        }
    }
    return $changedCount
}
