function Invoke-AccelOperation {
    <#
      .SYNOPSIS
      Executes a single file system operation (Move/Copy/Delete/DeleteDir).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][ValidateSet('Move','Copy','Delete','DeleteDir')]
        [string]$Action,

        [Parameter()][string]$Source,  # required for Move/Copy/Delete
        [Parameter()][string]$Destination, # required for Move/Copy
        [switch]$Force
    )

    switch ($Action) {
        'Move' {
           if (-not (Test-Path -LiteralPath $Source)) { Write-Verbose "Skip move (missing): $Source"; return 'Skipped' }
           $destDir = Split-Path -Parent -Path $Destination
           if ($destDir) { New-AccelDirectory -Path $destDir | Out-Null }
           if ($PSCmdlet.ShouldProcess("$Source", "Move to $Destination")) {
               if (Test-Path -LiteralPath $Destination) {
                   if ($Force) { Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction Stop }
                   else { Write-Warning "Destination exists, skipping: $Destination"; return 'Skipped' }
               }
               Move-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
               return 'Moved'
           }
       }

       'Copy' {
           if (-not (Test-Path -LiteralPath $Source)) { Write-Verbose "Skip copy (missing): $Source"; return 'Skipped' }
           $destDir = Split-Path -Parent -Path $Destination
           if ($destDir) { New-AccelDirectory -Path $destDir | Out-Null }
           if ($PSCmdlet.ShouldProcess("$Source", "Copy to $Destination")) {
               if (Test-Path -LiteralPath $Destination) {
                   if ($Force) { Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction Stop }
                   else { Write-Verbose "Destination exists; leaving as-is: $Destination"; return 'Skipped' }
               }
               Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force -ErrorAction Stop
               return 'Copied'
           }
       }

       'Delete' {
           if (-not (Test-Path -LiteralPath $Source)) { Write-Verbose "Skip delete (missing): $Source"; return 'Skipped' }
           if ($PSCmdlet.ShouldProcess("$Source", 'Delete file')) {
               Remove-Item -LiteralPath $Source -Force -ErrorAction Stop
               return 'Deleted'
           }
       }

       'DeleteDir' {
           if (-not (Test-Path -LiteralPath $Source)) { Write-Verbose "Skip delete dir (missing): $Source"; return 'Skipped' }
           if ($PSCmdlet.ShouldProcess("$Source", 'Delete directory')) {
               Remove-Item -LiteralPath $Source -Recurse -Force -ErrorAction Stop
               return 'Deleted'
           }
       }
    }
}
