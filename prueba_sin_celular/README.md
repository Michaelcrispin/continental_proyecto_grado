# PRUEBA SIN CELULAR — Emulador Android con GPS "pilotado"

No necesitas teléfono: Windows trae un emulador Android (`heltastruck`) y los
scripts le **inyectan coordenadas GPS reales** (las del GPX del 5 nov 2026) para
que la app crea que la trufi está conduciendo la ruta Villadela ↔ Teleférico.

> Las coordenadas de las paradas son las mismas de la app
> (`PuntosOficiales`): A `(-16.53454833, -68.191605)` y
> B `(-16.51834167, -68.15143667)`, separadas ~4.65 km en línea (7.15 km por vía).

## Paso 0 — construir la app (una sola vez)

```powershell
flutter build apk --debug
```
(ya está hecha: `build\app\outputs\flutter-apk\app-debug.apk`)

## Paso 1 — instalar y arrancar (abre el emulador con la app adentro)

```powershell
.\prueba_sin_celular\1_instalar_y_arrancar.ps1
```

Instala la APK, concede permisos de ubicación/notificaciones y abre la app.
En la pantalla de Login entra como **conductor** para ver counters y asistencia:

- CI: `6849201` · clave: `Pass1234*`

(ó como superadmin: `superadmin@continental.com` / `super123`; el servicio de
vueltas tomará al primer conductor activo igualmente).

## Paso 2 — PRUEBA RÁPIDA (~35 s) — demuestra los dos errores de una vez

Deja visible en el emulador la pantalla **Asistencia** o **GPS en Vivo**, y corre:

```powershell
.\prueba_sin_celular\2_prueba_rapida_AB.ps1
```

Qué debe aparecer en el emulador:

| Inyección | Resultado esperado |
|---|---|
| (1)(2) cerca y dentro de Parada A | snackbar verde + **asistencia marcada** (regla: registro activo de `punto_de_control`) |
| (3) punto medio A→B | **nada** |
| (4) dentro de Parada B | snackbar ámbar *"Paso por Parada B..."* |
| (5) rebote a 46 m de B | **nada** (histéresis 1.5× anti-rebote) |
| (6) regreso a Parada A | vibración + snackbar verde **"Vuelta #1 completada (A → B → A)"** |

Verificación en la app: pestaña **Vueltas** o **GPS en Vivo → "Vueltas hoy"**
deben pasar de 0 → 1 (y la asistencia aparece en la pantalla Asistencia).

## Paso 3 — PRUEBA DE RUTA COMPLETA (la trufi recorre su GPX real)

```powershell
.\prueba_sin_celular\3_ruta_completa_gpx.ps1          # ~2 min (punto cada ~30 m)
.\prueba_sin_celular\3_ruta_completa_gpx.ps1 -Salto 2 # ~4 min, más ralizado
```

Recorre los **1145 trackpoints reales** de `cordenadas gps\5_nov_2026_...gpx`:
arranca en Villadela, llega a Teleférico (km 7.15) y termina de vuelta en
Villadela → al final debe haber **1 vuelta completa** en el historial y la
asistencia del día marcada.

## Paso a cámara sincronizada (opcional para la defensa)

1. `.\prueba_sin_celular\2_prueba_rapida_AB.ps1` con la pantalla **GPS en Vivo**:
   se ve el auto azul moverse con el rastro + círculos de geocerca.
2. La prueba se grama mejor si antes en *Ruta Oficial* observas el estado
   "Rumbo a Parada B" → "Regresa a Parada A para completar la vuelta" que viste
   del servicio singleton (no de la pantalla): si cierras la app y la reabres a
   mitad de circuito, el estado sigue.

## Consejos

- Reinicia los datos de demo entre corridas: pantalla Asistencia → botón
  reiniciar pruebas del día (borra asistencia/sanciones de hoy).
- Si el emulador se quedó "pegado" en una posición vieja, ciérralo y vuelve a
  correr el Paso 1 (los scripts siempre mandan la posición correcta).
- Execución manual de una sola posición (consola abierta):
  ```powershell
  adb emu geo fix -68.191605 -16.53454833 4000 8
  ```
