function Simplify-AccelStarterLocations {
    <#
      .SYNOPSIS
      Replace the entire variable "starter_locations" block in platform_management/variables.tf
      with the simplified version (removing the connectivity-related validation).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    $root = Resolve-AccelPath -Path $Path
    $file = Join-Path (Join-Path $root 'platform_management') 'variables.tf'
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $false }

    try {
        $content = Get-Content -LiteralPath $file -Raw -ErrorAction Stop
        $match   = [regex]::Match($content, 'variable\s+"starter_locations"\s*\{', 'IgnoreCase')
        if (-not $match.Success) { return $false }

        $i = $match.Index + $match.Length
        $depth = 1
        while ($i -lt $content.Length) {
            $ch = $content[$i]
            if ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') {
                $depth--
                if ($depth -eq 0) { break }
            }
            $i++
        }
        if ($depth -ne 0) {
            Write-Warning "Could not parse balanced braces for starter_locations in $file"
            return $false
        }

        $before = $content.Substring(0, $match.Index)
        $after  = $content.Substring($i + 1)

        $nl = ($content -match "`r`n") ? "`r`n" : "`n"
        $replacement = @"
variable "starter_locations" {
  type        = list(string)
  description = "The default for Azure resources. (e.g 'uksouth')"
  validation {
    condition     = length(var.starter_locations) > 0
    error_message = "You must provide at least one starter location region."
  }
}
"@ -replace "`r?`n", $nl

        if ($PSCmdlet.ShouldProcess($file, 'Replace starter_locations validation block')) {
            Set-Content -LiteralPath $file -Value ($before + $replacement + $after) -Encoding UTF8 -ErrorAction Stop
            return $true
        }
    }
    catch {
        Write-Warning "Simplify starter_locations failed for '$file': $($_.Exception.Message)"
    }
    return $false
}
