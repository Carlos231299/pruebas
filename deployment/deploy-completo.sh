#!/bin/bash
# Script de despliegue completo - ejecutar paso a paso

set -e

PROJECT_DIR="/var/www/receptionplatform"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

echo "=== PASO 1: Verificar permisos ==="
sudo chown -R ubuntu:ubuntu "$PROJECT_DIR"

echo ""
echo "=== PASO 2: Configurar Backend ==="
cd "$BACKEND_DIR"

if [ ! -d "venv" ]; then
    echo "Creando entorno virtual..."
    python3 -m venv venv
fi

source venv/bin/activate

echo "Buscando requirements.txt..."
if [ -f "../requirements.txt" ]; then
    echo "✓ Encontrado: ../requirements.txt"
    pip install --upgrade pip
    pip install -r ../requirements.txt
else
    echo "✗ ERROR: requirements.txt no encontrado en ../requirements.txt"
    echo "Buscando en otras ubicaciones..."
    find "$PROJECT_DIR" -name "requirements.txt" -type f
    exit 1
fi

# Migraciones y static files
python manage.py migrate --noinput || echo "Advertencia: Error en migraciones"
python manage.py collectstatic --noinput || echo "Advertencia: Error en collectstatic"

deactivate

echo ""
echo "=== PASO 3: Configurar Frontend ==="
cd "$FRONTEND_DIR"

if [ ! -d "node_modules" ]; then
    echo "Instalando dependencias de Node.js..."
    npm install
fi

if [ ! -f ".env" ]; then
    echo "Creando .env del frontend..."
    cat > .env << EOF
VITE_API_URL=http://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/api
VITE_WS_URL=ws://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/ws
EOF
fi

echo "Compilando frontend..."
npm run build

echo ""
echo "=== PASO 4: Configurar servicio systemd ==="
sudo tee /etc/systemd/system/reception-platform.service > /dev/null << EOF
[Unit]
Description=Reception Platform Gunicorn daemon
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
ExecStart=$BACKEND_DIR/venv/bin/gunicorn \\
    --access-logfile - \\
    --workers 3 \\
    --bind unix:$BACKEND_DIR/reception-platform.sock \\
    --worker-class uvicorn.workers.UvicornWorker \\
    reception_platform.asgi:application
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable reception-platform
sudo systemctl restart reception-platform

echo ""
echo "=== PASO 5: Configurar Nginx ==="
sudo cp "$PROJECT_DIR/deployment/nginx.conf" /etc/nginx/sites-available/reception-platform
sudo ln -sf /etc/nginx/sites-available/reception-platform /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo ""
echo "=== VERIFICACIÓN FINAL ==="
echo "Estado de servicios:"
sudo systemctl status reception-platform --no-pager | head -5 || true
echo ""
sudo systemctl status nginx --no-pager | head -5 || true

echo ""
echo "✓ Despliegue completado!"
echo "Accede a: http://ec2-3-101-33-120.us-west-1.compute.amazonaws.com"

