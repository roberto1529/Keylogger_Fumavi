@echo off
echo ============================================
echo   Instalador de Inicio Automatico
echo ============================================
echo.

REM Obtener la ruta completa del ejecutable
set "EXE_PATH=%~dp0SystemMonitor.exe"

REM Verificar que existe el ejecutable
if not exist "%EXE_PATH%" (
    echo ERROR: No se encuentra SystemMonitor.exe en esta carpeta
    echo.
    echo Por favor ejecuta primero build.bat para crear el ejecutable
    pause
    exit /b 1
)

echo Ruta del ejecutable: %EXE_PATH%
echo.

REM Copiar a una ubicacion del sistema
set "INSTALL_DIR=%APPDATA%\SystemMonitor"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [1/3] Copiando ejecutable a: %INSTALL_DIR%
copy /Y "%EXE_PATH%" "%INSTALL_DIR%\SystemMonitor.exe" >nul

if errorlevel 1 (
    echo ERROR: No se pudo copiar el archivo
    pause
    exit /b 1
)

REM Agregar al registro para inicio automatico
echo.
echo [2/3] Agregando al inicio automatico de Windows...

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" /t REG_SZ /d "\"%INSTALL_DIR%\SystemMonitor.exe\"" /f >nul

if errorlevel 1 (
    echo ERROR: No se pudo agregar al registro
    pause
    exit /b 1
)

REM Iniciar el programa ahora
echo.
echo [3/3] Iniciando el monitor...
start "" "%INSTALL_DIR%\SystemMonitor.exe"

echo.
echo ============================================
echo   INSTALACION COMPLETADA
echo ============================================
echo.
echo El monitor esta ahora:
echo [X] Ejecutandose en segundo plano (invisible)
echo [X] Configurado para iniciar con Windows
echo [X] Instalado en: %INSTALL_DIR%
echo.
echo Para desinstalar, ejecuta: desinstalar.bat
echo.
pause