@echo off
title %~nx0

cd /d %~dp0

powershell -file ".\Powershell5-install-Install-Module.ps1"

pause
