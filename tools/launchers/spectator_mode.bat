@echo off
setlocal
set "PROJECT_DIR=%~dp0..\.."

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

"%GODOT_EXEC%" --path "%PROJECT_DIR%" "%PROJECT_DIR%\scenes\tools\spectator_viewer.tscn" %*
