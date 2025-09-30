# Backup PowerShell Script

Este repositorio contiene un script de **PowerShell** para realizar backups completos de los perfiles de usuario de Windows hacia un disco externo (USB, SSD, HDD). El script crea carpetas de destino con nomenclatura **`<NombreEquipo>_backupXXX`**, detecta automáticamente unidades externas y genera un log detallado del proceso.

---

## 📌 Funcionalidades

- Detecta discos externos conectados (USB, SSD, HDD), incluso si Windows los considera fijos.  
- Si hay más de un disco externo, permite seleccionar manualmente el destino.  
- Respaldos secuenciales evitando sobreescribir backups previos: `_backup001`, `_backup002`, etc.  
- Incluye las carpetas comunes de cada usuario:  
  - Desktop  
  - Documents  
  - Downloads  
  - Music  
  - Pictures  
  - Videos  
  - Favorites  
  - Contacts  
  - Links  
  - Saved Games  
  - Searches  
  - 3D Objects  
- Copia **todos los tipos de archivos**: MP3, MP4, PDF, DOCX, XLSX, CSV, VMs, SVG, EXCALIDRAW, etc.  
- Genera un **log** con estado de cada carpeta respaldada (`OK`, `ERROR` o `SKIP`).  

---

## 💻 Requisitos

- Windows 10 / 11  
- PowerShell 5.1 o superior  
- Permisos de administrador (para acceder a todos los perfiles de usuario)  
- Disco externo conectado con suficiente espacio  

---

## 📂 Uso

1. Abrir **PowerShell como administrador**:
   - Pulsar `Inicio` → escribir `PowerShell` → clic derecho → **Ejecutar como administrador**  

2. Cambiar al directorio donde se encuentra el script (normalmente el Escritorio):
   ```powershell
   cd $env:USERPROFILE\Desktop
````

3. Ejecutar el script con permisos:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\backup.ps1
   ```

4. El script detectará automáticamente la unidad externa:

   * Si hay **una sola unidad**, la usa automáticamente.
   * Si hay **varias unidades**, pedirá que selecciones el disco de destino.

5. Durante la ejecución, PowerShell mostrará:

   * Qué usuario y carpeta se están respaldando
   * Si se completó correctamente (`OK`) o si hubo errores

6. Al finalizar, se generará un archivo **`backup_log.txt`** dentro de la carpeta de respaldo con todos los detalles.

---

## 📦 Estructura de la carpeta de backup

```
<DiscoExterno>:\<NombreEquipo>_backup001\
├── Usuario1\
│   ├── Desktop\
│   ├── Documents\
│   └── ...
├── Usuario2\
│   ├── Desktop\
│   ├── Documents\
│   └── ...
└── backup_log.txt
```

---

## ⚠️ Notas importantes

* El script no respalda la unidad C:\ directamente, solo los perfiles de usuario.
* Asegúrate de que el archivo se llame **`backup.ps1`** y no tenga extensión oculta `.txt`.
* Guardar siempre el archivo con codificación **UTF-8** para evitar errores de caracteres.

---

## 📝 Contribuciones

Si deseas mejorar el script o añadir funcionalidades, por favor haz un fork y crea un pull request.

---

## 📜 Licencia

Este proyecto está bajo la licencia MIT. Puedes usarlo y modificarlo libremente.

```

---

Si quieres, puedo también crear un **README más visual con emojis y secciones de “Tips”** para que quede **estilo GitHub profesional y moderno**.  

¿Quieres que haga esa versión también?
```
