function New-AccelBackup {
    <#
      .SYNOPSIS
      Create a backup copy of the ALZ directory before we start moving/splitting.

      .DESCRIPTION
      Given a path to the ALZ repo root, create a sibling directory with
      a -bak, -bak1, -bak2... suffix and copy the entire tree there.

      Examples:
        C:\repos\alz-mgmt  -> C:\repos\alz-mgmt-bak
        C:\repos\alz-mgmt  -> C:\repos\alz-mgmt-bak1 (if -bak already exists)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    $root = Resolve-AccelPath -Path $Path

    $parent = Split-Path -Parent -Path $root
    $name   = Split-Path -Leaf   -Path $root

    # base candidate: <name>-bak, then <name>-bak1, -bak2, ...
    $suffix = '-bak'
    $candidateName = "$name$suffix"
    $candidatePath = Join-Path $parent $candidateName

    $i = 1
    while (Test-Path -LiteralPath $candidatePath) {
        $candidateName = "{0}{1}{2}" -f $name, $suffix, $i
        $candidatePath = Join-Path $parent $candidateName
        $i++
    }

    if ($PSCmdlet.ShouldProcess($root, "Backup to '$candidatePath'")) {
        # Copy the whole directory tree into the backup directory
        Copy-Item -LiteralPath $root -Destination $candidatePath -Recurse -Force:$Force -ErrorAction Stop
    }

    # Return backup path for logging if needed
    return $candidatePath
}