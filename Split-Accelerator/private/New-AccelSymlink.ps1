function New-AccelSymlink {
    <#
      .SYNOPSIS
      Create/ensure a symbolic link. If a file/link exists, overwrite only with -Force.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$TargetPath,
        [switch]$Force
    )

    $dir = Split-Path -Parent -Path $LinkPath
    if ($dir) { New-AccelDirectory -Path $dir -Confirm:$false | Out-Null }

    if (Test-Path -LiteralPath $LinkPath) {
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($LinkPath, "Replace existing with symlink → $TargetPath")) {
                Remove-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Verbose "Link already exists, skipping: $LinkPath"
            return $true
        }
    }

    if ($PSCmdlet.ShouldProcess($LinkPath, "Create symlink → $TargetPath")) {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
    }
    return $true
}
