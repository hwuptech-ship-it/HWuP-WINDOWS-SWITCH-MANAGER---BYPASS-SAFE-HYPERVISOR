@echo off
title HWuP Build
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-HWuP.ps1"
