@echo off
title CIVITUS - Jugar Mundo Oceanico (Modo Normal de Supervivencia)
color 0b

echo ===============================================================================
echo            CIVITUS: EXPEDICION EN MUNDO OCEANICO 100%% (MODO NORMAL)
echo ===============================================================================
echo.
echo  Iniciando supervivencia en planeta pelagico 100%% sumergido...
echo  (Amerizaje con retro-propulsores, soporte vital, natacion y traje de astronauta)
echo.
echo  Quimicas oceanicas disponibles:
echo    JUGAR_MUNDO_OCEANICO.bat                     (Oceano H2O Agua Marina)
echo    JUGAR_MUNDO_OCEANICO.bat magma               (Oceano de Lava Silicatada Fundida)
echo    JUGAR_MUNDO_OCEANICO.bat acido               (Oceano de Acido Sulfurico)
echo    JUGAR_MUNDO_OCEANICO.bat metano              (Oceano Criogenico de Metano)
echo    JUGAR_MUNDO_OCEANICO.bat hycean              (Super-Oceano Hiceanico NH3-H2O)
echo.
echo ===============================================================================

set CHEM=%1
if "%CHEM%"=="" set CHEM=h2o

set SEED=%2
if "%SEED%"=="" set SEED=700777

where godot >nul 2>&1
if %ERRORLEVEL% equ 0 (
    godot "%~dp0scenes\tools\play_oceanic_world.tscn" -- --chem %CHEM% --seed %SEED%
    goto fin
)

if exist "C:\Users\nicol\bin\godot.exe" (
    "C:\Users\nicol\bin\godot.exe" "%~dp0scenes\tools\play_oceanic_world.tscn" -- --chem %CHEM% --seed %SEED%
    goto fin
)

echo ERROR: No se encontro el ejecutable de Godot en el sistema.
pause

:fin
