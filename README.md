# 💾 Windows Backup Script Utility

Herramienta profesional de backup automatizado para Windows con detección inteligente de discos externos, numeración automática y exclusiones configurables.

## ✨ Características

- 🔍 **Detección automática de discos externos** - Identifica y selecciona dispositivos USB/HDD automáticamente
- 🔢 **Numeración inteligente** - Crea backups con formato `NOMBREPC_Backup001`, `NOMBREPC_Backup002` sin sobrescribir
- 🚀 **Copia multi-thread** - Utiliza robocopy con 8 hilos para máxima velocidad
- 🎯 **Exclusiones inteligentes** - Omite automáticamente `node_modules`, `.git`, archivos temporales y carpetas innecesarias
- 📊 **Logs detallados** - Genera registros con fecha, hora y estadísticas completas
- 🎨 **Interfaz visual** - Códigos de color y símbolos para seguimiento del progreso
- ✅ **Seguro** - Nunca sobrescribe backups anteriores, valida espacio disponible

## 📋 Requisitos

- Windows 10/11 o Windows Server 2016+
- PowerShell 5.1+ (incluido por defecto)
- Permisos de administrador
- Disco externo para almacenar backups

## 🚀 Uso

1. Conecta tu disco externo (USB, HDD externo, etc.)

2. Abre PowerShell como Administrador:
   - Presiona `Win + X` → Selecciona "Windows PowerShell (Admin)"

3. Navega a la ubicación del script y ejecútalo:
   ```powershell
   cd C:\ruta\del\script
   .\backup.ps1
   ```

4. El script:
   - Detectará automáticamente discos externos
   - Mostrará información detallada (modelo, capacidad, espacio libre)
   - Seleccionará automáticamente si solo hay un disco externo
   - Te pedirá confirmación antes de iniciar

## 📁 Carpetas Respaldadas

Por defecto, el script respalda estas carpetas del usuario actual:

- 📂 Escritorio (Desktop)
- 📄 Documentos (Documents)
- 🖼️ Imágenes (Pictures)
- 🎬 Videos
- 🎵 Música (Music)
- ⬇️ Descargas (Downloads)
- ⭐ Favoritos (Favorites)

## 🚫 Exclusiones Automáticas

### Carpetas excluidas

- `node_modules`, `bower_components`, `vendor` - Dependencias de proyectos (npm, bower, composer)
- `.git`, `.svn` - Repositorios de control de versiones
- `.vscode`, `.idea` - Configuraciones de IDEs
- `__pycache__`, `.next`, `.nuxt` - Caches de frameworks
- `dist`, `build`, `target`, `bin`, `obj` - Carpetas de compilación

### Archivos excluidos

- `*.tmp`, `*.temp` - Archivos temporales
- `*.cache` - Archivos de caché
- `Thumbs.db` - Miniaturas de Windows
- `.DS_Store` - Archivos de macOS

## 📁 Estructura Generada

```
D:\                                    (Disco Externo)
├── DESKTOP_Backup001/
│   ├── Escritorio/
│   ├── Documentos/
│   ├── Imagenes/
│   ├── Videos/
│   ├── Musica/
│   ├── Descargas/
│   ├── Favoritos/
│   └── backup_log_2025-09-29_14-30-15.txt
│
├── DESKTOP_Backup002/
│   └── ...
│
└── LAPTOP_Backup003/                 (Otra computadora)
    └── ...
```

## ⚙️ Personalización

### Modificar carpetas a respaldar

Edita la sección `$FoldersToBackup` en el script (línea ~290):

```powershell
$FoldersToBackup = @(
    @{Name="Escritorio"; Path="$env:USERPROFILE\Desktop"},
    @{Name="MiCarpeta"; Path="C:\MiCarpeta"}  # Agregar más aquí
)
```

### Modificar exclusiones

Edita las variables al inicio del script (líneas 10-35):

```powershell
$CARPETAS_EXCLUIDAS = @(
    "node_modules",
    ".git"
    # Agregar más...
)

$EXTENSIONES_EXCLUIDAS = @(
    "*.tmp",
    "*.cache"
    # Agregar más...
)
```

## 🔧 Solución de Problemas

### Error: "No se puede ejecutar scripts"

```powershell
# Opción 1: Bypass temporal
powershell -ExecutionPolicy Bypass -File .\backup_universal.ps1

# Opción 2: Cambiar política permanentemente (como admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error: "Requiere privilegios de administrador"

Ejecuta PowerShell como Administrador:
- Click derecho en PowerShell → "Ejecutar como administrador"

### Error: "No se encontraron discos externos"

- Verifica que el disco esté conectado y visible en "Este equipo"
- Si es un disco nuevo, formatealo primero (NTFS recomendado)
- Reconecta el disco y vuelve a ejecutar

### Backup lento

- Usa puerto USB 3.0 (no 2.0) para mejor velocidad
- El primer backup es más lento (copia todo), los siguientes son más rápidos
- Cierra programas que puedan estar usando archivos

### Advertencias durante backup

Es normal ver advertencias por archivos en uso o con permisos especiales. El script:
- Reintenta automáticamente (1 vez)
- Omite archivos problemáticos sin detener el proceso
- Registra todo en el log para revisión

## 💡 Ejemplos

### Ejemplo 1: Un solo disco externo

```
Detectando discos externos...

[1] D:\ - MiBackup
    Modelo: SAMSUNG HD154UI
    Conexión: USB | Tipo: HDD
    Tamaño Total: 1500.30 GB
    Espacio Libre: 1398.02 GB (93.2% disponible)
    ✓ DISCO EXTERNO DETECTADO

✓ Se detectó un solo disco externo. Seleccionándolo automáticamente...

Se creará el nuevo backup:
  → DESKTOP_Backup001
```

### Ejemplo 2: Múltiples discos

```
[1] D:\ - USB_32GB
    Espacio Libre: 15.5 GB
    ✓ DISCO EXTERNO DETECTADO

[2] E:\ - HDD_2TB
    Espacio Libre: 1500.00 GB
    ✓ DISCO EXTERNO DETECTADO

Selecciona el disco para el backup (1-2) o 'Q' para salir: 2
```

### Ejemplo 3: Backups existentes

```
Backups existentes en este disco:
────────────────────────────────────────────
  • DESKTOP_Backup001 - 28/09/2025 10:00 [ESTA PC]
  • DESKTOP_Backup002 - 29/09/2025 21:08 [ESTA PC]
  • LAPTOP_Backup003 - 30/09/2025 14:30
────────────────────────────────────────────

Se creará el nuevo backup:
  → DESKTOP_Backup004
```

## 🤝 Contribuir

Las contribuciones son bienvenidas:

1. Fork el proyecto
2. Crea un branch (`git checkout -b feature/nueva-feature`)
3. Commit cambios (`git commit -m 'Añade nueva feature'`)
4. Push al branch (`git push origin feature/nueva-feature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver [LICENSE](LICENSE) para más detalles.

## 🔗 Enlaces

- [Documentación PowerShell](https://docs.microsoft.com/powershell/)
- [Robocopy Docs](https://docs.microsoft.com/windows-server/administration/windows-commands/robocopy)

---

**⭐ Si te resulta útil, dale una estrella al repositorio**
