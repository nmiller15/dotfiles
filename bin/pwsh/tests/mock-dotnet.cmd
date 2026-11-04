@echo off
pwsh -NoProfile -File "%~dp0mock-dotnet.ps1" %*
exit /b %errorlevel%
