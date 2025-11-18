function Split-AccelLandingZoneAutoTfvars {
    <#
      .SYNOPSIS
      Split platform-landing-zone.auto.tfvars into:
        - root/platform.shared.auto.tfvars              (custom_replacements + enable_telemetry)
        - platform_management/management.auto.tfvars    (tags + management_* settings)
        - platform_connectivity/connectivity.auto.tfvars (tags + connectivity_* settings)
      then delete platform-landing-zone.auto.tfvars.

      .NOTES
      - Ignores all comments outside the extracted assignments.
      - Inline comments inside the {...} blocks are preserved.
      - Idempotent: if all target files already exist, it does nothing (unless -Force).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    $root = Resolve-AccelPath -Path $Path

    $tfvarsRoot = Join-Path $root 'platform-landing-zone.auto.tfvars'
    if (-not (Test-Path -LiteralPath $tfvarsRoot -PathType Leaf)) {
        Write-Verbose "No platform-landing-zone.auto.tfvars found at $tfvarsRoot; skipping split."
        return
    }

    $pmDir = Join-Path $root 'platform_management'
    $pcDir = Join-Path $root 'platform_connectivity'

    $mgmtFile   = Join-Path $pmDir   'management.auto.tfvars'
    $connFile   = Join-Path $pcDir   'connectivity.auto.tfvars'
    $sharedFile = Join-Path $root    'platform.shared.auto.tfvars'

    # If we've already split and not forcing, bail out
    if ((Test-Path -LiteralPath $mgmtFile) -and
        (Test-Path -LiteralPath $connFile) -and
        (Test-Path -LiteralPath $sharedFile) -and
        -not $Force) {
        Write-Verbose "management/ connectivity / shared .auto.tfvars already exist; skipping tfvars split."
        return
    }

    if (-not (Test-Path -LiteralPath $pmDir -PathType Container) -or
        -not (Test-Path -LiteralPath $pcDir -PathType Container)) {
        Write-Verbose "platform_* directories not found; skipping tfvars split."
        return
    }

    $text = Get-Content -LiteralPath $tfvarsRoot -Raw -ErrorAction Stop
    $nl = ($text -match "`r`n") ? "`r`n" : "`n"

    #
    # Helper: get "name = { ... }" block (brace-balanced), ignoring outer comments
    #
    function Get-TfvarsBlock {
        param(
            [string]$Name,
            [string]$Text
        )

        # match at start-of-line:   name = ...
        $pattern = '^\s*' + [regex]::Escape($Name) + '\s*='
        $m = [regex]::Match(
            $Text,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
        if (-not $m.Success) { return $null }

        $startIdx = $m.Index

        # find first '{' after the '='
        $eqIdx   = $Text.IndexOf('=', $startIdx)
        if ($eqIdx -lt 0) { return $null }
        $openIdx = $Text.IndexOf('{', $eqIdx)
        if ($openIdx -lt 0) { return $null }

        $depth = 0
        $closeIdx = -1
        for ($i = $openIdx; $i -lt $Text.Length; $i++) {
            $ch = $Text[$i]
            if ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') {
                $depth--
                if ($depth -eq 0) {
                    $closeIdx = $i
                    break
                }
            }
        }
        if ($closeIdx -lt 0) { return $null }

        # grab exactly: "name = { ... }"
        $seg = $Text.Substring($startIdx, $closeIdx - $startIdx + 1)
        return $seg.TrimEnd()
    }

    #
    # Helper: get a simple "name = something" single line, ignoring outer comments
    #
    function Get-TfvarsLine {
        param(
            [string]$Name,
            [string]$Text
        )

        $pattern = '^\s*' + [regex]::Escape($Name) + '\s*=.*$'
        $m = [regex]::Match(
            $Text,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
        if (-not $m.Success) { return $null }

        return $m.Value.TrimEnd()
    }

    # Extract the pieces we care about from the original file
    $tagsBlock            = Get-TfvarsBlock -Name 'tags'                        -Text $text
    $mgmtResBlock         = Get-TfvarsBlock -Name 'management_resource_settings' -Text $text
    $mgmtGroupBlock       = Get-TfvarsBlock -Name 'management_group_settings'    -Text $text
    $connRgsBlock         = Get-TfvarsBlock -Name 'connectivity_resource_groups' -Text $text
    $virtualHubsBlock     = Get-TfvarsBlock -Name 'virtual_hubs'                 -Text $text

    $connTypeLine         = Get-TfvarsLine  -Name 'connectivity_type'            -Text $text
    $customReplBlock      = Get-TfvarsBlock -Name 'custom_replacements'          -Text $text
    $enableTelemetryLine  = Get-TfvarsLine  -Name 'enable_telemetry'             -Text $text

    #
    # Build management.auto.tfvars
    #
    $mgmtParts = @()
    if ($tagsBlock)      { $mgmtParts += $tagsBlock }
    if ($mgmtResBlock)   { $mgmtParts += $mgmtResBlock }
    if ($mgmtGroupBlock) { $mgmtParts += $mgmtGroupBlock }

    $mgmtContent = if ($mgmtParts.Count -gt 0) {
        [string]::Join($nl + $nl, $mgmtParts) + $nl
    } else {
        ''
    }

    #
    # Build connectivity.auto.tfvars
    #
    $connParts = @()
    if ($tagsBlock)        { $connParts += $tagsBlock }
    if ($connTypeLine)     { $connParts += $connTypeLine }
    if ($connRgsBlock)     { $connParts += $connRgsBlock }
    if ($virtualHubsBlock) { $connParts += $virtualHubsBlock }

    $connContent = if ($connParts.Count -gt 0) {
        [string]::Join($nl + $nl, $connParts) + $nl
    } else {
        ''
    }

    #
    # Build platform.shared.auto.tfvars (shared bits only)
    #
    $sharedParts = @()
    if ($customReplBlock)     { $sharedParts += $customReplBlock }
    if ($enableTelemetryLine) { $sharedParts += $enableTelemetryLine }

    $sharedContent = if ($sharedParts.Count -gt 0) {
        [string]::Join($nl + $nl, $sharedParts) + $nl
    } else {
        ''
    }

    #
    # Write files (new content only – comments outside the blocks are intentionally dropped)
    #
    if ($PSCmdlet.ShouldProcess($mgmtFile, "Write management.auto.tfvars")) {
        New-AccelDirectory -Path $pmDir -Confirm:$false | Out-Null
        Set-Content -LiteralPath $mgmtFile -Value $mgmtContent -Encoding UTF8 -ErrorAction Stop
    }

    if ($PSCmdlet.ShouldProcess($connFile, "Write connectivity.auto.tfvars")) {
        New-AccelDirectory -Path $pcDir -Confirm:$false | Out-Null
        Set-Content -LiteralPath $connFile -Value $connContent -Encoding UTF8 -ErrorAction Stop
    }

    if ($PSCmdlet.ShouldProcess($sharedFile, "Write platform.shared.auto.tfvars")) {
        Set-Content -LiteralPath $sharedFile -Value $sharedContent -Encoding UTF8 -ErrorAction Stop
    }

    #
    # Finally, delete the original source file completely
    #
    if ($PSCmdlet.ShouldProcess($tfvarsRoot, 'Delete original platform-landing-zone.auto.tfvars')) {
        Remove-Item -LiteralPath $tfvarsRoot -Force -ErrorAction Stop
    }
}