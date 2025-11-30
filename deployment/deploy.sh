#!/bin/bash

# Script de despliegue para la plataforma de recepción de clientes
# Ejecutar en el servidor Linux EC2

set -e

echo "========================================="
echo "Desplegando Plataforma de Recepción"
echo "========================================="

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio del proyecto
PROJECT_DIR="/var/www/reception-platform"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Función para instalar dependencias del sistema
install_system_dependencies() {
    echo -e "${YELLOW}Instalando dependencias del sistema...${NC}"
    
    sudo apt-get update
    sudo apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        postgresql \
        postgresql-contrib \
        nginx \
        nodejs \
        npm \
        redis-server \
        git \
        build-essential \
        libpq-dev
}

# Función para configurar PostgreSQL
setup_postgresql() {
    echo -e "${YELLOW}Configurando PostgreSQL...${NC}"
    
    # Crear base de datos y usuario (ajustar según necesidades)
    sudo -u postgres psql << EOF
CREATE DATABASE reception_platform;
CREATE USER reception_user WITH PASSWORD 'change_this_password';
ALTER ROLE reception_user SET client_encoding TO 'utf8';
ALTER ROLE reception_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE reception_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE reception_platform TO reception_user;
\q
EOF
}

# Función para configurar el backend
setup_backend() {
    echo -e "${YELLOW}Configurando backend Django...${NC}"
    
    cd $BACKEND_DIR
    
    # Crear entorno virtual si no existe
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # Instalar dependencias
    pip install --upgrade pip
    pip install -r ../requirements.txt
    
    # Crear archivo .env si no existe
    if [ ! -f ".env" ]; then
        cat > .env << EOF
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=False
ALLOWED_HOSTS=ec2-3-101-33-120.us-west-1.compute.amazonaws.com,localhost,127.0.0.1
DATABASE_URL=postgresql://reception_user:change_this_password@localhost:5432/reception_platform
OPENAI_API_KEY=your_openai_api_key_here
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
CORS_ALLOWED_ORIGINS=https://ec2-3-101-33-120.us-west-1.compute.amazonaws.com,http://localhost:3000
EOF
        echo -e "${YELLOW}Archivo .env creado. Por favor, edítalo con tus valores reales.${NC}"
    fi
    
    # Ejecutar migraciones
    python manage.py migrate
    
    # Recopilar archivos estáticos
    python manage.py collectstatic --noinput
    
    deactivate
}

# Función para configurar el frontend
setup_frontend() {
    echo -e "${YELLOW}Configurando frontend React...${NC}"
    
    cd $FRONTEND_DIR
    
    # Instalar dependencias
    npm install
    
    # Crear archivo .env si no existe
    if [ ! -f ".env" ]; then
        cat > .env << EOF
VITE_API_URL=https://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/api
VITE_WS_URL=wss://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/ws
EOF
    fi
    
    # Build de producción
    npm run build
}

# Función para configurar Gunicorn
setup_gunicorn() {
    echo -e "${YELLOW}Configurando Gunicorn...${NC}"
    
    cd $BACKEND_DIR
    
    # Crear servicio systemd para Gunicorn
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

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable reception-platform
    sudo systemctl restart reception-platform
}

# Función para configurar Nginx
setup_nginx() {
    echo -e "${YELLOW}Configurando Nginx...${NC}"
    
    # Copiar configuración de Nginx
    sudo cp $PROJECT_DIR/deployment/nginx.conf /etc/nginx/sites-available/reception-platform
    
    # Crear enlace simbólico
    sudo ln -sf /etc/nginx/sites-available/reception-platform /etc/nginx/sites-enabled/
    
    # Eliminar configuración por defecto si existe
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Probar configuración
    sudo nginx -t
    
    # Reiniciar Nginx
    sudo systemctl restart nginx
}

# Función principal
main() {
    echo -e "${GREEN}Iniciando despliegue...${NC}"
    
    # Crear directorio del proyecto si no existe
    sudo mkdir -p $PROJECT_DIR
    sudo chown -R ubuntu:ubuntu $PROJECT_DIR
    
    # Instalar dependencias del sistema
    install_system_dependencies
    
    # Configurar PostgreSQL
    setup_postgresql
    
    # Configurar backend
    setup_backend
    
    # Configurar frontend
    setup_frontend
    
    # Configurar Gunicorn
    setup_gunicorn
    
    # Configurar Nginx
    setup_nginx
    
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}Despliegue completado exitosamente!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. Edita el archivo $BACKEND_DIR/.env con tus valores reales"
    echo "2. Edita el archivo $FRONTEND_DIR/.env con tus valores reales"
    echo "3. Reinicia los servicios:"
    echo "   sudo systemctl restart reception-platform"
    echo "   sudo systemctl restart nginx"
    echo "4. Verifica los logs:"
    echo "   sudo journalctl -u reception-platform -f"
}

# Ejecutar función principal
main

