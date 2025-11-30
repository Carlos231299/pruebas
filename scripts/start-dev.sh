#!/bin/bash

# Script para iniciar el entorno de desarrollo

echo "Iniciando servidores de desarrollo..."

# Iniciar backend en background
cd backend
source venv/bin/activate
python manage.py runserver &
BACKEND_PID=$!
cd ..

# Iniciar frontend
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo "Servidores iniciados:"
echo "Backend: http://localhost:8000 (PID: $BACKEND_PID)"
echo "Frontend: http://localhost:3000 (PID: $FRONTEND_PID)"
echo ""
echo "Presiona Ctrl+C para detener los servidores"

# Esperar a que se presione Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID; exit" INT
wait

