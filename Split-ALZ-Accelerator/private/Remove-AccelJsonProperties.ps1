function Remove-AccelJsonProperties {
    <#
      .SYNOPSIS
      Remove top-level JSON properties from all *.tfvars.json files under a directory.

      .DESCRIPTION
      This is JSON-aware: it loads the file with ConvertFrom-Json, removes the
      specified properties from the top-level object, then writes it back with
      ConvertTo-Json. Works regardless of whether the values are null, scalars,
      or multi-line objects/arrays.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string[]]$PropertyNames
    )

    $dirPath = Resolve-AccelPath -Path $Directory
    if (-not (Test-Path -LiteralPath $dirPath -PathType Container)) { return 0 }

    $files = Get-ChildItem -Path $dirPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '*.tfvars.json' }

    if (-not $files) { return 0 }

    $changed = 0

    foreach ($f in $files) {
        try {
            $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
            if (-not $raw.Trim()) { continue }

            # Try parse JSON
            try {
                $json = $raw | ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-Warning "Skipping invalid JSON in '$($f.FullName)': $($_.Exception.Message)"
                continue
            }

            # We only handle top-level objects
            if (-not ($json -is [psobject])) { continue }

            $removedAny = $false
            foreach ($name in $PropertyNames) {
                $prop = $json.PSObject.Properties[$name]
                if ($prop) {
                    $json.PSObject.Properties.Remove($name)
                    $removedAny = $true
                }
            }

            if (-not $removedAny) { continue }

            # Re-serialize; depth 10 should be plenty for tfvars
            $newJson = $json | ConvertTo-Json -Depth 10

            if ($PSCmdlet.ShouldProcess($f.FullName, "Remove JSON properties: $($PropertyNames -join ', ')")) {
                Set-Content -LiteralPath $f.FullName -Value $newJson -Encoding UTF8 -ErrorAction Stop
                $changed++
            }
        }
        catch {
            Write-Warning "JSON property cleanup failed for '$($f.FullName)': $($_.Exception.Message)"
            continue
        }
    }

    return $changed
}
