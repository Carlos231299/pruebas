#!/bin/bash

# Script para configurar el entorno de desarrollo local

set -e

echo "========================================="
echo "Configuración de Entorno de Desarrollo"
echo "========================================="

# Backend
echo "Configurando backend..."
cd backend

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r ../requirements.txt

# Crear .env si no existe
if [ ! -f ".env" ]; then
    cat > .env << EOF
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
OPENAI_API_KEY=your_openai_api_key_here
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
EOF
    echo "Archivo .env creado. Por favor, edita backend/.env con tu OPENAI_API_KEY"
fi

# Migraciones
python manage.py migrate

echo "Backend configurado correctamente"
deactivate

# Frontend
echo "Configurando frontend..."
cd ../frontend

npm install

# Crear .env si no existe
if [ ! -f ".env" ]; then
    cat > .env << EOF
VITE_API_URL=http://localhost:8000/api
VITE_WS_URL=ws://localhost:8000/ws
EOF
fi

echo "Frontend configurado correctamente"

echo "========================================="
echo "Configuración completada"
echo "========================================="
echo ""
echo "Para iniciar el desarrollo:"
echo "1. Backend: cd backend && source venv/bin/activate && python manage.py runserver"
echo "2. Frontend: cd frontend && npm run dev"

