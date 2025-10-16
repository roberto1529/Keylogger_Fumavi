@echo off
chcp 65001 >nul
color 0C

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║       DESINSTALADOR - MONITOR DE SISTEMA              ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Solicitar confirmación
echo ⚠️  ADVERTENCIA: Esto eliminará completamente el monitor
echo.
echo ¿Estás seguro de que deseas desinstalar? (S/N)
set /p CONFIRMAR=
if /i not "%CONFIRMAR%"=="S" (
    echo.
    echo Desinstalación cancelada.
    pause
    exit /b 0
)

echo.
echo Iniciando desinstalación...
echo.

REM ========================================
REM Detener proceso
REM ========================================
echo [1/4] Deteniendo proceso...

tasklist /FI "IMAGENAME eq SystemMonitor.exe" 2>NUL | find /I /N "SystemMonitor.exe">NUL
if "%ERRORLEVEL%"=="0" (
    taskkill /F /IM SystemMonitor.exe >nul 2>&1
    if errorlevel 1 (
        echo    ⚠ No se pudo detener el proceso (puede no estar ejecutándose)
    ) else (
        echo    ✓ Proceso detenido
    )
) else (
    echo    • Proceso no está en ejecución
)

REM Esperar a que el proceso termine completamente
timeout /t 2 /nobreak >nul

echo.

REM ========================================
REM Eliminar del inicio automático
REM ========================================
echo [2/4] Eliminando del inicio automático...

reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" >nul 2>&1
if errorlevel 1 (
    echo    • No estaba en el inicio automático
) else (
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" /f >nul 2>&1
    if errorlevel 1 (
        echo    ⚠ No se pudo eliminar del registro
    ) else (
        echo    ✓ Eliminado del inicio automático
    )
)

echo.

REM ========================================
REM Eliminar archivos
REM ========================================
echo [3/4] Eliminando archivos...

set "INSTALL_DIR=%APPDATA%\SystemMonitor"

if exist "%INSTALL_DIR%" (
    echo    • Eliminando carpeta: %INSTALL_DIR%
    
    REM Intentar eliminar los archivos individualmente primero
    if exist "%INSTALL_DIR%\SystemMonitor.exe" del /F /Q "%INSTALL_DIR%\SystemMonitor.exe" 2>nul
    if exist "%INSTALL_DIR%\system_log.dat" del /F /Q "%INSTALL_DIR%\system_log.dat" 2>nul
    if exist "%INSTALL_DIR%\config.dat" del /F /Q "%INSTALL_DIR%\config.dat" 2>nul
    
    REM Eliminar la carpeta completa
    rmdir /S /Q "%INSTALL_DIR%" 2>nul
    
    if exist "%INSTALL_DIR%" (
        echo    ⚠ No se pudieron eliminar algunos archivos
        echo      Puedes eliminarlos manualmente desde:
        echo      %INSTALL_DIR%
    ) else (
        echo    ✓ Archivos eliminados correctamente
    )
) else (
    echo    • No se encontró la carpeta de instalación
)

echo.

REM ========================================
REM Verificar eliminación
REM ========================================
echo [4/4] Verificando eliminación...

set "TODO_LIMPIO=1"

REM Verificar proceso
tasklist /FI "IMAGENAME eq SystemMonitor.exe" 2>NUL | find /I /N "SystemMonitor.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo    ⚠ El proceso aún está en ejecución
    set "TODO_LIMPIO=0"
)

REM Verificar registro
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" >nul 2>&1
if not errorlevel 1 (
    echo    ⚠ Entrada en el registro aún existe
    set "TODO_LIMPIO=0"
)

REM Verificar carpeta
if exist "%INSTALL_DIR%" (
    echo    ⚠ La carpeta de instalación aún existe
    set "TODO_LIMPIO=0"
)

if "%TODO_LIMPIO%"=="1" (
    echo    ✓ Verificación completada - Todo limpio
)

echo.

REM ========================================
REM Resumen
REM ========================================
if "%TODO_LIMPIO%"=="1" (
    echo ╔════════════════════════════════════════════════════════╗
    echo ║          ✓ DESINSTALACIÓN COMPLETADA                  ║
    echo ╚════════════════════════════════════════════════════════╝
    echo.
    echo El Monitor de Sistema ha sido completamente eliminado:
    echo    • Proceso: Detenido
    echo    • Inicio automático: Desactivado
    echo    • Archivos: Eliminados
    echo    • Registros: Limpios
) else (
    echo ╔════════════════════════════════════════════════════════╗
    echo ║        ⚠ DESINSTALACIÓN PARCIAL                       ║
    echo ╚════════════════════════════════════════════════════════╝
    echo.
    echo Algunos elementos no se pudieron eliminar completamente.
    echo.
    echo LIMPIEZA MANUAL:
    echo ────────────────────────────────────────────────────────
    echo.
    echo 1. Abre el Administrador de Tareas (Ctrl+Shift+Esc)
    echo    • Busca: SystemMonitor.exe
    echo    • Finaliza la tarea si aparece
    echo.
    echo 2. Elimina la carpeta manualmente:
    echo    • Presiona: Windows + R
    echo    • Escribe: %%APPDATA%%\SystemMonitor
    echo    • Elimina la carpeta completa
    echo.
    echo 3. Verifica el inicio automático:
    echo    • Presiona: Windows + R
    echo    • Escribe: shell:startup
    echo    • Elimina cualquier acceso directo relacionado
)

echo.
echo ═══════════════════════════════════════════════════════════
echo.

pause