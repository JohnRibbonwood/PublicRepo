<#
.SYNOPSIS
    Removes old versions of installed PowerShell modules and keeps only the latest version of each.

.DESCRIPTION
    Lists all installed modules with:
        Get-Module -ListAvailable | Select-Object Name, Version, ModuleBase
    groups them per module name and keeps the highest version. The ModuleBase directories
    of all older versions are processed in ModuleBase order and deleted.

    WhatIf mode is the DEFAULT: without options the script only shows which old directories
    would be deleted. To really delete them, add -WhatIf:$false.

    Options (all can be combined on one command line):
        -TranscriptFolder <path>  Folder for the transcript log (default: the script's folder).
        (default) / -WhatIf       Show which old directories would be deleted; delete nothing.
        -WhatIf:$false            Delete the old directories.
        -Confirm                  Ask for confirmation before deleting each directory
                                  (only has effect together with -WhatIf:$false).
        -Verbose                  Also show skipped directories and progress messages.

    Directories under $PSHOME and the Windows folder are never touched, because those
    modules ship with PowerShell / Windows itself.

    Every run (including -WhatIf runs) is recorded in a transcript named
        <scriptname>-TRANSCRIPT-<yyyy-MM-dd_HHmmss>.log
    in the script's folder, or in -TranscriptFolder when given.

.PARAMETER TranscriptFolder
    Folder for the transcript log. Default: the folder this script is in.
    The folder is created if it doesn't exist.

.EXAMPLE
    .\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -Verbose
    Dry run (default): shows which old module directories would be deleted and which
    were skipped, writes the transcript to C:\Logs, and deletes nothing.

.EXAMPLE
    .\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -WhatIf:$false -Confirm -Verbose
    Real run with all options: asks before deleting each old module directory, shows
    which directories were skipped, and writes the transcript to C:\Logs.

.EXAMPLE
    .\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -WhatIf:$false -Verbose
    Real run without prompts: deletes all old module directories, shows which were
    skipped, and writes the transcript to C:\Logs.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$TranscriptFolder = $PSScriptRoot
)

# WhatIf mode is the default: only delete when -WhatIf:$false is given explicitly
if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
}

$sep = [IO.Path]::DirectorySeparatorChar

function Get-NormalizedDir([string]$Path) {
    # Trailing separator so "C:\Mod\Foo" doesn't match "C:\Mod\FooBar"
    return $Path.TrimEnd('\', '/') + $sep
}

function Test-IsUnder([string]$Path, [string[]]$Roots) {
    $p = Get-NormalizedDir $Path
    foreach ($r in $Roots) {
        if ($p.StartsWith($r, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# --- Transcript -------------------------------------------------------------
$scriptName     = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$timestamp      = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$transcriptFile = Join-Path $TranscriptFolder "$scriptName-TRANSCRIPT-$timestamp.log"

# -WhatIf:$false so the transcript is also written during a -WhatIf run.
# If the log can't be written, stop before deleting anything.
try {
    # Windows PowerShell 5.1 doesn't create a missing transcript folder
    New-Item -ItemType Directory -Path $TranscriptFolder -Force -WhatIf:$false -Confirm:$false -ErrorAction Stop | Out-Null
    Start-Transcript -LiteralPath $transcriptFile -WhatIf:$false -Confirm:$false -ErrorAction Stop
}
catch {
    throw "Could not start transcript '$transcriptFile'. Nothing was deleted. Use -TranscriptFolder to pick a writable folder. ($($_.Exception.Message))"
}

try {
    # Modules that ship with PowerShell / Windows are never deleted
    $protectedRoots = @($PSHOME, $env:SystemRoot) |
        Where-Object { $_ } |
        ForEach-Object { Get-NormalizedDir $_ }

    Write-Verbose 'Collecting installed modules...'
    $modules = Get-Module -ListAvailable | Select-Object Name, Version, ModuleBase

    # Loop per module, keep the latest version, collect the older ones
    $toDelete = foreach ($group in $modules | Group-Object Name) {

        $latest    = ($group.Group | Sort-Object Version -Descending | Select-Object -First 1).Version
        $keepBases = @($group.Group | Where-Object { $_.Version -eq $latest } |
                       Select-Object -ExpandProperty ModuleBase -Unique)

        foreach ($old in $group.Group | Where-Object { $_.Version -lt $latest }) {

            if (Test-IsUnder $old.ModuleBase $protectedRoots) {
                Write-Verbose "Skipping (system folder): $($old.ModuleBase)"
                continue
            }

            # Never delete a folder that contains (or is) the folder of the version we keep
            $oldRoot = Get-NormalizedDir $old.ModuleBase
            if ($keepBases | Where-Object { Test-IsUnder $_ @($oldRoot) }) {
                Write-Verbose "Skipping (contains latest version): $($old.ModuleBase)"
                continue
            }

            [pscustomobject]@{
                Name          = $old.Name
                Version       = $old.Version
                LatestVersion = $latest
                ModuleBase    = $old.ModuleBase
            }
        }
    }

    # Order by ModuleBase, one entry per directory
    $toDelete = @($toDelete | Sort-Object ModuleBase -Unique)

    if ($toDelete.Count -eq 0) {
        Write-Host 'No old module versions found.'
        return
    }

    $deleted = 0
    $failed  = 0

    foreach ($item in $toDelete) {
        $action = "Delete $($item.Name) $($item.Version) (latest is $($item.LatestVersion))"

        if ($PSCmdlet.ShouldProcess($item.ModuleBase, $action)) {
            try {
                Remove-Item -LiteralPath $item.ModuleBase -Recurse -Force -Confirm:$false -ErrorAction Stop
                Write-Host "Deleted: $($item.ModuleBase)"
                $deleted++
            }
            catch {
                Write-Warning "Could not delete $($item.ModuleBase): $($_.Exception.Message)"
                $failed++
            }
        }
    }

    Write-Host ''
    if ($WhatIfPreference) {
        Write-Host "Dry run: $($toDelete.Count) old module directories found, nothing was deleted."
        Write-Host 'Run again with -WhatIf:$false to delete them.'
    }
    else {
        Write-Host "Done. Deleted: $deleted  Failed: $failed"
    }
}
finally {
    # Runs on normal end, on 'return', on errors and on Ctrl+C.
    # WhatIf/Confirm off so -WhatIf and -Confirm runs close the log without a prompt
    # (5.1 has no -WhatIf/-Confirm on Stop-Transcript, so set the preferences instead).
    $WhatIfPreference  = $false
    $ConfirmPreference = 'None'
    Stop-Transcript | Out-Null
}
