# 💾 Windows Backup Script

Sistema de respaldo automático incremental para Windows que protege tus archivos importantes de manera eficiente.

## ✨ Características

- 🔄 **Backup incremental** - Solo copia archivos nuevos o modificados
- 📁 **Respaldo completo** - Escritorio, Documentos, Imágenes, Videos, Música, Descargas y más
- 📊 **Logs automáticos** - Registro detallado de cada operación
- ⚡ **Optimizado** - Ahorra tiempo y espacio en ejecuciones posteriores
- ⏰ **Automatizable** - Compatible con el Programador de Tareas de Windows

## 🚀 Inicio Rápido

### 1. Configuración

Edita estas variables al inicio del script:

```powershell
$DiscoDestino = "E:"              # Letra de tu disco HDD
$NombreCarpetaBackup = "Backup001" # Nombre de la carpeta destino
```

### 2. Habilitar ejecución

Abre PowerShell como Administrador:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Ejecutar

```powershell
.\backup.ps1
```

O simplemente: **Clic derecho** → **Ejecutar con PowerShell**.

### Si no te funcion usa: 

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Brian\Desktop\backup.ps1"
```


## 📁 Carpetas Respaldadas

- 📄 Documentos
- 🖼️ Imágenes  
- 🎬 Videos
- 🎵 Música
- ⬇️ Descargas
- 🖥️ Escritorio
- 🎨 Objetos 3D
- ⭐ Favoritos
- 🔗 Enlaces

## ⏰ Automatización (Opcional)

Para backup automático semanal (ej: Domingos 11:59 PM):

1. Abre **Programador de Tareas** (`Win + R` → `taskschd.msc`)
2. **Crear tarea básica**
3. Configurar:
   - **Desencadenador**: Semanal → Domingo → 23:59
   - **Acción**: Iniciar programa
   - **Programa**: `powershell.exe`
   - **Argumentos**: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\ruta\backup.ps1"`

## 🔄 ¿Cómo funciona el Backup Incremental?

```
Primera ejecución:
└── Copia TODO (35 GB) → 2 horas

Segunda ejecución (una semana después):
└── Solo archivos nuevos/modificados (565 MB) → 5 minutos ⚡
```

Cada backup posterior solo copia lo que cambió, ahorrando tiempo y espacio.

## 📊 Logs

Los logs se guardan automáticamente en:
```
E:\Backup001\backup_log_YYYY-MM-DD_HH-mm-ss.txt
```

## 🔧 Solución de Problemas

| Problema | Solución |
|----------|----------|
| Error: "No se puede ejecutar scripts" | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Error: "Acceso denegado" | Ejecutar PowerShell como Administrador |
| Disco lleno | Libera espacio o usa un disco más grande |
| Tarea programada no funciona | Verifica que el disco esté conectado y la ruta sea correcta |

## ⚙️ Requisitos

- Windows 10/11
- PowerShell 5.1+ (incluido por defecto)
- Disco externo o secundario con espacio suficiente

## 📝 Licencia

Uso libre. Modifica y distribuye según tus necesidades.

---

**💡 Tip**: El script NO elimina archivos del backup si los borras del origen, protegiendo contra eliminaciones accidentales.
