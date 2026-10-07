# Get-RunningServices.ps1

Lists all services in the Running state, with start mode, logon account and
binary path. Queries `Win32_Service` in a single pass rather than calling
`Get-Service` and looking each of those properties up separately.

```powershell
.\Get-RunningServices.ps1                                   # all running services
.\Get-RunningServices.ps1 -ThirdPartyOnly                   # skip in-box Windows services
.\Get-RunningServices.ps1 -ThirdPartyOnly -IncludeProcess   # add PID, memory, CPU
.\Get-RunningServices.ps1 -Filter '*sql*' -CsvPath .\svc.csv
```

## Parameters

| Parameter | Effect |
| --- | --- |
| `-Filter` | Wildcard matched against `Name` and `DisplayName`. |
| `-ThirdPartyOnly` | Drops services whose binary lives under `%SystemRoot%`. |
| `-IncludeProcess` | Joins against `Get-Process` for `ProcessId`, `MemoryMB`, `CpuSeconds`. |
| `-CsvPath` | Also exports the results to CSV. |

## Notes

- `-IncludeProcess` needs an elevated shell for complete CPU figures. Without
  elevation `Get-Process` returns `$null` for `.CPU` on processes it cannot
  open, and the script leaves `CpuSeconds` blank rather than reporting a
  misleading `0`.
- `-ThirdPartyOnly` is a path heuristic, not a signature check. Vendor services
  installed into `System32` or `DriverStore` (NVIDIA, Intel, VMware networking,
  Realtek audio) are classed as Windows services, and a few in-box services
  with unusual paths leak the other way. Use `Get-AuthenticodeSignature` on the
  binary if you need an exact answer.
- Requires PowerShell 5.1 or later.
