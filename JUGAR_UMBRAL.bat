@echo off
cd /d "%~dp0"
where godot >nul 2>&1
if errorlevel 1 (
    echo ERROR: No se encuentra el comando godot en PATH.
    pause
    exit /b 1
)
echo Importando recursos de UMBRAL...
start /wait "" godot --headless --editor --path . --import
echo Abriendo el juego...
godot --path .
pause
