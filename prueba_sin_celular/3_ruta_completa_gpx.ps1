# ============================================================================
# PRUEBA DE RUTA COMPLETA REAL (~2-3 min): recorre el GPX completo del
# 5 Nov 2026 (1145 puntos reales grabados por la trufi) sobre el emulador.
# La app debe: marcar asistencia en Villadela (inicio), registrar el paso por
# Teleférico (km 7.15) y CERRAR la vuelta cuando el GPX regresa a Villadela.
#
# Uso:  .\prueba_sin_celular\3_ruta_completa_gpx.ps1          (rápido)
#       .\prueba_sin_celular\3_ruta_completa_gpx.ps1 -Salto 2  (más detallado)
# ============================================================================
[CmdletBinding()]
param(
  [int]$Salto = 5,         # cada N puntos del GPX se inyecta uno (5 => ~2.3 min)
  [int]$DelayMs = 300      # pausa entre inyecciones
)
$ErrorActionPreference = 'Stop'
$ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$GPX = "$PSScriptRoot\..\cordenadas gps\5_nov_2026,_14_30_16.gpx"

$deviceLinea = ((& $ADB devices) -split "`r?`n") | Where-Object { $_ -match 'emulator-\d+' } | Select-Object -First 1
if (-not $deviceLinea) { throw 'Emulador no detectado. Ejecuta 1_instalar_y_arrancar.ps1 primero.' }
$serial = $deviceLinea.Trim().Split("`t")[0]
$INV = [System.Globalization.CultureInfo]::InvariantCulture

if (-not (Test-Path $GPX)) { throw "No se encontro el GPX: $GPX" }
$contenido = Get-Content $GPX -Raw
$puntos = [regex]::Matches($contenido, '<trkpt lat="(-?[0-9.]+)" lon="(-?[0-9.]+)"')
if ($puntos.Count -lt 10) { throw 'No se pudieron leer los trackpoints del GPX' }

Write-Host "== RUTA REAL COMPLETA: $($puntos.Count) puntos, inyectando 1 de cada $Salto =="
$estimado = [math]::Round($puntos.Count / $Salto * $DelayMs / 1000)
Write-Host   "  Duracion estimada: $estimado s"

$enviados = 0
for ($i = 0; $i -lt $puntos.Count; $i += $Salto) {
    $lat = [double]$puntos[$i].Groups[1].Value
    $lon = [double]$puntos[$i].Groups[2].Value
    $lonTxt = $lon.ToString('G6', $INV)
    $latTxt = $lat.ToString('G6', $INV)

    & $ADB -s $serial emu geo fix $lonTxt $latTxt 4050 8 | Out-Null

    $enviados++
    if ($enviados % 10 -eq 0) {
        $pct = [math]::Round(100.0 * $i / $puntos.Count)
        Write-Progress -Activity 'Inyectando ruta GPX real' -Status "$i de $($puntos.Count) puntos" -PercentComplete $pct
    }
    Start-Sleep -Milliseconds $DelayMs
}
Write-Progress -Activity 'Inyectando ruta GPX real' -Completed

Write-Host "`n=== RUTA COMPLETA INYECTADA ($enviados puntos) ==="
Write-Host ' El GPX empieza y termina en Villadela, pasa por Telefonico en el km 7.15:'
Write-Host '   - asistencia marcada en el arranque'
Write-Host '   - paso por Parada B al llegar a Telefonico'
Write-Host '   - vuelta #1 completada al final del GPX'
