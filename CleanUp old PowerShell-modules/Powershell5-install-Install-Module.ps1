Write-Host "Check if logged on as Administrator" -ForegroundColor Yellow

# Abort if not running as Administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Aborting."
    Start-Sleep -Seconds 4
    exit 1
} else {
    Write-Host "Logged on as Administrator" -ForegroundColor Yellow
}


#
Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" -ForegroundColor Yellow
#
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force


#
Write-Host "Set SecurityProtocol = [Net.SecurityProtocolType]::Tls12" -ForegroundColor Yellow
#
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

$dest = 'C:\Program Files\WindowsPowerShell\Modules'
$pkgs = [ordered]@{ PackageManagement = '1.4.8.1'; PowerShellGet = '2.2.5' }

foreach ($name in $pkgs.Keys) {
    $ver = $pkgs[$name]
    $zip = "$env:TEMP\$name.$ver.zip"
    $out = "$dest\$name\$ver"
    (New-Object Net.WebClient).DownloadFile("https://www.powershellgallery.com/api/v2/package/$name/$ver", $zip)
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $out)
    Remove-Item -LiteralPath "$out\_rels","$out\package","$out\[Content_Types].xml","$out\$name.nuspec" -Recurse -Force -ErrorAction SilentlyContinue
}


#
Write-Host "Import module PackageManagement" -ForegroundColor Yellow
#
Import-Module "$dest\PackageManagement\1.4.8.1\PackageManagement.psd1"


#
Write-Host "Import module PowerShellGet" -ForegroundColor Yellow
#
Import-Module "$dest\PowerShellGet\2.2.5\PowerShellGet.psd1"


#
Write-Host "Set EnvironmentVariable" -ForegroundColor Yellow
#
$p = [Environment]::GetEnvironmentVariable('PSModulePath','Machine')
[Environment]::SetEnvironmentVariable('PSModulePath', "C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules;$p", 'Machine')
