#!/bin/bash

# Script de verificación y despliegue completo
# Ejecutar en el servidor EC2

set -e

echo "========================================="
echo "Verificación y Despliegue Completo"
echo "========================================="

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorio del proyecto (SIN GUION)
PROJECT_DIR="/var/www/receptionplatform"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Verificar que el directorio existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: El directorio $PROJECT_DIR no existe${NC}"
    exit 1
fi

echo -e "${GREEN}1. Verificando permisos...${NC}"
sudo chown -R ubuntu:ubuntu "$PROJECT_DIR"
echo -e "${GREEN}✓ Permisos configurados${NC}"

echo -e "${GREEN}2. Configurando backend...${NC}"
cd "$BACKEND_DIR"

# Verificar entorno virtual
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creando entorno virtual...${NC}"
    python3 -m venv venv
fi

source venv/bin/activate

# Instalar dependencias
if [ -f "../../requirements.txt" ]; then
    echo -e "${YELLOW}Instalando dependencias de Python...${NC}"
    pip install --upgrade pip
    pip install -r ../../requirements.txt
else
    echo -e "${RED}Error: requirements.txt no encontrado${NC}"
    exit 1
fi

# Verificar archivo .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creando archivo .env...${NC}"
    SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    cat > .env << EOF
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=ec2-3-101-33-120.us-west-1.compute.amazonaws.com,localhost,127.0.0.1
DATABASE_URL=postgresql://reception_user:change_this_password@localhost:5432/reception_platform
OPENAI_API_KEY=
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
CORS_ALLOWED_ORIGINS=https://ec2-3-101-33-120.us-west-1.compute.amazonaws.com,http://localhost:3000
EOF
    echo -e "${YELLOW}Archivo .env creado. Por favor, edítalo con tus valores reales.${NC}"
fi

# Ejecutar migraciones
echo -e "${YELLOW}Ejecutando migraciones...${NC}"
python manage.py migrate --noinput || echo -e "${YELLOW}Advertencia: Error en migraciones (puede ser normal si la BD no está configurada)${NC}"

# Recopilar archivos estáticos
echo -e "${YELLOW}Recopilando archivos estáticos...${NC}"
python manage.py collectstatic --noinput || echo -e "${YELLOW}Advertencia: Error recopilando archivos estáticos${NC}"

deactivate
echo -e "${GREEN}✓ Backend configurado${NC}"

echo -e "${GREEN}3. Configurando frontend...${NC}"
cd "$FRONTEND_DIR"

# Verificar node_modules
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Instalando dependencias de Node.js...${NC}"
    npm install
fi

# Crear archivo .env si no existe
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creando archivo .env del frontend...${NC}"
    cat > .env << EOF
VITE_API_URL=http://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/api
VITE_WS_URL=ws://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/ws
EOF
fi

# Compilar frontend
echo -e "${YELLOW}Compilando frontend...${NC}"
npm run build
echo -e "${GREEN}✓ Frontend configurado${NC}"

echo -e "${GREEN}4. Configurando servicio systemd (Gunicorn)...${NC}"

# Crear servicio systemd
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

# Recargar systemd y habilitar servicio
sudo systemctl daemon-reload
sudo systemctl enable reception-platform
sudo systemctl restart reception-platform || echo -e "${YELLOW}Advertencia: Error al iniciar el servicio (puede ser normal si hay errores en .env)${NC}"
echo -e "${GREEN}✓ Servicio systemd configurado${NC}"

echo -e "${GREEN}5. Configurando Nginx...${NC}"

# Verificar que nginx.conf existe
if [ ! -f "$PROJECT_DIR/deployment/nginx.conf" ]; then
    echo -e "${RED}Error: nginx.conf no encontrado en $PROJECT_DIR/deployment/${NC}"
    exit 1
fi

# Copiar configuración de Nginx
sudo cp "$PROJECT_DIR/deployment/nginx.conf" /etc/nginx/sites-available/reception-platform

# Crear enlace simbólico
sudo ln -sf /etc/nginx/sites-available/reception-platform /etc/nginx/sites-enabled/

# Eliminar configuración por defecto
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar sintaxis
if sudo nginx -t; then
    sudo systemctl restart nginx
    echo -e "${GREEN}✓ Nginx configurado${NC}"
else
    echo -e "${RED}Error en la configuración de Nginx${NC}"
    exit 1
fi

echo -e "${GREEN}6. Verificando estado de servicios...${NC}"

# Verificar servicio de Django
if sudo systemctl is-active --quiet reception-platform; then
    echo -e "${GREEN}✓ Servicio reception-platform está corriendo${NC}"
else
    echo -e "${RED}✗ Servicio reception-platform NO está corriendo${NC}"
    echo -e "${YELLOW}Ver logs con: sudo journalctl -u reception-platform -n 50${NC}"
fi

# Verificar Nginx
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx está corriendo${NC}"
else
    echo -e "${RED}✗ Nginx NO está corriendo${NC}"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Verificación completada${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Próximos pasos:"
echo "1. Verifica el archivo $BACKEND_DIR/.env (especialmente OPENAI_API_KEY)"
echo "2. Verifica los logs si hay problemas:"
echo "   sudo journalctl -u reception-platform -f"
echo "   sudo tail -f /var/log/nginx/error.log"
echo "3. Accede a: http://ec2-3-101-33-120.us-west-1.compute.amazonaws.com"
echo ""
echo "Comandos útiles:"
echo "  - Ver estado: sudo systemctl status reception-platform"
echo "  - Reiniciar: sudo systemctl restart reception-platform"
echo "  - Ver logs: sudo journalctl -u reception-platform -n 50"

