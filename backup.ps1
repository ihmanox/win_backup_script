# ========================================
# SCRIPT DE BACKUP AUTOMÁTICO COMPLETO
# ========================================

# CONFIGURACIÓN - MODIFICA ESTAS VARIABLES
$DiscoDestino = "E:"  # Cambia por la letra de tu disco HDD (E:, F:, D:, etc.)
$NombreCarpetaBackup = "Backup001"

# ========================================
# NO MODIFICAR A PARTIR DE AQUÍ
# ========================================

# Obtener el usuario actual
$Usuario = $env:USERNAME

# Ruta completa de destino
$RutaDestino = Join-Path $DiscoDestino $NombreCarpetaBackup

# Crear carpeta de backup si no existe
if (!(Test-Path $RutaDestino)) {
    New-Item -ItemType Directory -Path $RutaDestino -Force | Out-Null
    Write-Host "✓ Carpeta de backup creada: $RutaDestino" -ForegroundColor Green
} else {
    Write-Host "✓ Usando carpeta existente: $RutaDestino" -ForegroundColor Yellow
}

# Definir carpetas a respaldar
$CarpetasARespaldar = @(
    @{Nombre="Escritorio"; Ruta="$env:USERPROFILE\Desktop"},
    @{Nombre="Documentos"; Ruta="$env:USERPROFILE\Documents"},
    @{Nombre="Imagenes"; Ruta="$env:USERPROFILE\Pictures"},
    @{Nombre="Videos"; Ruta="$env:USERPROFILE\Videos"},
    @{Nombre="Musica"; Ruta="$env:USERPROFILE\Music"},
    @{Nombre="Descargas"; Ruta="$env:USERPROFILE\Downloads"},
    @{Nombre="Objetos3D"; Ruta="$env:USERPROFILE\3D Objects"},
    @{Nombre="Favoritos"; Ruta="$env:USERPROFILE\Favorites"},
    @{Nombre="Enlaces"; Ruta="$env:USERPROFILE\Links"}
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  INICIANDO BACKUP COMPLETO" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "Usuario: $Usuario" -ForegroundColor White
Write-Host "Destino: $RutaDestino`n" -ForegroundColor White

$TotalCarpetas = 0
$CarpetasExitosas = 0
$CarpetasOmitidas = 0

foreach ($Carpeta in $CarpetasARespaldar) {
    $TotalCarpetas++
    $Origen = $Carpeta.Ruta
    $Destino = Join-Path $RutaDestino $Carpeta.Nombre
    
    Write-Host "[$TotalCarpetas/$($CarpetasARespaldar.Count)] Procesando: $($Carpeta.Nombre)" -ForegroundColor Cyan
    
    if (Test-Path $Origen) {
        try {
            # Usar robocopy para copiar (más eficiente y robusto)
            # /E = copia subdirectorios incluidos vacíos
            # /XO = excluye archivos más antiguos
            # /R:3 = reintentos en caso de error
            # /W:5 = tiempo de espera entre reintentos
            # /NFL = no muestra lista de archivos
            # /NDL = no muestra lista de directorios
            # /NP = no muestra progreso de porcentaje
            
            $resultado = robocopy "$Origen" "$Destino" /E /XO /R:3 /W:5 /NFL /NDL /NP
            
            # Robocopy devuelve códigos: 0-7 son exitosos, 8+ son errores
            if ($LASTEXITCODE -lt 8) {
                Write-Host "  ✓ Completado: $($Carpeta.Nombre)" -ForegroundColor Green
                $CarpetasExitosas++
            } else {
                Write-Host "  ⚠ Advertencia en: $($Carpeta.Nombre)" -ForegroundColor Yellow
                $CarpetasExitosas++
            }
        }
        catch {
            Write-Host "  ✗ Error al copiar: $($Carpeta.Nombre)" -ForegroundColor Red
            Write-Host "    Detalle: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⊘ No existe: $($Carpeta.Nombre)" -ForegroundColor DarkGray
        $CarpetasOmitidas++
    }
    Write-Host ""
}

# Crear archivo de registro con fecha y hora
$FechaHora = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ArchivoLog = Join-Path $RutaDestino "backup_log_$FechaHora.txt"

$LogContenido = @"
========================================
REGISTRO DE BACKUP
========================================
Fecha: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Usuario: $Usuario
Destino: $RutaDestino

RESUMEN:
- Total de carpetas procesadas: $TotalCarpetas
- Copias exitosas: $CarpetasExitosas
- Carpetas omitidas (no existen): $CarpetasOmitidas

CARPETAS RESPALDADAS:
"@

foreach ($Carpeta in $CarpetasARespaldar) {
    if (Test-Path $Carpeta.Ruta) {
        $LogContenido += "`n✓ $($Carpeta.Nombre) - $($Carpeta.Ruta)"
    } else {
        $LogContenido += "`n⊘ $($Carpeta.Nombre) - NO EXISTE"
    }
}

$LogContenido | Out-File -FilePath $ArchivoLog -Encoding UTF8

# Resumen final
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BACKUP COMPLETADO" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "Carpetas exitosas: $CarpetasExitosas/$TotalCarpetas" -ForegroundColor Green
Write-Host "Carpetas omitidas: $CarpetasOmitidas" -ForegroundColor Yellow
Write-Host "`nLog guardado en: $ArchivoLog" -ForegroundColor White
Write-Host "`nPresiona cualquier tecla para salir..." -ForegroundColor Gray

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
