# ========================================
# SCRIPT DE BACKUP AUTOMATICO COMPLETO
# ========================================

# CONFIGURACION - MODIFICA ESTAS VARIABLES
$DiscoDestino = "D:"  # Cambia por la letra de tu disco HDD (E:, F:, D:, etc.)
$NombreCarpetaBackup = "Backup001"

# ========================================
# NO MODIFICAR A PARTIR DE AQUI
# ========================================

# Obtener el usuario actual
$Usuario = $env:USERNAME

# Ruta completa de destino
$RutaDestino = Join-Path $DiscoDestino $NombreCarpetaBackup

# Crear carpeta de backup si no existe
if (!(Test-Path $RutaDestino)) {
    New-Item -ItemType Directory -Path $RutaDestino -Force | Out-Null
    Write-Host "Carpeta de backup creada: $RutaDestino" -ForegroundColor Green
} else {
    Write-Host "Usando carpeta existente: $RutaDestino" -ForegroundColor Yellow
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

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INICIANDO BACKUP COMPLETO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usuario: $Usuario" -ForegroundColor White
Write-Host "Destino: $RutaDestino" -ForegroundColor White
Write-Host ""

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
            $resultado = robocopy "$Origen" "$Destino" /E /XO /R:3 /W:5 /NFL /NDL /NP
            
            if ($LASTEXITCODE -lt 8) {
                Write-Host "  Completado: $($Carpeta.Nombre)" -ForegroundColor Green
                $CarpetasExitosas++
            } else {
                Write-Host "  Advertencia en: $($Carpeta.Nombre)" -ForegroundColor Yellow
                $CarpetasExitosas++
            }
        }
        catch {
            Write-Host "  Error al copiar: $($Carpeta.Nombre)" -ForegroundColor Red
            Write-Host "    Detalle: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  No existe: $($Carpeta.Nombre)" -ForegroundColor DarkGray
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
Total de carpetas procesadas: $TotalCarpetas
Copias exitosas: $CarpetasExitosas
Carpetas omitidas (no existen): $CarpetasOmitidas

CARPETAS RESPALDADAS:
"@

foreach ($Carpeta in $CarpetasARespaldar) {
    if (Test-Path $Carpeta.Ruta) {
        $LogContenido += "`n[OK] $($Carpeta.Nombre) - $($Carpeta.Ruta)"
    } else {
        $LogContenido += "`n[NO EXISTE] $($Carpeta.Nombre)"
    }
}

$LogContenido | Out-File -FilePath $ArchivoLog -Encoding UTF8

# Resumen final
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BACKUP COMPLETADO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Carpetas exitosas: $CarpetasExitosas/$TotalCarpetas" -ForegroundColor Green
Write-Host "Carpetas omitidas: $CarpetasOmitidas" -ForegroundColor Yellow
Write-Host ""
Write-Host "Log guardado en: $ArchivoLog" -ForegroundColor White
Write-Host ""
Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
