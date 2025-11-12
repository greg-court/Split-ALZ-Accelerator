function Update-AccelProviderInFile {
    <#
      .SYNOPSIS
      Ensure provider "azurerm" block contains the desired subscription_id assignment.
      If a subscription_id line exists, it is replaced; otherwise it's inserted after
      resource_provider_registrations (or at top of block if not found).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$SubscriptionKey  # e.g. 'connectivity' or 'management'
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) { return $false }

    $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction Stop
    $nl = ($content -match "`r`n") ? "`r`n" : "`n"

    # find start of provider "azurerm" {
    $m = [regex]::Match($content, 'provider\s+"azurerm"\s*\{', 'IgnoreCase')
    if (-not $m.Success) { return $false }

    # find the opening brace and match to its closing brace using simple brace counting
    $openIdx = $content.IndexOf('{', $m.Index)
    if ($openIdx -lt 0) { return $false }
    $i = $openIdx
    $depth = 0
    do {
        $ch = $content[$i]
        if ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') { $depth-- }
        $i++
    } while ($i -lt $content.Length -and $depth -gt 0)
    if ($depth -ne 0) { Write-Warning "Unbalanced braces in $FilePath provider block"; return $false }

    $blockStart = $m.Index
    $blockEnd   = $i - 1
    $block      = $content.Substring($blockStart, $blockEnd - $blockStart + 1)

    # derive an indent from an existing property line, fall back to two spaces
    $indentMatch = [regex]::Match($block, "^\s+[A-Za-z_]+\s*=", 'Multiline')
    $indent = if ($indentMatch.Success) {
        ([regex]::Match($indentMatch.Value, '^\s+')).Value
    } else { '  ' }

    $desiredLine = $indent + 'subscription_id = var.subscription_ids["' + $SubscriptionKey + '"]'

    $blockNew = $block

    # replace existing subscription_id line if present
    $rxSubLine = [regex]::new('^\s*subscription_id\s*=\s*.*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($rxSubLine.IsMatch($blockNew)) {
        $blockNew = $rxSubLine.Replace($blockNew, [System.Text.RegularExpressions.MatchEvaluator]{ param($mm) $desiredLine })
    } else {
        # insert after resource_provider_registrations line if present
        $rxRpr = [regex]::new('^(\s*resource_provider_registrations\s*=\s*".*")\s*$', 'Multiline')
        if ($rxRpr.IsMatch($blockNew)) {
            $blockNew = $rxRpr.Replace($blockNew, { param($mm) $mm.Groups[1].Value + $nl + $desiredLine }, 1)
        } else {
            # otherwise, insert just after opening brace
            $insPos = $blockNew.IndexOf('{') + 1
            $blockNew = $blockNew.Substring(0,$insPos) + $nl + $desiredLine + $blockNew.Substring($insPos)
        }
    }

    if ($blockNew -ne $block) {
        $newContent = $content.Substring(0,$blockStart) + $blockNew + $content.Substring($blockEnd+1)
        if ($PSCmdlet.ShouldProcess($FilePath, "Set provider azurerm subscription_id = var.subscription_ids[`"$SubscriptionKey`"]")) {
            Set-Content -LiteralPath $FilePath -Value $newContent -Encoding UTF8 -ErrorAction Stop
            return $true
        }
    }

    return $false
}

function Invoke-AccelFixProviders {
    <#
      .SYNOPSIS
      Apply provider "azurerm" subscription_id fix to both platform_* terraform.tf files.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    $root = Resolve-AccelPath -Path $Path

    $pcFile = Join-Path (Join-Path $root 'platform_connectivity') 'terraform.tf'
    $pmFile = Join-Path (Join-Path $root 'platform_management')  'terraform.tf'

    $c = $false
    $m = $false

    try { $c = Update-AccelProviderInFile -FilePath $pcFile -SubscriptionKey 'connectivity' -Confirm:$false } catch { Write-Warning "Fix provider (connectivity) failed: $($_.Exception.Message)" }
    try { $m = Update-AccelProviderInFile -FilePath $pmFile -SubscriptionKey 'management'  -Confirm:$false } catch { Write-Warning "Fix provider (management) failed: $($_.Exception.Message)" }

    # return simple tuple-like object
    [pscustomobject]@{ ConnectivityUpdated = $c; ManagementUpdated = $m }
}
