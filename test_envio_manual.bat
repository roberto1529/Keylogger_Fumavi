@echo off
chcp 65001 >nul
color 0E

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║         PRUEBA MANUAL DE ENVÍO - SISTEMA MONITOR      ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Buscar la instalación
set "INSTALL_DIR=%APPDATA%\SystemMonitor"

if not exist "%INSTALL_DIR%" (
    echo ❌ ERROR: El monitor no está instalado
    echo.
    echo Por favor instala primero con: instalar_inicio_automatico.bat
    echo.
    pause
    exit /b 1
)

echo 📂 Directorio de instalación: %INSTALL_DIR%
echo.

REM Verificar logs
set "LOGS_DIR=%INSTALL_DIR%\logs"

if not exist "%LOGS_DIR%" (
    echo ❌ No se encuentra la carpeta de logs
    echo.
    mkdir "%LOGS_DIR%"
    echo ✓ Carpeta de logs creada
    echo.
)

REM Obtener fecha actual
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set "DIA=%%a"
    set "MES=%%b"
    set "ANO=%%c"
)

REM Formato YYYY-MM-DD
set "FECHA=%ANO%-%MES%-%DIA%"
set "LOG_FILE=%LOGS_DIR%\log_%FECHA%.dat"

echo 📅 Fecha actual: %FECHA%
echo 📄 Archivo de log: %LOG_FILE%
echo.

REM Verificar si existe el log de hoy
if not exist "%LOG_FILE%" (
    echo ⚠️  No existe log para hoy, creando uno de prueba...
    echo.
    
    REM Crear log de prueba
    echo === Equipo: %COMPUTERNAME% === > "%LOG_FILE%"
    echo === Fecha: %FECHA% === >> "%LOG_FILE%"
    echo === LOG DE PRUEBA === >> "%LOG_FILE%"
    echo. >> "%LOG_FILE%"
    echo [%date% %time%] [PRUEBA] Inicio de prueba manual >> "%LOG_FILE%"
    echo [%date% %time%] T >> "%LOG_FILE%"
    echo [%date% %time%] E >> "%LOG_FILE%"
    echo [%date% %time%] S >> "%LOG_FILE%"
    echo [%date% %time%] T >> "%LOG_FILE%"
    echo [%date% %time%] [space] >> "%LOG_FILE%"
    echo [%date% %time%] M >> "%LOG_FILE%"
    echo [%date% %time%] A >> "%LOG_FILE%"
    echo [%date% %time%] N >> "%LOG_FILE%"
    echo [%date% %time%] U >> "%LOG_FILE%"
    echo [%date% %time%] A >> "%LOG_FILE%"
    echo [%date% %time%] L >> "%LOG_FILE%"
    echo [%date% %time%] [enter] >> "%LOG_FILE%"
    echo [%date% %time%] [PRUEBA] Fin de prueba manual >> "%LOG_FILE%"
    
    echo ✓ Log de prueba creado
    echo.
) else (
    echo ✓ Log de hoy encontrado
    echo.
)

REM Mostrar tamaño del log
for %%A in ("%LOG_FILE%") do set SIZE=%%~zA
echo 💾 Tamaño del log: %SIZE% bytes
echo.

if %SIZE% LSS 50 (
    echo ⚠️  El log es muy pequeño (menos de 50 bytes)
    echo    Agregando contenido de prueba...
    echo. >> "%LOG_FILE%"
    echo [%date% %time%] [PRUEBA MANUAL] Contenido agregado para prueba >> "%LOG_FILE%"
    echo.
)

REM Listar todos los logs disponibles
echo 📋 Logs disponibles:
echo ────────────────────────────────────────────────────────
if exist "%LOGS_DIR%\*.dat" (
    dir /b "%LOGS_DIR%\*.dat"
) else (
    echo    (ninguno)
)
echo ────────────────────────────────────────────────────────
echo.

REM Crear script Python para envío manual
echo 🔧 Generando script de envío...
echo.

set "PYTHON_SCRIPT=%INSTALL_DIR%\enviar_manual.py"

(
echo import smtplib
echo import ssl
echo import os
echo from email.message import EmailMessage
echo from datetime import datetime
echo.
echo # Configuración
echo SMTP_HOST = "smtp.zoho.com"
echo SMTP_PORT = 465
echo SMTP_USER = "onecore_mail@zohomail.com"
echo SMTP_PASS = "Onecore2025**"
echo MAIL_TO = "yarokasas@gmail.com"
echo LOG_FILE = r"%LOG_FILE%"
echo EQUIPO = "%COMPUTERNAME%"
echo.
echo print^("════════════════════════════════════════════════════════"^)
echo print^("         ENVIANDO CORREO DE PRUEBA MANUAL"^)
echo print^("════════════════════════════════════════════════════════"^)
echo print^(^)
echo print^(f"Equipo: {EQUIPO}"^)
echo print^(f"Log: {LOG_FILE}"^)
echo print^(^)
echo.
echo if not os.path.exists^(LOG_FILE^):
echo     print^("❌ ERROR: El archivo de log no existe"^)
echo     input^("Presiona Enter para salir..."^)
echo     exit^(1^)
echo.
echo size = os.path.getsize^(LOG_FILE^)
echo print^(f"Tamaño: {size} bytes"^)
echo print^(^)
echo.
echo if size ^< 50:
echo     print^("⚠️  ADVERTENCIA: El log es muy pequeño"^)
echo     print^(^)
echo.
echo # Crear mensaje
echo fecha = datetime.now^(^).strftime^('%%Y-%%m-%%d %%H:%%M'^)
echo subject = f"[PRUEBA MANUAL] {EQUIPO} - {fecha}"
echo body = f"""Prueba manual de envío
echo.
echo Equipo: {EQUIPO}
echo Fecha/Hora: {fecha}
echo Tamaño del log: {size} bytes
echo.
echo Este es un envío de prueba manual."""
echo.
echo msg = EmailMessage^(^)
echo msg["From"] = SMTP_USER
echo msg["To"] = MAIL_TO
echo msg["Subject"] = subject
echo msg.set_content^(body^)
echo.
echo # Adjuntar log
echo print^("📎 Adjuntando archivo..."^)
echo with open^(LOG_FILE, "rb"^) as f:
echo     data = f.read^(^)
echo msg.add_attachment^(data, maintype="application", subtype="octet-stream", filename=os.path.basename^(LOG_FILE^)^)
echo print^("   ✓ Archivo adjuntado"^)
echo print^(^)
echo.
echo # Enviar
echo print^("📧 Enviando correo..."^)
echo print^(f"   Servidor: {SMTP_HOST}:{SMTP_PORT}"^)
echo print^(f"   Destino: {MAIL_TO}"^)
echo print^(^)
echo.
echo try:
echo     context = ssl.create_default_context^(^)
echo     with smtplib.SMTP_SSL^(SMTP_HOST, SMTP_PORT, context=context^) as server:
echo         server.login^(SMTP_USER, SMTP_PASS^)
echo         server.send_message^(msg^)
echo     print^("════════════════════════════════════════════════════════"^)
echo     print^("              ✅ CORREO ENVIADO EXITOSAMENTE"^)
echo     print^("════════════════════════════════════════════════════════"^)
echo     print^(^)
echo     print^(f"Revisa tu correo: {MAIL_TO}"^)
echo except Exception as e:
echo     print^("════════════════════════════════════════════════════════"^)
echo     print^("                 ❌ ERROR AL ENVIAR"^)
echo     print^("════════════════════════════════════════════════════════"^)
echo     print^(^)
echo     print^(f"Error: {e}"^)
echo     print^(^)
echo     print^("Posibles causas:"^)
echo     print^("  • Credenciales incorrectas"^)
echo     print^("  • Sin conexión a internet"^)
echo     print^("  • Firewall bloqueando el puerto 465"^)
echo.
echo print^(^)
echo input^("Presiona Enter para salir..."^)
) > "%PYTHON_SCRIPT%"

echo ✓ Script generado: %PYTHON_SCRIPT%
echo.

REM Verificar si Python está disponible
echo 🔍 Verificando Python...
python --version >nul 2>&1

if errorlevel 1 (
    echo.
    echo ❌ ERROR: Python no está instalado
    echo.
    echo IMPORTANTE: Este equipo no tiene Python instalado.
    echo El ejecutable .exe NO requiere Python, pero esta
    echo prueba manual sí lo necesita.
    echo.
    echo OPCIONES:
    echo   1. Instala Python desde: https://www.python.org/downloads/
    echo   2. Espera hasta las 3 PM para que se envíe automáticamente
    echo   3. Verifica que el monitor esté corriendo
    echo.
    echo Para verificar si está corriendo:
    echo   - Abre Administrador de Tareas (Ctrl+Shift+Esc^)
    echo   - Busca: SystemMonitor.exe
    echo.
    pause
    exit /b 1
)

echo ✓ Python detectado
echo.

REM Ejecutar el script
echo ════════════════════════════════════════════════════════
echo.
python "%PYTHON_SCRIPT%"
echo.

REM Limpiar
del "%PYTHON_SCRIPT%" 2>nul

echo.
echo ════════════════════════════════════════════════════════
echo.
pause