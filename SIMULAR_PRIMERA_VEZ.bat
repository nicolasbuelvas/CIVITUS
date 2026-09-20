@echo off
title CIVITUS - Simular Primera Vez
echo ===================================================
echo   CIVITUS // THE UNMILKY WAY HOME
echo   Restableciendo bandera de primer inicio...
echo ===================================================

set FLAG_FILE="%APPDATA%\Godot\app_userdata\CIVITUS- Procedural Exploration\intro_viewed.flag"
if exist %FLAG_FILE% (
    del /f /q %FLAG_FILE%
    echo [OK] Bandera de intro eliminada correctamente.
) else (
    echo [INFO] No existia bandera previa.
)

echo.
echo Iniciando juego como primera vez (Logo Godot + Intro completa)...
start "" "C:\Users\nicol\bin\godot.exe" --path "%~dp0."
