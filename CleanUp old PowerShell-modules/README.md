# Remove-OldModuleVersions

PowerShell script that removes old versions of installed PowerShell modules and keeps only the latest version of each module.

## What it does

1. Lists all installed modules:
   ```powershell
   Get-Module -ListAvailable | Select-Object Name, Version, ModuleBase
   ```
2. Groups them per module name and determines the latest (highest) version.
3. Collects the `ModuleBase` directories of all older versions, ordered by `ModuleBase`.
4. **By default only shows** which directories would be deleted (WhatIf mode). With `-WhatIf:$false` it really deletes them.
5. Records every run, including dry runs, in a transcript log.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator rights to delete modules from all-users folders such as
  `C:\Program Files\WindowsPowerShell\Modules` and `C:\Program Files\PowerShell\Modules`.
  Without admin rights those folders fail with a warning and the script continues.

## Options

**WhatIf mode is the default.** Without options the script only shows what it would delete. To really delete, add `-WhatIf:$false`.

All options can be combined on one command line.

| Option | Description |
|---|---|
| `-TranscriptFolder <path>` | Folder for the transcript log. Default: the folder the script is in. Created if it doesn't exist. |
| *(default)* or `-WhatIf` | Show which old directories would be deleted. Nothing is deleted. |
| `-WhatIf:$false` | Delete the old directories. |
| `-Confirm` | Ask for confirmation before deleting each directory. Only has effect together with `-WhatIf:$false`. |
| `-Verbose` | Also show skipped directories and progress messages. |

## Examples

Dry run (default): shows which old module directories would be deleted and which were skipped, writes the transcript to `C:\Logs`, and deletes nothing.

```powershell
.\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -Verbose
```

Real run with all options: asks before deleting each old module directory, shows which directories were skipped, and writes the transcript to `C:\Logs`.

```powershell
.\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -WhatIf:$false -Confirm -Verbose
```

Real run without prompts: deletes all old module directories, shows which were skipped, and writes the transcript to `C:\Logs`.

```powershell
.\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -WhatIf:$false -Verbose
```

Built-in help:

```powershell
Get-Help .\Remove-OldModuleVersions.ps1 -Full
```

## Sample output

Dry run (default):

```text
Transcript started, output file is C:\Logs\Remove-OldModuleVersions-TRANSCRIPT-2026-10-30_173544.log
What if: Performing the operation "Delete Az.Accounts 2.12.1 (latest is 3.0.4)" on target "C:\Users\me\Documents\PowerShell\Modules\Az.Accounts\2.12.1".
What if: Performing the operation "Delete Pester 5.4.0 (latest is 5.6.1)" on target "C:\Users\me\Documents\PowerShell\Modules\Pester\5.4.0".

Dry run: 2 old module directories found, nothing was deleted.
Run again with -WhatIf:$false to delete them.
```

Real run (`-WhatIf:$false`):

```text
Transcript started, output file is C:\Logs\Remove-OldModuleVersions-TRANSCRIPT-2026-10-30_173550.log
Deleted: C:\Users\me\Documents\PowerShell\Modules\Az.Accounts\2.12.1
Deleted: C:\Users\me\Documents\PowerShell\Modules\Pester\5.4.0

Done. Deleted: 2  Failed: 0
```

## Transcript

Every run writes a transcript named:

```text
<scriptname>-TRANSCRIPT-<yyyy-MM-dd_HHmmss>.log
```

For example `Remove-OldModuleVersions-TRANSCRIPT-2026-10-30_173544.log`.

- The log goes to the script's folder, or to `-TranscriptFolder` when given.
- If the transcript can't be started (for example, a folder without write access), the script stops with an error **before anything is deleted**.
- The transcript is always closed, also when there's nothing to delete, when an error occurs, or after Ctrl+C.

## Safety rules

- **Nothing is deleted unless you ask for it.** The default is a dry run; only `-WhatIf:$false` deletes.
- **System folders are never touched.** Anything under `$PSHOME` or the Windows folder is skipped, because those modules ship with PowerShell or Windows itself.
- **All copies of the latest version are kept.** If the latest version is installed in more than one folder, every one of those folders is kept.
- **A folder that contains the kept version is never deleted.**
- **Failed deletions don't stop the run.** Each failure is reported as a warning, and the summary at the end shows how many directories were deleted and how many failed.

Use `-Verbose` to see which directories were skipped and why.

## Things to know

- **Modules in use:** a module that is loaded in an open PowerShell session can have locked DLLs. Close other PowerShell sessions first, or run the script again afterwards.
- **Run from the right PowerShell edition:** PowerShell 7 also sees the module folders of Windows PowerShell 5.1. It can therefore delete an old version that 5.1 still uses, when the newer copy sits in a folder only PowerShell 7 searches (for example `Documents\PowerShell\Modules` vs. `Documents\WindowsPowerShell\Modules`). If you use both editions, check the dry-run output first.
- **Empty module folders:** only the old version's directory is deleted. If that was the only version in that location, an empty parent folder (for example `Modules\Pester`) can remain.
- **Execution policy:** if the script was downloaded, Windows may block it. Unblock it once with:
  ```powershell
  Unblock-File .\Remove-OldModuleVersions.ps1
  ```

## Recommended workflow

1. Run a dry run (the default) and review the output and transcript:
   ```powershell
   .\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -Verbose
   ```
2. Close other PowerShell sessions.
3. Run it for real from an elevated (Run as administrator) PowerShell window:
   ```powershell
   .\Remove-OldModuleVersions.ps1 -TranscriptFolder C:\Logs -WhatIf:$false -Verbose
   ```
