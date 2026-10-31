@echo off
title %~nx0

cd /d %~dp0

pwsh -command "Install-module az.accounts -RequiredVersion 2.2.3 -force"
pwsh -command "Install-module az.accounts -RequiredVersion 2.2.4 -force"
pwsh -command "Install-module az.accounts -RequiredVersion 2.2.5 -force"
pwsh -command "Install-module az.accounts -RequiredVersion 2.2.6 -force"
pwsh -command "Install-module az.accounts -RequiredVersion 2.2.7 -force"

pause
