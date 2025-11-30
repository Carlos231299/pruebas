# Configuración de Gunicorn para la plataforma de recepción

import multiprocessing
import os

# Directorio del proyecto
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Configuración del servidor
bind = "unix:/var/www/reception-platform/backend/reception-platform.sock"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "channels.asgi.WorkerChannelLayerWorker"
worker_connections = 1000
timeout = 30
keepalive = 2

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"

# Proceso
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None

# SSL (si es necesario)
keyfile = None
certfile = None

