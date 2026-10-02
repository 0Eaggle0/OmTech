@echo off
rem Release: release.bat [patch|minor|major] [-DryRun]
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\release.ps1" %*
pause
