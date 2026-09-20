@echo off
title CIVITUS - Inspector de Mundos Procedurales (Modo Espectador)
color 0b

echo ===============================================================================
echo                CIVITUS: MODO ESPECTADOR (INSPECTOR DE MUNDOS)
echo ===============================================================================
echo.
echo  CATEGORIAS PADRE DE GENERACION PROCEDURAL:
echo  (Presiona la misma tecla para regenerar otro planeta completamente distinto)
echo.
echo    [1] : BASE: HABITABLE / TEMPLADO  - Océanos H2O, costas, llanuras con flora y cumbres nevadas.
echo    [2] : DESERTICO / ARIDO           - Regolito con óxido férrico, cañones secos y dunas.
echo    [3] : CRIOGENICO / GLACIAR        - Océanos de metano líquido cian, glaciares y anillos.
echo    [4] : TOXICO / SULFURICO          - Lagos de ácido sulfúrico concentrado y niebla corrosiva.
echo    [5] : IGNEO / MAGMATICO           - Mares de lava viva incandescente y basalto volcánico.
echo    [6] : VACIO / LUNAR               - Cuerpo sin atmósfera al vacío, regolito craterizado.
echo    [7] : OCEANICO / ACUATICO 100%%   - Mundo océano global pelágico, 100%% agua, fosas abisales.
echo    [8] : SINGULARIDAD / VOID PRO     - Basalto ultradenso y fracturas de plasma cuántico violeta.
echo.
echo    [R] : Regenerar un planeta completamente aleatorio de cualquier categoría.
echo.
echo  CONTROLES DE VUELO Y VISTAS (ESTILO MINECRAFT SPECTATOR):
echo    [W, A, S, D]        : Desplazamiento libre omnidireccional por el espacio
echo    [Espacio / Ctrl]    : Ascender o descender en el eje vertical
echo    [Rueda del Raton]   : Modificar velocidad de vuelo (de 2 a 280 m/s)
echo    [Shift (Mantener)]  : Turbo (aceleración x3.5)
echo    [O]                 : Teletransporte a Vista Orbital Alta (globo completo)
echo    [P]                 : Teletransporte a Vista de Superficie y Relieve
echo    [T]                 : Avanzar Hora Solar / Ciclo Día-Noche (atardeceres y reflejos)
echo    [F]                 : Pausar / Reanudar giro diurno planetario
echo    [Tab]               : Alternar captura de ratón para orientar la cámara
echo    [H]                 : Ocultar / Mostrar tarjeta de telemetría (capturas limpias)
echo    [Esc]               : Liberar ratón
echo.
echo ===============================================================================
echo  Iniciando visor 3D...
echo ===============================================================================

where godot >nul 2>&1
if %ERRORLEVEL% equ 0 (
    godot "%~dp0scenes\tools\spectator_viewer.tscn"
    goto fin
)

if exist "C:\Users\nicol\bin\godot.exe" (
    "C:\Users\nicol\bin\godot.exe" "%~dp0scenes\tools\spectator_viewer.tscn"
    goto fin
)

echo ERROR: No se encontro el ejecutable de Godot en el sistema.
pause

:fin
