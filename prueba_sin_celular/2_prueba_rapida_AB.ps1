# ============================================================================
# PRUEBA RAPIDA (~35 s): demuestra con inyecciones GPS en el emulador que
#   ERROR 1 → la asistencia se marca al entrar en la geocerca de Villadela
#   ERROR 2 → A → B → A suma UNA vuelta y los rebotes no doble-cuentan
#
# Uso (con la app abierta y sesion iniciada en el emulador):
#   .\prueba_sin_celular\2_prueba_rapida_AB.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
$ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$dispositivos = (& $ADB devices) -join "`n"
if ($dispositivos -notmatch 'emulator-\d+') { throw 'Emulador no detectado. Ejecuta primero 1_instalar_y_arrancar.ps1' }
$serial = (($dispositivos -split "`n") | Where-Object { $_ -match 'emulator-\d+' })[0].Trim().Split("`t")[0]

# Coordenadas OFICIALES (fuente unica PuntosOficiales)
$LAT_A = [decimal]-16.53454833; $LON_A = [decimal]-68.191605
$LAT_B = [decimal]-16.51834167; $LON_B = [decimal]-68.15143667
$INV = [System.Globalization.CultureInfo]::InvariantCulture

function Enviar([decimal]$lat, [decimal]$lon, [string]$etiqueta) {
    $lonTxt = $lon.ToString('G', $INV)
    $latTxt = $lat.ToString('G', $INV)
    Write-Host ("→ GPS $etiqueta :  $latTxt ,  $lonTxt")
    & $ADB -s $serial emu geo fix $lonTxt $latTxt 4000 3 | Out-Null
    Start-Sleep -Seconds 3
}

function Desplazar([decimal]$lat, [decimal]$lon, [double]$metros) {
    # desplaza el punto ~ $metros hacia el noreste (valido < 5000 m)
    $d = [decimal]($metros / 111320)
    return ,@(($lat + $d), ($lon + $d))
}

Write-Host '=== PRUEBA RAPIDA A -> B -> A (emulador) ==='

# 1. Aproximacion y llegada a Parada A
$p = Desplazar $LAT_A $LON_A 60;        Enviar $p[0] $p[1] '(1) a unos 60 m de Parada A'
$p = Desplazar $LAT_A $LON_A 12;        Enviar $p[0] $p[1] '(2) DENTRO de la geocerca de Parada A'

# 2. Tramo A -> B (se salta el kilometraje, solo esta el punto medio)
$MEDIO_LAT = ($LAT_A + $LAT_B) / 2
$MEDIO_LON = ($LON_A + $LON_B) / 2
Enviar $MEDIO_LAT $MEDIO_LON '(3) punto medio del tramo A->B (no debe disparar nada)'

# 3. Parada B
$p = Desplazar $LAT_B $LON_B 12;        Enviar $p[0] $p[1] '(4) DENTRO de la geocerca de Parada B (Teleferico)'

# 4. Rebote al salir de B (46 m, menos que la histeresis 1.5 x 45 = 67.5 m)
$p = Desplazar $LAT_B $LON_B 46;        Enviar $p[0] $p[1] '(5) rebote a 46 m de B (no debe contar dos veces)'

# 5. Regreso a Parada A: ¡VUELTA COMPLETA!
$p = Desplazar $LAT_A $LON_A 12;        Enviar $p[0] $p[1] '(6) REGRESO a Parada A  =>  VUELTA COMPLETADA'

Write-Host "`n=== PROGRAMADO. Que deberia ver en el emulador ==="
Write-Host ' (1-2)  snackbar verde/azul: paso por Parada A + asistencia marcada si el usuario es conductor'
Write-Host ' (3)    NADA'
Write-Host ' (4)    snackbar ambar: paso por Parada B (Teleferico)'
Write-Host ' (5)    NADA (histeresis anti-rebote)'
Write-Host ' (6)    vibracion + snackbar VERDE: VUELTA #1 COMPLETADA + vaya a Vueltas y comprobar el incremento'
