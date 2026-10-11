@echo off
title HWuP Launcher
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Solicitando permissao de Administrador...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0HWuP.ps1"
echo.
echo ================================================================
echo  HWuP foi encerrado. Se a janela do app fechou sozinha com erro,
echo  o texto do erro deve aparecer acima. Copie e me envie.
echo ================================================================
pause
