# ============================================================================
# INSTALA Y ARRANCA Continental en el emulador Android (sin celular)
# Uso:  .\prueba_sin_celular\1_instalar_y_arrancar.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
$ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$APK = "$PSScriptRoot\..\build\app\outputs\flutter-apk\app-debug.apk"
$EMU = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
$AVD = 'heltastruck'

function Adb($args) { & $ADB $args }

if (-not (Test-Path $ADB)) { throw "No se encontro adb en $ADB (instala Android SDK platform-tools)" }
if (-not (Test-Path $APK)) { throw "No se encontro la APK. Compila primero:  flutter build apk --debug" }

# 1. Emulador corriendo?
$dispositivos = (Adb devices) -join "`n"
if ($dispositivos -notmatch 'emulator-\d+') {
    Write-Host '-> Lanzando el emulador heltastruck...'
    Start-Process -FilePath $EMU -ArgumentList "-avd $AVD -no-snapshot-load" -WindowStyle Minimized
}

# 2. Esperar a que adb vea el dispositivo y el sistema arranque
Write-Host '-> Esperando el dispositivo (arranque del Android) ...'
$intentos = 0
do {
    Start-Sleep -Seconds 4
    $intentos++
    $dispositivos = (Adb devices) -join "`n"
} while ($dispositivos -notmatch 'emulator-\d+' -and $intentos -lt 60)
$serial = (($dispositivos -split "`n") | Where-Object { $_ -match 'emulator-\d+' })[0].Trim().Split("`t")[0]
Write-Host "   Dispositivo: $serial"

Adb wait-for-device
do { $sys = (Adb -s $serial shell getprop sys.boot_completed).Trim() } while ($sys -ne '1' -and ($intentos++ -lt 90))
Write-Host '-> Android iniciado.'

# 3. Instalar la APK
Write-Host '-> Instalando app-debug.apk ...'
Adb -s $serial install -r -t $APK
if ($LASTEXITCODE -ne 0) { throw 'Fallo la instalacion de la APK' }

# 4. Conceder permisos de runtime (para no tocar el dialogo a mano)
$pkg = 'com.example.continental'
foreach ($perm in @('android.permission.ACCESS_FINE_LOCATION',
                    'android.permission.ACCESS_COARSE_LOCATION',
                    'android.permission.POST_NOTIFICATIONS')) {
    Adb -s $serial shell pm grant $pkg $perm 2>$null | Out-Null
}
Write-Host '-> Permisos de ubicacion y notificaciones concedidos.'

# 5. Iniciar la app
Adb -s $serial shell am start -n "$pkg/.MainActivity" | Out-Null
Write-Host "`nAPP LISTA EN EL EMULADOR  →  inicia sesion con distintos perfiles para probar:"
Write-Host '   Conductor:  CI 6849201   clave Pass1234*'
Write-Host '   Superadmin: superadmin@continental.com   clave super123'
