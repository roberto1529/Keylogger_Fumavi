@echo off
echo ============================================
echo   Desinstalador del Monitor de Sistema
echo ============================================
echo.

set "INSTALL_DIR=%APPDATA%\SystemMonitor"

echo [1/3] Deteniendo proceso...
taskkill /F /IM SystemMonitor.exe >nul 2>&1

timeout /t 2 /nobreak >nul

echo.
echo [2/3] Eliminando del inicio automatico...
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemMonitor" /f >nul 2>&1

echo.
echo [3/3] Eliminando archivos...
if exist "%INSTALL_DIR%" (
    rmdir /S /Q "%INSTALL_DIR%"
)

echo.
echo ============================================
echo   DESINSTALACION COMPLETADA
echo ============================================
echo.
echo El monitor ha sido completamente eliminado.
echo.
pause