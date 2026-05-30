@echo off
:: SGLite - SG Pinyin Bloatware Remover
:: https://github.com/dmtang-jpg/SGLite
:: License: MIT

:: Self-elevate to admin (handles paths with spaces)
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WorkingDirectory '%~dp0'"
    exit /b
)

:: Set UTF-8 codepage for Chinese display
chcp 65001 >nul 2>&1

:: Run PowerShell script
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0SGLite.ps1"
