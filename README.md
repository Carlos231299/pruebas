# Plataforma de Recepción de Clientes

Plataforma web para recepción de clientes con chatbot integrado (OpenAI) y chat en vivo con asesores mediante WebSocket.

## Características

- 🤖 **Chatbot con IA**: Integración con OpenAI API para respuestas inteligentes
- 💬 **Chat en Vivo**: Sistema de chat en tiempo real con asesores usando WebSocket
- 📝 **Historial de Conversaciones**: Registro y consulta de todas las conversaciones
- 🎨 **Interfaz Moderna**: UI responsive y atractiva construida con React
- 🚀 **Lista para Producción**: Configuración completa para despliegue en servidor Linux

## Arquitectura

- **Frontend**: React + TypeScript + Vite
- **Backend**: Django + Django REST Framework + Django Channels
- **Base de Datos**: PostgreSQL (producción) / SQLite (desarrollo)
- **WebSocket**: Django Channels con Redis
- **Servidor Web**: Nginx + Gunicorn

## Requisitos Previos

- Python 3.9+
- Node.js 18+
- PostgreSQL (para producción)
- Redis (opcional, para producción)
- Nginx
- Git

## Instalación Local

### 1. Clonar el repositorio

```bash
git clone <tu-repositorio>
cd pruebas
```

### 2. Configurar Backend

```bash
cd backend

# Crear entorno virtual
python -m venv venv

# Activar entorno virtual
# En Windows:
venv\Scripts\activate
# En Linux/Mac:
source venv/bin/activate

# Instalar dependencias
pip install -r ../requirements.txt

# Crear archivo .env
cp .env.example .env
# Editar .env con tus valores:
# - SECRET_KEY (generar uno nuevo)
# - OPENAI_API_KEY (tu clave de OpenAI)
# - DATABASE_URL (si usas PostgreSQL)

# Ejecutar migraciones
python manage.py migrate

# Crear superusuario (opcional)
python manage.py createsuperuser

# Ejecutar servidor de desarrollo
python manage.py runserver
```

### 3. Configurar Frontend

```bash
cd frontend

# Instalar dependencias
npm install

# Crear archivo .env
cp .env.example .env
# Editar .env con tus valores:
# - VITE_API_URL=http://localhost:8000/api
# - VITE_WS_URL=ws://localhost:8000/ws

# Ejecutar servidor de desarrollo
npm run dev
```

La aplicación estará disponible en `http://localhost:3000`

## Subir a Repositorio Git

Antes de desplegar en el servidor, es recomendable subir el código a un repositorio Git (GitHub, GitLab, etc.).

### Opción 1: Usar Scripts Automáticos (Windows)

1. **Inicializar repositorio local:**
   ```bash
   setup-repo.bat
   ```

2. **Crear repositorio en GitHub/GitLab** y copiar la URL

3. **Subir al repositorio remoto:**
   ```bash
   setup-push.bat
   ```
   (Te pedirá la URL del repositorio)

### Opción 2: Comandos Manuales

Ver `INSTRUCCIONES_GIT.md` para instrucciones detalladas.

## Despliegue en Servidor Linux (EC2)

### Acceso al Servidor

```bash
ssh -i "pruebas.pem" ubuntu@ec2-3-101-33-120.us-west-1.compute.amazonaws.com
```

### Opción A: Clonar desde Repositorio Git (Recomendado)

```bash
# En el servidor EC2
cd /var/www
sudo git clone https://github.com/tu-usuario/recepcion-clientes.git reception-platform
sudo chown -R ubuntu:ubuntu /var/www/reception-platform
cd reception-platform
```

### Opción B: Subir Archivos Directamente

```bash
# Desde tu máquina local (Windows PowerShell)
scp -i "pruebas.pem" -r . ubuntu@ec2-3-101-33-120.us-west-1.compute.amazonaws.com:/var/www/reception-platform/
```

### 1. Instalación Inicial (Solo primera vez)

```bash
# Subir archivos al servidor
scp -i "pruebas.pem" -r . ubuntu@ec2-3-101-33-120.us-west-1.compute.amazonaws.com:/var/www/reception-platform/

# Conectarse al servidor
ssh -i "pruebas.pem" ubuntu@ec2-3-101-33-120.us-west-1.compute.amazonaws.com

# Ejecutar script de instalación
cd /var/www/reception-platform
chmod +x deployment/install.sh
sudo ./deployment/install.sh
```

### 2. Configurar Variables de Entorno

```bash
cd /var/www/reception-platform/backend

# Crear archivo .env
nano .env
```

Agregar las siguientes variables:

```env
SECRET_KEY=tu-secret-key-generado
DEBUG=False
ALLOWED_HOSTS=ec2-3-101-33-120.us-west-1.compute.amazonaws.com,localhost,127.0.0.1
DATABASE_URL=postgresql://reception_user:tu_password@localhost:5432/reception_platform
OPENAI_API_KEY=tu_openai_api_key
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
CORS_ALLOWED_ORIGINS=https://ec2-3-101-33-120.us-west-1.compute.amazonaws.com
```

```bash
cd /var/www/reception-platform/frontend

# Crear archivo .env
nano .env
```

Agregar:

```env
VITE_API_URL=https://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/api
VITE_WS_URL=wss://ec2-3-101-33-120.us-west-1.compute.amazonaws.com/ws
```

### 3. Ejecutar Despliegue

```bash
cd /var/www/reception-platform
chmod +x deployment/deploy.sh
sudo ./deployment/deploy.sh
```

### 4. Verificar Servicios

```bash
# Verificar estado de Gunicorn
sudo systemctl status reception-platform

# Verificar estado de Nginx
sudo systemctl status nginx

# Ver logs de la aplicación
sudo journalctl -u reception-platform -f
```

### 5. Configurar SSL (Opcional pero Recomendado)

```bash
# Instalar Certbot
sudo apt-get install certbot python3-certbot-nginx

# Obtener certificado SSL
sudo certbot --nginx -d ec2-3-101-33-120.us-west-1.compute.amazonaws.com

# Renovación automática
sudo certbot renew --dry-run
```

Después de obtener el certificado, editar `deployment/nginx.conf` y descomentar la sección HTTPS.

## Estructura del Proyecto

```
pruebas/
├── backend/                 # Aplicación Django
│   ├── reception_platform/  # Configuración del proyecto
│   ├── chatbot/             # App del chatbot
│   ├── chat/                # App de chat en vivo (WebSocket)
│   ├── conversations/       # App de historial
│   └── manage.py
├── frontend/                # Aplicación React
│   ├── src/
│   │   ├── components/      # Componentes React
│   │   ├── services/        # Servicios API
│   │   ├── hooks/           # Custom hooks
│   │   └── App.tsx
│   └── package.json
├── deployment/              # Scripts de despliegue
│   ├── deploy.sh
│   ├── install.sh
│   ├── nginx.conf
│   └── gunicorn_config.py
└── requirements.txt
```

## API Endpoints

### Chatbot
- `POST /api/chatbot/message/` - Enviar mensaje al chatbot

### Conversaciones
- `GET /api/conversations/` - Listar conversaciones
- `GET /api/conversations/<id>/` - Detalle de conversación
- `GET /api/conversations/<id>/messages/` - Mensajes de una conversación

### WebSocket
- `ws://host/ws/chat/<room_id>/` - Conexión WebSocket para chat en vivo

## Uso

### Modo Chatbot
1. Selecciona el botón "Chatbot" en la interfaz
2. Escribe tu mensaje y presiona Enter o haz clic en "Enviar"
3. El chatbot responderá usando OpenAI

### Modo Chat con Asesor
1. Selecciona el botón "Hablar con Asesor" en la interfaz
2. Se establecerá una conexión WebSocket
3. Escribe tu mensaje y espera a que un asesor se conecte
4. Los mensajes se sincronizan en tiempo real

## Mantenimiento

### Actualizar Código

```bash
# En el servidor
cd /var/www/reception-platform
git pull origin main  # O subir archivos nuevos

# Reconstruir frontend
cd frontend
npm install
npm run build

# Reiniciar servicios
sudo systemctl restart reception-platform
sudo systemctl restart nginx
```

### Ver Logs

```bash
# Logs de la aplicación
sudo journalctl -u reception-platform -f

# Logs de Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Backup de Base de Datos

```bash
# Backup
pg_dump -U reception_user reception_platform > backup_$(date +%Y%m%d).sql

# Restaurar
psql -U reception_user reception_platform < backup_YYYYMMDD.sql
```

## Solución de Problemas

### El servidor no responde
- Verificar que Gunicorn esté corriendo: `sudo systemctl status reception-platform`
- Verificar que Nginx esté corriendo: `sudo systemctl status nginx`
- Revisar logs: `sudo journalctl -u reception-platform -n 50`

### WebSocket no funciona
- Verificar que Redis esté corriendo: `sudo systemctl status redis-server`
- Verificar configuración de Nginx para WebSocket
- Revisar que el puerto 80/443 esté abierto en el firewall

### Error de conexión a la base de datos
- Verificar que PostgreSQL esté corriendo: `sudo systemctl status postgresql`
- Verificar credenciales en `.env`
- Verificar que la base de datos exista: `sudo -u postgres psql -l`

## Desarrollo

### Ejecutar Tests

```bash
cd backend
python manage.py test
```

### Crear Migraciones

```bash
cd backend
python manage.py makemigrations
python manage.py migrate
```

## Licencia

Este proyecto es privado y de uso interno.

## Soporte

Para problemas o preguntas, contactar al equipo de desarrollo.

#   p r u e b a s  
 