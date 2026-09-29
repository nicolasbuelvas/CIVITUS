@echo off
title CIVITUS - Modo Fotografia y Captura HD
color 0a

echo ===============================================================================
echo            CIVITUS: MODO FOTOGRAFIA Y CAPTURAS EN ALTA DEFINICION (HD)
echo ===============================================================================
echo.
echo   El visor se iniciara directamente con el PLANETA BASE DE VIDA (HABITABLE).
echo.
echo  -----------------------------------------------------------------------------
echo   CONTROLES DE CAMARA Y FOTOGRAFIA:
echo  -----------------------------------------------------------------------------
echo.
echo    [C]  o  [F12]         : TOMAR FOTO HD EN PNG LIMPIO (Sin interfaz)
echo    [H]                   : Ocultar / Mostrar tarjeta de telemetria
echo    [O]                   : Vista Orbital Alta (Globo terraqueo completo)
echo    [P]                   : Vista de Superficie (Costas, relieve y bioma)
echo    [T]                   : Cambiar hora solar / posicion del sol (iluminacion)
echo    [F]                   : Pausar / Reanudar giro del planeta
echo    [Tab]                 : Alternar captura de raton (mirar libremente)
echo    [W, A, S, D]          : Volar libremente alrededor del planeta
echo    [Espacio / Ctrl]      : Subir o bajar altura de camara
echo    [Rueda del Raton]     : Cambiar velocidad de vuelo
echo.
echo  -----------------------------------------------------------------------------
echo   CAMBIAR DE MUNDO (1 al 8):
echo  -----------------------------------------------------------------------------
echo    [1] : BASE: HABITABLE / TEMPLADO (Bioma verde, oceanos H2O y vida)
echo    [2] : DESERTICO / ARIDO
echo    [3] : CRIOGENICO / GLACIAR
echo    [4] : TOXICO / SULFURICO
echo    [5] : IGNEO / MAGMATICO
echo    [6] : VACIO / LUNAR
echo    [7] : OCEANICO 100%%
echo    [8] : SINGULARIDAD / VOID
echo.
echo  Las capturas se guardan automaticamente en:
echo    .\capturas_hd\
echo.
echo ===============================================================================
echo  Iniciando visor en 1080p Full HD...
echo ===============================================================================

if not exist "%~dp0capturas_hd" mkdir "%~dp0capturas_hd"

where godot >nul 2>&1
if %ERRORLEVEL% equ 0 (
    godot --resolution 1920x1080 "%~dp0scenes\tools\spectator_viewer.tscn"
    goto post_run
)

if exist "C:\Users\nicol\bin\godot.exe" (
    "C:\Users\nicol\bin\godot.exe" --resolution 1920x1080 "%~dp0scenes\tools\spectator_viewer.tscn"
    goto post_run
)

echo ERROR: No se encontro el ejecutable de Godot en el sistema.
pause
exit /b 1

:post_run
echo.
echo ===============================================================================
echo  Sesion finalizada. Abriendo carpeta de capturas...
echo ===============================================================================
start "" "%~dp0capturas_hd"
