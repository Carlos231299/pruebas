#!/bin/bash
# Script de diagnóstico completo

echo "========================================="
echo "DIAGNÓSTICO COMPLETO"
echo "========================================="

PROJECT_DIR="/var/www/receptionplatform"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

echo ""
echo "1. Verificando servicios systemd..."
echo "Estado de reception-platform:"
sudo systemctl status reception-platform --no-pager -l | head -20

echo ""
echo "2. Verificando logs del servicio (últimas 30 líneas):"
sudo journalctl -u reception-platform -n 30 --no-pager

echo ""
echo "3. Verificando socket de Gunicorn:"
if [ -S "$BACKEND_DIR/reception-platform.sock" ]; then
    echo "✓ Socket existe:"
    ls -la "$BACKEND_DIR/reception-platform.sock"
else
    echo "✗ Socket NO existe"
fi

echo ""
echo "4. Verificando frontend compilado:"
if [ -d "$FRONTEND_DIR/dist" ] && [ "$(ls -A $FRONTEND_DIR/dist)" ]; then
    echo "✓ Frontend compilado existe:"
    ls -la "$FRONTEND_DIR/dist" | head -10
else
    echo "✗ Frontend NO está compilado"
fi

echo ""
echo "5. Verificando Nginx:"
sudo systemctl status nginx --no-pager -l | head -10

echo ""
echo "6. Últimos errores de Nginx:"
sudo tail -n 20 /var/log/nginx/error.log

echo ""
echo "7. Verificando acceso local a la API:"
curl -v http://localhost/api/ 2>&1 | head -20

echo ""
echo "8. Verificando acceso local al frontend:"
curl -v http://localhost/ 2>&1 | head -20

echo ""
echo "9. Verificando configuración de Nginx:"
sudo cat /etc/nginx/sites-available/reception-platform | grep -A 5 "location /"

echo ""
echo "10. Verificando puertos abiertos:"
sudo netstat -tlnp | grep -E ':80|:443|:8000'

echo ""
echo "11. Verificando permisos del socket:"
if [ -S "$BACKEND_DIR/reception-platform.sock" ]; then
    ls -la "$BACKEND_DIR/reception-platform.sock"
    sudo stat "$BACKEND_DIR/reception-platform.sock"
fi

echo ""
echo "12. Verificando proceso de Gunicorn:"
ps aux | grep gunicorn | grep -v grep

echo ""
echo "========================================="
echo "FIN DEL DIAGNÓSTICO"
echo "========================================="

