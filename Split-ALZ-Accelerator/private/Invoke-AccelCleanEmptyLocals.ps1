function Invoke-AccelCleanEmptyLocals {
    <#
      .SYNOPSIS
      Removes empty Terraform locals blocks (`locals {}`) from platform_* directories.
      Works even if block spans multiple lines or has only whitespace inside.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $root = Resolve-AccelPath -Path $Path
    $targets = @('platform_connectivity','platform_management') | ForEach-Object { Join-Path $root $_ }

    $rxEmptyLocals = [regex]::new(
        'locals\s*\{\s*\}',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    $rxMultiline = [regex]::new(
        'locals\s*\{(?:\s|\r|\n)*\}',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    $changed = 0

    foreach ($dir in $targets) {
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { continue }

        $files = Get-ChildItem -Path $dir -Recurse -Filter '*.tf' -File -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            try {
                $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
                $newContent = $content

                # Replace both compact and multiline empty locals
                $newContent = $rxEmptyLocals.Replace($newContent, '')
                $newContent = $rxMultiline.Replace($newContent, '')

                if ($newContent -ne $content) {
                    if ($PSCmdlet.ShouldProcess($f.FullName, 'Remove empty locals blocks')) {
                        Set-Content -LiteralPath $f.FullName -Value $newContent -Encoding UTF8 -ErrorAction Stop
                        $changed++
                    }
                }
            } catch {
                Write-Warning "Failed to clean empty locals in '$($f.FullName)': $($_.Exception.Message)"
            }
        }
    }

    return $changed
}