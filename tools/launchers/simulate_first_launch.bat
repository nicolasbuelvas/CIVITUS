@echo off
setlocal
set "PROJECT_DIR=%~dp0..\.."

set "FLAG_FILE=%APPDATA%\Godot\app_userdata\CIVITUS- Procedural Exploration\intro_viewed.flag"
if exist "%FLAG_FILE%" (
    del /f /q "%FLAG_FILE%"
    echo [INFO] Intro flag reset successfully.
)

if defined GODOT_BIN (
    set "GODOT_EXEC=%GODOT_BIN%"
) else (
    where godot.exe >nul 2>&1
    if not errorlevel 1 (
        set "GODOT_EXEC=godot.exe"
    ) else if exist "%USERPROFILE%\bin\godot.exe" (
        set "GODOT_EXEC=%USERPROFILE%\bin\godot.exe"
    ) else (
        echo [ERROR] godot.exe not found in PATH or %USERPROFILE%\bin\godot.exe
        exit /b 1
    )
)

start "" "%GODOT_EXEC%" --path "%PROJECT_DIR%"
