@echo off
if "%~1"=="" exit /b 1
if not exist "%~1" exit /b 1

powershell -NoProfile -Command ^
  "$shell = New-Object -ComObject Shell.Application; " ^
  "$bin = $shell.Namespace(10); " ^
  "$bin.MoveHere('%~f1')"
