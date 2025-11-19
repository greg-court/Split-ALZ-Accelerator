function Invoke-AccelCleanManagement {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    $root = Resolve-AccelPath -Path $Path
    $pm   = Join-Path $root 'platform_management'
    if (-not (Test-Path -LiteralPath $pm -PathType Container)) { return 0 }

    # 1) Line-based cleanup for .tf and simple references
    $patterns = @(
        '\bvar\.connectivity_type\b',
        '\bmodule\.resource_groups\b',
        '\bvar\.connectivity_resource_groups\b',
        '\bvar\.hub_and_spoke_networks_settings\b',
        '\bvar\.hub_virtual_networks\b',
        '\bvar\.virtual_wan_settings\b',
        '\bvar\.virtual_hubs\b',
        '\bvar\.connectivity_tags\b',

        # NOTE: we removed the bare 'connectivity_tags', 'virtual_hubs',
        # and 'virtual_wan_settings' so we don't corrupt multi-line JSON.

        '\bmodule\.hub_and_spoke_vnet\b',
        '\bmodule\.virtual_wan\b',

        '\bmodule\.config\.outputs\.(hub_and_spoke_networks_settings|hub_virtual_networks|virtual_wan_settings|virtual_hubs)\b'
    )
    $changedLines = Remove-AccelLines -Directory $pm -RegexPatterns $patterns -Confirm:$false

    # 2) JSON-aware cleanup for terraform.tfvars.json
    $jsonProps = @(
        'connectivity_tags',
        'virtual_hubs',
        'virtual_wan_settings'
    )
    $changedJson = Remove-AccelJsonProperties -Directory $pm -PropertyNames $jsonProps -Confirm:$false

    return ($changedLines + $changedJson)
}
