<#
.SYNOPSIS
    Lists all running Windows services.

.DESCRIPTION
    Returns every service in the Running state, with its start mode, account,
    and binary path. Optionally resolves the owning process (PID, CPU, memory)
    and filters out Microsoft-signed services to show only third-party ones.

.PARAMETER Filter
    Wildcard pattern matched against service Name and DisplayName.

.PARAMETER ThirdPartyOnly
    Exclude services whose binary lives under %SystemRoot% (i.e. in-box
    Windows services), leaving vendor and application services.

.PARAMETER IncludeProcess
    Resolve ProcessId, memory (MB) and total CPU seconds for each service.
    Requires elevation for some services; unresolved entries show $null.

.PARAMETER CsvPath
    Also write the results to this CSV file.

.EXAMPLE
    .\Get-RunningServices.ps1

.EXAMPLE
    .\Get-RunningServices.ps1 -ThirdPartyOnly -IncludeProcess

.EXAMPLE
    .\Get-RunningServices.ps1 -Filter '*sql*' -CsvPath .\sql-services.csv
#>
[CmdletBinding()]
param(
    [string]$Filter = '*',
    [switch]$ThirdPartyOnly,
    [switch]$IncludeProcess,
    [string]$CsvPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Win32_Service carries StartMode, StartName, PathName and ProcessId in one
# query -- Get-Service alone would need a second lookup for each of those.
$services = Get-CimInstance -ClassName Win32_Service -Filter "State = 'Running'"

if ($Filter -ne '*') {
    $services = $services | Where-Object { $_.Name -like $Filter -or $_.DisplayName -like $Filter }
}

if ($ThirdPartyOnly) {
    $systemRoot = [regex]::Escape($env:SystemRoot)
    $services = $services | Where-Object { $_.PathName -notmatch "^`"?$systemRoot" }
}

$processes = @{}
if ($IncludeProcess) {
    Get-Process | ForEach-Object { $processes[$_.Id] = $_ }
}

$results = foreach ($svc in $services) {
    $row = [ordered]@{
        Name        = $svc.Name
        DisplayName = $svc.DisplayName
        StartMode   = $svc.StartMode
        Account     = $svc.StartName
        Path        = $svc.PathName
    }

    if ($IncludeProcess) {
        $proc = if ($svc.ProcessId -and $processes.ContainsKey([int]$svc.ProcessId)) {
            $processes[[int]$svc.ProcessId]
        }
        $row.ProcessId = $svc.ProcessId
        $row.MemoryMB  = if ($proc) { [math]::Round($proc.WorkingSet64 / 1MB, 1) }
        # $proc.CPU is $null without rights to the process; rounding $null would
        # silently report 0.0, so leave it blank instead.
        $row.CpuSeconds = if ($proc -and $null -ne $proc.CPU) { [math]::Round($proc.CPU, 1) }
    }

    [pscustomobject]$row
}

$results = $results | Sort-Object DisplayName

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Verbose "Wrote $($results.Count) rows to $CsvPath"
}

$results
