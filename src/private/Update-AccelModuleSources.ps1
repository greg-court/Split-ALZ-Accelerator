function Update-AccelModuleSources {
    <#
      .SYNOPSIS
      Rewrite Terraform module sources from ./modules or ../modules to the correct
      relative path to accelerator-modules, without stray quotes or escapes.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$ModulesNewName = 'accelerator-modules'
    )

    $rootPath   = Resolve-AccelPath -Path $Root
    $modulesNew = Join-Path $rootPath $ModulesNewName

    # all .tf files except under accelerator-modules or custom-modules
    $tfFiles = Get-ChildItem -Path $rootPath -Recurse -Filter '*.tf' -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notlike (Join-Path $modulesNew '*') -and
            $_.FullName -notlike (Join-Path $rootPath 'custom-modules*')
        }

    $changed = 0
    foreach ($file in $tfFiles) {
        try {
            $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop

            # compute correct relative path to accelerator-modules from this file's folder
            $rel = [System.IO.Path]::GetRelativePath($file.Directory.FullName, $modulesNew).Replace('\','/')
            if (-not $rel.EndsWith('/')) { $rel = "$rel/" }

            $newContent = $content

            # 1) Replace ONLY the prefix inside the quotes; keep the trailing module name
            #    e.g. source = "./modules/config-templating" -> source = "../accelerator-modules/config-templating"
            $patternPrefix = '(?<=\bsource\s*=\s*")\s*(?:\./|\.\./)modules/?'
            $newContent = [regex]::Replace($newContent, $patternPrefix, $rel)

            # 2) Fix any previously broken double-quote splits, e.g.
            #    source = "../accelerator-modules/"config-templating"
            $relEsc = [regex]::Escape($rel)
            $patternFixQuotes = '(?<=\bsource\s*=\s*")(' + $relEsc + ')"\s*([^"]+)"'
            $newContent = [regex]::Replace($newContent, $patternFixQuotes, '$1$2"')

            # 3) Clean up accidental backslash-escaped segments from earlier runs, e.g. \.\./accelerator-modules/
            $newContent = $newContent -replace '(?<=\bsource\s*=\s*")\\\.\./','../'
            # Remove stray backslashes just before our prefix or ../ (conservative lookahead)
            $newContent = $newContent -replace '(?<=\bsource\s*=\s*")\\(?=(\.\./|[A-Za-z0-9_\-]+/))',''

            if ($newContent -ne $content) {
                if ($PSCmdlet.ShouldProcess($file.FullName, "Rewrite module sources → $rel")) {
                    Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding UTF8 -ErrorAction Stop
                    $changed++
                }
            }
        }
        catch {
            Write-Warning "Module source rewrite failed for '$($file.FullName)': $($_.Exception.Message)"
            continue
        }
    }

    return $changed
}
