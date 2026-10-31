@echo off
title %~nx0

cd /d %~dp0

powershell -file ".\PowerShell list all installed modules.ps1"

pause
