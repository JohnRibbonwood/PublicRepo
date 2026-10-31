@echo off
title %~nx0

cd /d %~dp0

powershell -command  ".\Remove-Old-PowerShell-Module-versions.ps1" -TranscriptFolder c:\temp -WhatIf:$false
pause

pwsh -command  ".\Remove-Old-PowerShell-Module-versions.ps1" -TranscriptFolder c:\temp -WhatIf:$false
pause
