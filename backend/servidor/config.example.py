"""Configuración de ÓPTIMA. Cambiá estos valores según tu instalación de MySQL.
También se pueden definir como variables de entorno (OPTIMA_DB_PASSWORD, etc.)."""
import os
from pathlib import Path

BASE = Path(__file__).resolve().parent

DB_HOST     = os.environ.get('OPTIMA_DB_HOST', 'localhost')
DB_PORT     = int(os.environ.get('OPTIMA_DB_PORT', '3306'))
DB_USER     = os.environ.get('OPTIMA_DB_USER', 'optima')
DB_PASSWORD = os.environ.get('OPTIMA_DB_PASSWORD', 'tu_contraseña_de_mysql')      # <-- poné acá tu contraseña de MySQL (XAMPP suele no tener)
DB_NAME     = os.environ.get('OPTIMA_DB_NAME', 'optima_movil')

# Carpeta de la web (el "pc" del frontend) y carpeta donde se guardan fotos y CVs subidos
WEB_DIR     = Path(os.environ.get('OPTIMA_WEB_DIR', BASE.parent / 'pc'))
UPLOADS_DIR = BASE / 'uploads'

# Clave para firmar las cookies de sesión. Cambiala si algún día lo publicás.
SECRET_KEY  = os.environ.get('OPTIMA_SECRET', 'cambiame-por-algo-largo-y-secreto')

# Datos de ejemplo: si es True, cada evento nuevo recibe postulantes de ejemplo (para la demo).
# Ponelo en False cuando quieras usar el sistema "en serio".
DEMO_POSTULANTES = True
ADMIN_CORREO   = 'admin12@gmail.com'
ADMIN_PASSWORD = '4231'      # solo prototipo
TEL_PRUEBA     = '1139373911'  # teléfono de los trabajadores de ejemplo (10 dígitos)
