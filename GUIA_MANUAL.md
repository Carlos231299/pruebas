# Guía Manual para Subir Código a GitHub

## ✅ Estado Actual

- ✅ Clave SSH generada correctamente: `id_ed25519`
- ✅ Clave pública agregada a GitHub (autenticación exitosa)
- ✅ Repositorio remoto: `git@github.com:Carlos231299/pruebas.git`

## Pasos para Subir el Código

### Paso 1: Verificar el estado del repositorio

```bash
git status
```

**¿Qué hace?** Muestra qué archivos han cambiado y cuáles están listos para commit.

**Qué esperar ver:**
- Archivos en rojo = sin agregar al staging
- Archivos en verde = agregados y listos para commit
- Si dice "nothing to commit" = ya todo está commiteado

---

### Paso 2: Agregar archivos al staging

```bash
git add .
```

**¿Qué hace?** Agrega TODOS los archivos de la carpeta actual al "staging area" (área de preparación). El punto (`.`) significa "todos los archivos".

**Alternativas:**
- `git add archivo.txt` - Agregar un archivo específico
- `git add backend/` - Agregar una carpeta específica
- `git add .` - Agregar todo (lo que usaremos)

---

### Paso 3: Verificar qué se agregó

```bash
git status
```

**¿Qué hace?** Verifica que los archivos se agregaron correctamente al staging.

**Qué esperar:** Los archivos ahora deberían aparecer en verde (staged).

---

### Paso 4: Crear un commit

```bash
git commit -m "Initial commit: Plataforma de recepción de clientes"
```

**¿Qué hace?** Crea un "snapshot" (fotografía) del estado actual de tu código con un mensaje descriptivo.

**Partes del comando:**
- `git commit` - Crea el commit
- `-m "mensaje"` - Agrega un mensaje descriptivo
- El mensaje debe ser claro y describir qué cambios incluye

**Buenos mensajes de commit:**
- "Initial commit: Plataforma de recepción de clientes"
- "Agregar funcionalidad de chatbot"
- "Corregir error en conexión WebSocket"

---

### Paso 5: Verificar que el commit se creó

```bash
git log --oneline
```

**¿Qué hace?** Muestra el historial de commits (deberías ver tu commit recién creado).

**Qué esperar:** Verás algo como:
```
abc1234 Initial commit: Plataforma de recepción de clientes
```

---

### Paso 6: Asegurar que estás en la rama main

```bash
git branch
```

**¿Qué hace?** Muestra en qué rama estás. La rama actual tiene un asterisco (*).

**Si no estás en main:**
```bash
git branch -M main
```

**¿Qué hace?** Renombra la rama actual a "main" (o la crea si no existe).

---

### Paso 7: Verificar el remoto

```bash
git remote -v
```

**¿Qué hace?** Muestra la URL del repositorio remoto configurado.

**Qué esperar ver:**
```
origin  git@github.com:Carlos231299/pruebas.git (fetch)
origin  git@github.com:Carlos231299/pruebas.git (push)
```

**Si no aparece nada o está mal:**
```bash
git remote remove origin
git remote add origin git@github.com:Carlos231299/pruebas.git
```

---

### Paso 8: Subir el código (PUSH)

```bash
git push -u origin main
```

**¿Qué hace?** Sube tus commits locales al repositorio remoto en GitHub.

**Partes del comando:**
- `git push` - Comando para subir
- `-u` - Establece el "upstream" (relación entre rama local y remota)
- `origin` - Nombre del remoto (por defecto es "origin")
- `main` - Nombre de la rama a subir

**Qué esperar:**
- Si es la primera vez, verás algo como "Enumerating objects..." y luego "Writing objects..."
- Al final: "Branch 'main' set up to track remote branch 'main' from 'origin'"

---

## Comandos Útiles para el Futuro

### Ver qué cambió desde el último commit
```bash
git diff
```

### Ver el historial completo
```bash
git log
```

### Ver el historial resumido
```bash
git log --oneline --graph
```

### Deshacer cambios en un archivo (antes de hacer add)
```bash
git checkout -- archivo.txt
```

### Deshacer el último commit (manteniendo los cambios)
```bash
git reset --soft HEAD~1
```

### Ver qué archivos están siendo rastreados
```bash
git ls-files
```

---

## Flujo de Trabajo Típico

Cuando hagas cambios en el futuro:

1. **Hacer cambios** en tus archivos
2. `git status` - Ver qué cambió
3. `git add .` - Agregar cambios
4. `git commit -m "Descripción de los cambios"` - Crear commit
5. `git push` - Subir cambios (ya no necesitas `-u origin main` después de la primera vez)

---

## Solución de Problemas

### Error: "nothing to commit"
**Causa:** No hay cambios nuevos
**Solución:** Haz algunos cambios en los archivos primero

### Error: "fatal: not a git repository"
**Causa:** No estás en una carpeta con Git inicializado
**Solución:** `git init` (solo la primera vez)

### Error: "failed to push some refs"
**Causa:** El repositorio remoto tiene cambios que no tienes localmente
**Solución:** `git pull origin main` primero, luego `git push`

### Error: "permission denied"
**Causa:** Problema con SSH
**Solución:** Verifica con `ssh -T git@github.com`

---

## Notas Importantes

1. **Siempre verifica con `git status`** antes de hacer commit
2. **Los mensajes de commit deben ser descriptivos** - te ayudarán en el futuro
3. **Haz commits frecuentes** - es mejor muchos commits pequeños que uno grande
4. **Nunca hagas commit de archivos sensibles** (contraseñas, keys, etc.) - están en `.gitignore`

