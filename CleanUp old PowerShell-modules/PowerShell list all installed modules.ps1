Write-Host "Getting all installed PowerShell-modules..." -ForegroundColor Yellow

# Abort if not running as Administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Aborting."
    Start-Sleep -Seconds 4
    exit 1
}

$scriptName = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$file = "Installed_PowerShell_Modules_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').txt"
Get-Module -ListAvailable | Select-Object Name, Version, ModuleBase |
    Format-Table -AutoSize | Out-File -FilePath $file -Width 500 -Encoding utf8

Write-Host "Results written to: $($file) " -ForegroundColor Yellow
