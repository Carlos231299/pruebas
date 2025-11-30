#!/bin/bash

# Script de instalación inicial en el servidor
# Ejecutar una sola vez para preparar el servidor

set -e

echo "========================================="
echo "Instalación Inicial del Servidor"
echo "========================================="

# Actualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar dependencias básicas
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
    libpq-dev \
    ufw

# Configurar firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Iniciar y habilitar servicios
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl enable redis-server
sudo systemctl start redis-server
sudo systemctl enable nginx

# Crear directorio del proyecto
sudo mkdir -p /var/www/reception-platform
sudo chown -R ubuntu:ubuntu /var/www/reception-platform

echo "========================================="
echo "Instalación completada"
echo "========================================="
echo ""
echo "Próximos pasos:"
echo "1. Clona tu repositorio en /var/www/reception-platform"
echo "2. Ejecuta deployment/deploy.sh para desplegar la aplicación"

