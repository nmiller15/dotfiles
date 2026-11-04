@echo off
pwsh -NoProfile -File "%~dp0dtest.ps1" %*
exit /b %errorlevel%
