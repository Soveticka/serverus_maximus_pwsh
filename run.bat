@echo off
title Serverus Maximus Profile Copy
echo Starting PowerShell script...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Copy-ServerusMaximusProfile.ps1"
echo.
pause