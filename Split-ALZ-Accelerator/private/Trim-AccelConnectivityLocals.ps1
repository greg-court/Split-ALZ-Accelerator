function Trim-AccelConnectivityLocals {
    <#
      .SYNOPSIS
      In platform_connectivity/locals.tf, remove assignments like
      'management_group_settings = merge(...)' and
      'management_resource_settings = merge(...)' (entire assignment, robust to formatting).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $root = Resolve-AccelPath -Path $Path
    $file = Join-Path (Join-Path $root 'platform_connectivity') 'locals.tf'
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return 0 }

    try {
        $text = Get-Content -LiteralPath $file -Raw -ErrorAction Stop

        # targets we want to remove if they appear as "<name> = merge("
        $targets = @('management_group_settings','management_resource_settings')
        $removed = 0

        foreach ($name in $targets) {
            # regex to find start of "<name> = merge("
            $pat = [System.Text.RegularExpressions.Regex]::new(
                [Regex]::Escape($name) + '\s*=\s*merge\s*\(',
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
            $matches = $pat.Matches($text)
            if ($matches.Count -eq 0) { continue }

            # remove from end to start so indices don’t shift
            for ($mi = $matches.Count - 1; $mi -ge 0; $mi--) {
                $m = $matches[$mi]
                $startIdx = $m.Index

                # find the matching closing ')' for this merge(
                $parenStart = $text.IndexOf('(', $m.Index)
                if ($parenStart -lt 0) { continue }

                $i = $parenStart + 1
                $depth = 1
                while ($i -lt $text.Length -and $depth -gt 0) {
                    $ch = $text[$i]
                    if ($ch -eq '(') { $depth++ }
                    elseif ($ch -eq ')') { $depth-- }
                    $i++
                }
                if ($depth -ne 0) { continue } # unbalanced, skip safely

                $endIdx = $i # just after the closing ')'

                # swallow any trailing commas/whitespace/newlines after the merge(...)
                while ($endIdx -lt $text.Length) {
                    $c = [char]$text[$endIdx]
                    if ($c -eq ',' -or $c -eq ' ' -or $c -eq "`t" -or $c -eq "`r" -or $c -eq "`n") { $endIdx++ }
                    else { break }
                }

                # expand start to beginning of its line
                $lineStart = $startIdx
                while ($lineStart -gt 0) {
                    $prev = [char]$text[$lineStart - 1]
                    if ($prev -eq "`n" -or $prev -eq "`r") { break }
                    $lineStart--
                }

                # remove the slice
                $text = $text.Remove($lineStart, $endIdx - $lineStart)
                $removed++
            }
        }

        if ($removed -gt 0) {
            if ($PSCmdlet.ShouldProcess($file, "Trim $removed merge assignment(s) in locals.tf")) {
                Set-Content -LiteralPath $file -Value $text -Encoding UTF8 -ErrorAction Stop
            }
        }

        return $removed
    }
    catch {
        Write-Warning "Trimming connectivity locals failed for '$file': $($_.Exception.Message)"
        return 0
    }
}
