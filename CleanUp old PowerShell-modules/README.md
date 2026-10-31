# CleanUp old PowerShell-modules

Scripts to list installed PowerShell modules, remove old versions of them (keeping only the latest), and reinstall specific older versions for testing.

## Contents

| File | Purpose |
|---|---|
| `Remove-Old-PowerShell-Module-versions.ps1` | Main script. Removes old module versions and keeps the latest of each. Dry run by default. |
| `Remove-Old-PowerShell-Module-versions - SHOW only.cmd` | Dry run in Windows PowerShell 5.1, then in PowerShell 7. Deletes nothing. |
| `Remove-Old-PowerShell-Module-versions - REMOVE.cmd` | Real run (`-WhatIf:$false`) in Windows PowerShell 5.1, then in PowerShell 7. |
| `PowerShell list all installed modules.ps1` / `.cmd` | Writes all installed modules (name, version, path) to `Installed_PowerShell_Modules_<computer>_<timestamp>.txt`. Needs administrator rights. |
| `Powershell5-install-Install-Module.ps1` / `.cmd` | Bootstraps PackageManagement 1.4.8.1 and PowerShellGet 2.2.5 on Windows PowerShell 5.1 so `Install-Module` works. Needs administrator rights. |
| `Powershell5-install-previous-VMware.Vim-module.cmd` | Installs two older VMware.Vim versions (9.1.0.25718932 and 9.1.0.25380678) in Windows PowerShell 5.1, to create old versions to clean up. |
| `Powershell7-install-previous-Az.Account-modules.cmd` | Installs Az.Accounts 2.2.3 to 2.2.7 in PowerShell 7, to create old versions to clean up. |
| `Installed_PowerShell_Modules_*.txt` | Sample output of the list script. |

All `.cmd` files change to their own folder first, so they can be started by double-clicking. The `.cmd` files write transcripts to `c:\temp`.

## Remove-Old-PowerShell-Module-versions.ps1

### What it does

1. Lists all installed modules:
   ```powershell
   Get-Module -ListAvailable | Select-Object Name, Version, ModuleBase
   ```
2. Groups them per module name and determines the latest (highest) version.
3. Collects the `ModuleBase` directories of all older versions, ordered by `ModuleBase`.
4. **By default only shows** which directories would be deleted (WhatIf mode). With `-WhatIf:$false` it really deletes them.
5. Records every run, including dry runs, in a transcript log.

### Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator rights to delete modules from all-users folders such as
  `C:\Program Files\WindowsPowerShell\Modules` and `C:\Program Files\PowerShell\Modules`.
  Without admin rights those folders fail with a warning and the script continues.

### Options

**WhatIf mode is the default.** Without options the script only shows what it would delete. To really delete, add `-WhatIf:$false`. All options can be combined.

| Option | Description |
|---|---|
| `-TranscriptFolder <path>` | Folder for the transcript log. Default: the folder the script is in. Created if it doesn't exist. |
| *(default)* or `-WhatIf` | Show which old directories would be deleted. Nothing is deleted. |
| `-WhatIf:$false` | Delete the old directories. |
| `-Confirm` | Ask for confirmation before deleting each directory. Only has effect together with `-WhatIf:$false`. |
| `-Verbose` | Also show skipped directories and progress messages. |

### Examples

Dry run (default): shows which old module directories would be deleted, and deletes nothing.

```powershell
.\Remove-Old-PowerShell-Module-versions.ps1 -TranscriptFolder C:\Logs -Verbose
```

Real run, asking before each deletion:

```powershell
.\Remove-Old-PowerShell-Module-versions.ps1 -TranscriptFolder C:\Logs -WhatIf:$false -Confirm -Verbose
```

Real run without prompts:

```powershell
.\Remove-Old-PowerShell-Module-versions.ps1 -TranscriptFolder C:\Logs -WhatIf:$false -Verbose
```

Built-in help:

```powershell
Get-Help .\Remove-Old-PowerShell-Module-versions.ps1 -Full
```

### Sample output

Dry run (default):

```text
Transcript started, output file is C:\Logs\Remove-Old-PowerShell-Module-versions-TRANSCRIPT-2026-10-30_173544.log
What if: Performing the operation "Delete Az.Accounts 2.12.1 (latest is 3.0.4)" on target "C:\Users\me\Documents\PowerShell\Modules\Az.Accounts\2.12.1".
What if: Performing the operation "Delete Pester 5.4.0 (latest is 5.6.1)" on target "C:\Users\me\Documents\PowerShell\Modules\Pester\5.4.0".

Dry run: 2 old module directories found, nothing was deleted.
Run again with -WhatIf:$false to delete them.
```

Real run (`-WhatIf:$false`):

```text
Transcript started, output file is C:\Logs\Remove-Old-PowerShell-Module-versions-TRANSCRIPT-2026-10-30_173550.log
Deleted: C:\Users\me\Documents\PowerShell\Modules\Az.Accounts\2.12.1
Deleted: C:\Users\me\Documents\PowerShell\Modules\Pester\5.4.0

Done. Deleted: 2  Failed: 0
```

### Transcript

Every run writes a transcript named `<scriptname>-TRANSCRIPT-<yyyy-MM-dd_HHmmss>.log`, in the script's folder or in `-TranscriptFolder` when given.

- A missing `-TranscriptFolder` is created, also on Windows PowerShell 5.1.
- If the transcript can't be started (for example, a folder without write access), the script stops with an error **before anything is deleted**.
- The transcript is always closed, also when there's nothing to delete, when an error occurs, or after Ctrl+C.

### Safety rules

- **Nothing is deleted unless you ask for it.** The default is a dry run; only `-WhatIf:$false` deletes.
- **System folders are never touched.** Anything under `$PSHOME` or the Windows folder is skipped, because those modules ship with PowerShell or Windows itself.
- **All copies of the latest version are kept.** If the latest version is installed in more than one folder, every one of those folders is kept.
- **A folder that contains the kept version is never deleted.**
- **Failed deletions don't stop the run.** Each failure is reported as a warning, and the summary shows how many directories were deleted and how many failed.

Use `-Verbose` to see which directories were skipped and why.

### Things to know

- **Modules in use:** a module loaded in an open PowerShell session can have locked DLLs. Close other PowerShell sessions first, or run the script again afterwards.
- **Run from the right PowerShell edition:** PowerShell 7 also sees the module folders of Windows PowerShell 5.1. It can therefore delete an old version that 5.1 still uses, when the newer copy sits in a folder only PowerShell 7 searches (for example `Documents\PowerShell\Modules` vs. `Documents\WindowsPowerShell\Modules`). If you use both editions, check the dry-run output first.
- **Empty module folders:** only the old version's directory is deleted. If that was the only version in that location, an empty parent folder (for example `Modules\Pester`) can remain.
- **Execution policy:** if the script was downloaded, Windows may block it. Unblock it once with:
  ```powershell
  Unblock-File .\Remove-Old-PowerShell-Module-versions.ps1
  ```

### Recommended workflow

1. Run a dry run (the default) and review the output and transcript, or double-click `Remove-Old-PowerShell-Module-versions - SHOW only.cmd`.
2. Close other PowerShell sessions.
3. Run it for real from an elevated (Run as administrator) window, or run `Remove-Old-PowerShell-Module-versions - REMOVE.cmd` as administrator.

## Other scripts

- **List installed modules:** run `PowerShell list all installed modules.cmd` as administrator. The result is saved in the current folder as `Installed_PowerShell_Modules_<computer>_<yyyy-MM-dd_HHmmss>.txt`.
- **Fix `Install-Module` on Windows PowerShell 5.1:** run `Powershell5-install-Install-Module.cmd` as administrator. It sets the execution policy to `RemoteSigned` for the current user, enables TLS 1.2, downloads PackageManagement 1.4.8.1 and PowerShellGet 2.2.5 from the PowerShell Gallery into `C:\Program Files\WindowsPowerShell\Modules`, imports them, and puts the two Windows PowerShell module folders at the front of the machine-wide `PSModulePath` (without adding duplicates when run again). The downloaded `.zip` files are deleted afterwards.
- **Create old versions to test with:** `Powershell5-install-previous-VMware.Vim-module.cmd` and `Powershell7-install-previous-Az.Account-modules.cmd` install several older versions side by side, so the remove script has something to find.
