# 🤖 INFORME MAESTRO DEL PROYECTO — Continental Trufi 101 – 127

> **Para qué sirve este archivo:** que una IA (o una persona) lea UN solo documento y entienda
> qué es el proyecto, qué está hecho, qué está a medias, qué falta, qué se habló con el usuario
> y cómo trabajar sin confundirse. Está escrito para lectura rápida: tablas, listas y rutas exactas.
>
> **Última actualización:** 25 oct 2026 · **Rama:** `main` · **Último commit:** `69d2272`
> **Repositorio:** https://github.com/Michaelcrispin/continental_proyecto_grado
> **Documentos hermanos (más detalle):** [docs/plan_objetivos.md](docs/plan_objetivos.md) · [docs/plan_datos_conductor.md](docs/plan_datos_conductor.md)

---

## 0. ⚡ RESUMEN EN 30 SEGUNDOS (TL;DR)

- **Qué es:** app móvil Flutter (Android) para el **Grupo Continental Trufi 101–127** (sindicato de transporte, El Alto, Bolivia). Es el **Proyecto de Grado** del usuario.
- **Qué hace hoy:** login con roles, directorio, conductores con ficha completa (foto, licencia, vehículo, SOAT/RUAT), **control de cuotas** (crear, cobrar, filtrar, informe PDF), asistencia / vueltas / sanciones **manuales**, GPS **solo como mapa estático**.
- **Base de datos:** SQLite **local** (`sqflite`), versión **7**. **No hay nube todavía.**
- **Lo que viene:** módulo **GPS en 7 etapas** (puntos con coordenadas → turno/servicio 2.º plano → asistencia automática → vueltas A→B→A → ruta/desvíos → pantallas supervisor → pruebas en calle + APK).
- **Estado del código:** `flutter analyze` = **0 problemas**. Todo subido a GitHub.
- **Idioma del usuario:** **español**. Escribe informal, a veces en MAYÚSCULAS y con errores de tipeo: interpretar la intención, no el texto literal.
- **Regla de oro:** **no borrar nada sin que el usuario lo pida** (dijo explícitamente "solo analízalo, no borres nada todavía").

---

## 1. 🎯 EL PROYECTO

### 1.1 Objetivo general (texto del usuario, sección 5.1 de su tesis)
> Desarrollar una aplicación móvil para el control de asistencia y gestión operativa de los conductores del Grupo Continental Trufi 101 – 127, que **centralice** la información de registros, vueltas, sanciones y cuotas, apoyando la toma de decisiones acertadas por parte de la directiva del sindicato.

### 1.2 Objetivos específicos (resumen; detalle en `docs/plan_objetivos.md`)
| Obj. | Qué pide | Estado |
|---|---|---|
| **a)** Registro centralizado de conductores | Datos en un solo lugar, sin duplicados | 🟢 ~75% (falta normalizar CI/placa, dar de baja) |
| **b)** Asistencia por GPS | Marcar llegada en Cruce Villadela y Teleférico Amarillo sin papel/biométrico/Excel/WhatsApp | 🔴 ~15% (es manual) |
| **c)** Vueltas por GPS (+ castigo) | Vuelta = Cruce → Teleférico Amarillo → Cruce | 🔴 ~10% (es manual) |
| **d)** Sanciones e informes | Detectar tardanzas, registrar castigos, informes diarios | 🟡 ~30% |
| **e)** Control económico | Cuotas de ayuda, canastón, multas, faltas a reunión, pasanaco: quién pagó, cuánto y por qué | 🟢 ~65% (cuotas sí; reuniones/pasanaco sin conectar) |

### 1.3 Contexto del negocio
- **Puntos de control reales:** **Cruce (Villadela)** = punto A y **Teleférico Amarillo** = punto B.
- **Vuelta completa:** A → B → A. Solo cuenta si pasó por B entre los dos A.
- **Hoy en la vida real:** asistencia en papel / biométrico → Excel → WhatsApp. La app lo reemplaza.
- **Conductores:** 20 trufis (minibuses Toyota Hiace). Nombres, CI, placas, etc. en `lib/services/seed_data.dart`.
- **Actores:** Superadmin, Admin, Supervisor, **Tesorero (Secretario de Hacienda)**, Conductor.

---

## 2. 🧱 STACK Y ENTORNO

| Tema | Valor |
|---|---|
| Framework | Flutter (Dart SDK `^3.12.2`) |
| Plataforma probada | Android (emulador `emulator-5554`), paquete `com.example.continental` |
| BD | SQLite local · archivo `continental.db` · `_dbVersion = 7` |
| Raíz del proyecto | `d:\PROYECTO_GRADO\continental` (workspace padre: `d:\PROYECTO_GRADO`, **sin** git propio) |
| SO / Shell del usuario | Windows + **PowerShell** |
| Git remoto | `origin` → https://github.com/Michaelcrispin/continental_proyecto_grado.git (rama `main`) |

### 2.1 Dependencias (`pubspec.yaml`)
`flutter_map`, `latlong2` · `sqflite`, `path` · `google_fonts` · `uuid`, `crypto` · `shared_preferences` · `image_picker` · `intl` · `pdf`, `printing`, `share_plus` · `fl_chart` · `archive` · `cupertino_icons`.
**NO instaladas aún (necesarias para GPS):** `geolocator`, `permission_handler`, `flutter_foreground_task`.
**NO existe:** `supabase_flutter` / Firebase / `excel`.

### 2.2 Assets
`assets/images/`: `logo.png` (logo del sindicato), `conductor_default.jpg`, `trufi_minibus.jpg`, `icono_auto_al_frente.png`.

### 2.3 AndroidManifest
Hoy **sin permisos de ubicación**. Faltan: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`.

### 2.4 Comandos útiles (Windows/PowerShell)
```powershell
flutter analyze                                   # debe dar "No issues found"
# adb NO está en el PATH; ruta real:
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s emulator-5554 shell "su 0 sqlite3 /data/data/com.example.continental/databases/continental.db 'PRAGMA table_info(cuota);'"
```
> ⚠️ **Trampa de PowerShell:** SQL con comillas simples y tildes (ñ, é) **se rompe** al pasarlo por `adb shell "..."`.
> Solución probada: un script Python que mande el SQL por **stdin** a `sqlite3` (`subprocess.Popen([...,'sqlite3', ruta_db], stdin=PIPE)` + `communicate(sql)`).
> Script existente para volcar la BD: `…\brain\<id>\scratch\dump_from_emulator.py` → genera `d:\PROYECTO_GRADO\continental_dump.sql` (copia también en `continental/continental_dump.sql`).

### 2.5 Credenciales de desarrollo
| Rol | Usuario | Contraseña |
|---|---|---|
| Superadmin | `superadmin@continental.com` | `super123` |
| Conductores (20) | su **CI** como usuario | ver `lib/services/seed_data.dart` (ej.: Juan Carlos Quispe, CI `6849201`, `Pass1234*`) |

> ⚠️ Solo desarrollo. Las contraseñas se guardan hasheadas con `crypto` (`hashPassword`). **Cambiar antes de producción.**

---

## 3. 🗺️ ARQUITECTURA DEL CÓDIGO

```
lib/
├─ main.dart                  → MaterialApp, tema AppTheme.lightTheme, home = SplashScreen
├─ core/
│   ├─ app_theme.dart         → tema y AppColors
│   ├─ permisos.dart          → RBAC: Permisos.puedeVer(rol, modulo) / puedeEditar(rol, modulo)
│   └─ documentos_alerta.dart → estado de vencimiento (SOAT / licencia): vigente / por vencer (30 d) / vencido
├─ services/
│   ├─ database_helper.dart   → SQLite: esquema, migraciones, CRUD genérico, consultas con JOIN, seed
│   ├─ economia_repo.dart     → TODA la lógica de cuotas, pagos, reuniones, pasanaco
│   ├─ recibo_pdf_service.dart→ PDFs (recibo, informe económico, informe de cuotas por conductor)
│   ├─ sesion_service.dart    → sesión (SharedPreferences) y getters de rol
│   └─ seed_data.dart         → los 20 conductores oficiales con vehículo y credenciales
├─ widgets/
│   ├─ app_background.dart    → fondo con logo translúcido
│   ├─ glass_card.dart (GlassCard) → tarjetas estilo vidrio
│   └─ avatar_conductor.dart  → foto o avatar con iniciales si no hay imagen
└─ screens/  (27 pantallas, ver §5)
```

### 3.1 Flujo de arranque
`SplashScreen` → (¿hay sesión guardada?) → `HomeScreen` **o** `LoginScreen`.
Login: staff con **gmail**; conductor con **CI** (el correo es opcional para el conductor).

### 3.2 Navegación (`home_screen.dart`)
- **Barra inferior (4):** Inicio · Asistencias · Vueltas · Cuotas.
- **Menú hamburguesa ☰ (Drawer izquierdo)**, secciones: `NAVEGACIÓN` (Inicio, Asistencias, Vueltas, Cuotas) · `OPERACIONES` (Sanciones, GPS) · `ADMINISTRACIÓN` (Directorio, Conductores, Informes, Panel Técnico) · `MI CUENTA` (Perfil, Cerrar sesión). Cada ítem se muestra según `Permisos`.
- **Tarjetas del Inicio (según rol):**
  - Staff: Asistencia `x / 20 conductores` · Vueltas registradas hoy · Sanciones pendientes · **Cuotas = cantidad de cuotas creadas** (toca → abre Control de Cuotas).
  - Conductor: Mis Sanciones · Mis Cuotas (saldo pendiente en Bs.).
- **Accesos rápidos:** cuadrícula de 3 columnas, filtrada por permisos.

### 3.3 Matriz de permisos REAL (`permisos.dart`)
| Módulo | Ver | Editar |
|---|---|---|
| panel_tecnico | superadmin | superadmin |
| usuarios (Directorio) | superadmin, admin | superadmin, admin |
| conductores | superadmin, admin, **tesorero** | superadmin, admin |
| control_economico | superadmin, admin, conductor, supervisor, tesorero | superadmin, admin, tesorero |
| informes | superadmin, admin, tesorero | superadmin, admin |
| sanciones | todos | superadmin, admin, supervisor |
| asistencia | todos | superadmin, admin, supervisor, **conductor** (solo la suya) |
| vueltas | todos | superadmin, admin, supervisor |
| gps, perfil | todos | gps: nadie edita · perfil: todos |

> ⚠️ **Inconsistencia a corregir:** los comentarios de `permisos.dart` dicen que el supervisor NO ve económico y que no existe `tesorero`, pero el código SÍ da acceso de lectura al supervisor y SÍ existe el rol `tesorero`. Decidir qué es lo correcto (ver §9).

---

## 4. 🗄️ BASE DE DATOS (SQLite, versión 7)

### 4.1 Historial de migraciones (`_onUpgrade`)
| Versión | Cambio |
|---|---|
| v2 | `conductor` +telefono, fecha_nacimiento, direccion, estado_civil, foto, licencia_categoria/emision/vencimiento · `automovil` +marca, modelo, color, capacidad |
| v3 | Recrea `usuario` (admite rol `tesorero`) · `tipo_cuota` +monto_sugerido/activo/es_fijo · `cuota` +monto_pagado, concepto, fecha_vencimiento, id_lote, registrado_por, motivo_anulacion, id_reunion, id_ronda · crea `pago`, `reunion`, `asistencia_reunion`, `pasanaco`, `participante_pasanaco`, `ronda_pasanaco` + índices |
| v4 | (intermedio, ajustes de economía) |
| v5 | **Borra** `pago`, `cuota`, `tipo_cuota` (el usuario quiso empezar sin cuotas) |
| v6 | Siembra los 20 conductores (`_seedConductores`) |
| v7 | `tipo_cuota` +`descripcion` (el **Motivo** de la cuota) |

### 4.2 Tablas (17)
| Tabla | PK | Columnas relevantes |
|---|---|---|
| `usuario` | id_usuario | rol (CHECK: superadmin/admin/supervisor/conductor/tesorero), nombre, estado, gmail (UNIQUE), password (hash), fecha_creacion |
| `conductor` | id_conductor | id_usuario (UNIQUE), nombre, **ci (UNIQUE)**, licencia, fecha_incorporacion, estado, telefono, fecha_nacimiento, direccion, estado_civil, foto, licencia_categoria/emision/vencimiento |
| `automovil` | id_auto | **placa (UNIQUE)**, ruat, soat, fecha_vencimiento_soat, foto, marca, modelo, color, capacidad |
| `conductor_automovil` | (id_conductor, id_auto) | relación N:M |
| `punto_de_control` | id_punto | nombre. **SIN latitud/longitud/radio/tipo** ← Etapa 1 GPS |
| `asistencia` | id_asistencia | id_conductor, id_punto, fecha, hora_llegada, estado. **SIN coordenadas / método / retraso** |
| `vueltas` | id_vuelta | id_conductor, id_asistencia, fecha, hora, tipo (completa/media/turno). **SIN origen/fin/duración/castigo** |
| `sancion` | id_sancion | id_conductor, id_asistencia, motivo, vueltas_asignadas, vueltas_cumplidas, estado, fecha, hora |
| `tipo_cuota` | id_tipo_cuota | **nombre (UNIQUE) = Título**, **descripcion = Motivo**, monto_sugerido, activo, es_fijo |
| `cuota` | id_cuota | id_conductor, id_tipo_cuota, monto, monto_pagado, fecha, estado (pendiente/parcial/pagado/anulado), concepto, registrado_por + 5 sin uso (§4.4) |
| `pago` | id_pago | id_cuota, monto, fecha, metodo, **nro_recibo (UNIQUE, REC-AAAA-NNNNNN)**, observacion, id_usuario |
| `reunion` | id_reunion | fecha, tema, monto_multa (def. 50), estado, cerrada_en |
| `asistencia_reunion` | id_asistencia_reunion | id_reunion, id_conductor, estado (presente/falta/licencia) |
| `pasanaco` | id_pasanaco | nombre, monto_aporte, periodicidad, fecha_inicio, estado |
| `participante_pasanaco` | id_participante | id_pasanaco, id_conductor, numero_turno |
| `ronda_pasanaco` | id_ronda | id_pasanaco, numero_ronda, id_conductor_beneficiario, fecha_limite, monto_total, estado, fecha_entrega |

Todas llevan `created_at`, `updated_at`, `sincronizado` (0 = no subido) pensando en la futura sincronización.

### 4.3 Concepto clave de economía
Se separa **obligación** (`cuota` = lo que se debe) de **abono** (`pago` = lo que se paga). Permite pagos parciales. `monto_falta = monto − monto_pagado`.
Un "**Título de cuota**" (`tipo_cuota`) genera **una `cuota` por cada conductor activo** al crearse.

### 4.4 Columnas de `cuota` sin uso (análisis pedido por el usuario — NO borradas)
`fecha_vencimiento`, `id_lote`, `motivo_anulacion`, `id_reunion`, `id_ronda` → **100% NULL** hoy. Algunas las usarían cobro masivo / reuniones / pasanaco si se conectan. **Decisión pendiente del usuario.** Las otras 12 columnas sí se usan.

### 4.5 Estado de la BD del emulador (al 22 oct)
20 conductores · 2 tipos de cuota (`Pasanaku`, `Apoyo económico`) · 21 cuotas · 9 pagos (`REC-2026-000001…9`).

### 4.6 Siembra (`_seed`)
Solo crea el **superadmin**. (El comentario del código dice "7 tipos de cuota base" pero **ya no los crea**.)

---

## 5. 📱 INVENTARIO DE PANTALLAS (`lib/screens/`)

Leyenda: 🟢 conectada y funcional · 🟡 conectada pero parcial/manual · 🔴 existe pero **no tiene acceso desde el menú**.

| Pantalla | Estado | Qué hace |
|---|---|---|
| `splash_screen` | 🟢 | Arranque; decide Login u Home |
| `login_screen` | 🟢 | Login (gmail staff / CI conductor) |
| `home_screen` | 🟢 | Inicio, drawer, barra inferior, tarjetas |
| `perfil_screen` | 🟢 | Datos del usuario, cerrar sesión |
| `usuarios_screen` | 🟢 | **Directorio** (cuentas de usuario, tarjetas) |
| `conductores_screen` | 🟢 | Conductores en **tarjetas cuadradas**, botón **👁️** → ficha, botón + → formulario |
| `conductor_detalle_screen` | 🟢 | **Ficha completa** del conductor (pantalla, no modal) |
| `conductor_form_screen` | 🟢 | **Crear/editar conductor** en pantalla completa (todos los datos + foto) |
| `control_economico_screen` | 🟢 | **Control de Cuotas** (ver §6) |
| `asistencia_screen` | 🟡 | Asistencia **manual** (se elige conductor y punto) |
| `vueltas_screen` | 🟡 | Vueltas **manuales** |
| `sanciones_screen` | 🟡 | Sanciones **manuales** |
| `informes_screen` | 🟡 | Solo 4 contadores del día |
| `gps_screen` | 🟡 | Mapa `flutter_map` con coordenadas **fijas en código** |
| `panel_tecnico_screen` | 🟢 | Panel técnico (solo superadmin) |
| `cobrar_screen` | 🔴 | Cobro de deudas de un conductor (lo usan las pantallas huérfanas) |
| `nueva_deuda_screen` | 🔴 | Crear deuda individual |
| `cobro_masivo_screen` | 🔴 | Cobro masivo con `id_lote` |
| `cuotas_lista_screen` | 🔴 | Lista filtrable de cuotas |
| `estado_cuenta_screen` | 🔴 | Estado de cuenta por conductor |
| `caja_del_dia_screen` | 🔴 | Caja diaria |
| `informe_economico_screen` | 🔴 | Informe económico |
| `tipos_cuota_screen` | 🔴 | Catálogo de tipos de cuota |
| `reuniones_screen` | 🔴 | Reuniones y faltas |
| `pasanaco_screen` | 🔴 | Pasanaco (sorteo, rondas, entrega) |
| `register_screen` | 🔴 | Autorregistro (nadie lo importa) |
| `welcome_screen` | 🔴 | Bienvenida (nadie lo importa) |

---

## 6. 💰 MÓDULO DE CUOTAS (lo más trabajado) — `control_economico_screen.dart`

### 6.1 Diseño final acordado con el usuario
1. **Tarjeta superior** con 3 datos explícitos: **Título de la Cuota** · **Motivo de la Cuota** · **Monto que debe dar cada chofer (Bs.)**, más botones **✏️ Editar** y **+ Nueva**. Si hay más de una cuota, el título es un selector desplegable.
2. **3 cuadrados informativos que también filtran la lista:**
   - 🟢 **Ya Pagaron** → "60 de 100", total pagado en Bs.
   - 🔴 **No Pagaron** → "40 de 100", total que falta en Bs.
   - 🔵 **Total Cuota** → total de todo (pagado + falta).
3. **Buscador** por nombre o CI.
4. **Lista de conductores** con avatar, `Pagó: Bs. X` (verde), `Falta: Bs. Y` (rojo) y botón **Cobrar** (total o parcial).
5. Botón **Informe** (AppBar) → PDF con **todas las cuotas de todos los conductores**.
6. Menú ⋮: Generar informe, **Eliminar esta cuota**, **Borrar todas**.
7. **Sin recibo** (el usuario lo pidió quitar). Aún existe `siguienteNroRecibo` y el `nro_recibo` es obligatorio en `pago`, pero la UI ya no lo muestra.

### 6.2 Crear cuota (diálogo "Crear Nueva Cuota")
Campos: **Título de la Cuota \*** (ej. "Apoyo económico") · **Motivo de la Cuota** (multilínea, descripción larga) · **Monto por chofer \***. Al guardar: `EconomiaRepo.crearNuevoConceptoCuota(nombre, descripcion, monto, idUsuario)` crea el `tipo_cuota` y una `cuota` por conductor activo, en transacción.

### 6.3 Métodos de `EconomiaRepo` (todos)
- **Cuotas:** `listarTiposCuota`, `crearNuevoConceptoCuota`, `actualizarTipoCuota`, `eliminarTipoCuota`, `vaciarTodasLasCuotas`, `estadoConductoresPorCuota`, `crearCuota`, `crearCobroMasivo`, `anularCuota`.
- **Cobros:** `cobrarAConductor`, `registrarPago`, `siguienteNroRecibo`, `deudasDeConductor`, `estadoDeCuenta`, `pagosDelDia`.
- **Informes:** `resumenHacienda`, `informeEconomico`.
- **Reuniones:** `listarReuniones`, `crearReunion`, `asistenciasDeReunion`, `actualizarAsistenciaReunion`, `cerrarReunion`.
- **Pasanaco:** `listarPasanacos`, `crearPasanaco`, `participantesPasanaco`, `sortearTurnosPasanaco`, `rondasDePasanaco`, `generarSiguienteRondaPasanaco`, `aportesDeRonda`, `entregarRondaPasanaco`.

### 6.4 PDFs (`recibo_pdf_service.dart`)
`generarPdfRecibo` / `mostrarVistaPrevia` · `generarPdfInformeEconomico` / `mostrarVistaPreviaInforme` · **`generarPdfInformeCuotasConductores` / `mostrarVistaPreviaInformeCuotas`** (el vigente: encabezado con Título + Motivo + Monto, 3 tarjetas resumen y tabla de los 20 conductores con Total/Pagó/Falta/Estado).

---

## 7. 🎨 DISEÑO (el usuario insiste en mantenerlo)

| Elemento | Valor |
|---|---|
| Azul institucional | `#1E3A8A` (títulos, íconos, botones principales) |
| Verde (éxito / pagado / acción) | `#10B981` · oscuro `#059669` · fondo `#ECFDF5` |
| Rojo (deuda / peligro) | `#DC2626` · fondo `#FEF2F2` |
| Morado (cuotas en Inicio) | `#8B5CF6` |
| Texto secundario | `#64748B` |
| Fondo de pantalla | `AppBackground` (degradado + **logo del sindicato translúcido**) |
| Tarjetas | `GlassCard` / contenedores blancos, esquinas **18–20 px**, sombra suave |
| Estilo | **Tarjetas cuadradas** (no listas planas) para Directorio y Conductores |
| Tipografía | Google Fonts |

**Preferencias de UX expresadas por el usuario:**
- Formularios grandes → **pantalla propia, NO modal**.
- Simple y directo; "que no se entienda desordenado".
- Mensajes de éxito limpios (no modales raros).
- Mostrar **cantidades** (ej. "3 cuotas") donde antes se mostraban montos, cuando él lo pide.
- Sin "recibo" en cuotas.
- Si no hay foto → **avatar** con iniciales.

---

## 8. 🗣️ HISTORIAL COMPLETO DE LA CONVERSACIÓN

> Hora local (UTC-4). Cada fila = una petición del usuario y lo que se hizo.

### 8.1 Jornada 1 — 21 oct 2026 (conductores, navegación, ficha)
| # | Hora | Petición del usuario | Resultado |
|---|---|---|---|
| 1 | 19:17 | "¿Cuántos módulos tiene este proyecto? Analízalo y explícame" | Análisis de módulos (Auth, Directorio, Conductores, Asistencia, Vueltas, Sanciones, Cuotas, Informes, GPS, Panel Técnico, Perfil) |
| 2 | 19:57 | "Crear un conductor me da este error… ¿por qué?" | Diagnosticado y corregido el alta de conductor |
| 3 | 20:21 | "Aparece un modal de 'usuario creado'; que no salga así" | Reemplazado por un mensaje de éxito limpio |
| 4 | 20:27 | "Quita Usuarios de la barra y pon: Inicio, Asistencias, Vueltas y Cuotas" | Barra inferior de 4 ítems |
| 5 | 20:41 | Pegó **5.1 Objetivo general y 5.2 objetivos específicos a–e** de su tesis | Se generó `plan_objetivos.md` (diagnóstico + plan técnico por objetivo) |
| 6 | 20:50 | "Menú de 3 líneas que despliegue una ventanita a la izquierda" | **Drawer** lateral con secciones |
| 7 | 20:53 | "En transparente y estético, que parezca el logo del sindicato" | Logo translúcido de fondo (`AppBackground`) |
| 8 | 21:02 | "Dividir Usuarios: conductores aparte, supervisores… o un Directorio" | Se separa en Directorio y Conductores |
| 9 | 21:13 | "Solo sería: DIRECTORIO y CONDUCTORES, lo demás está bien" | Confirmada la estructura |
| 10 | 21:19 | "." | (mensaje vacío) |
| 11 | 21:20 | "Quita esto, es exclusivo del directorio" | Elemento retirado de la vista |
| 12 | 21:28 | "Hazlo en **tarjetas cuadradas**, no lista; igual con Conductores" | Grillas de tarjetas |
| 13 | 21:35 | "Pon un botón de **ojito** para ver su información (a futuro)" | Botón 👁️ en cada conductor |
| 14 | 21:41 | Envió imagen de referencia: "Quiero así pero con nuestro diseño; algunos campos no están en la BD; que **no sea modal** sino una **pantalla** por conductor" | `conductor_detalle_screen.dart` (ficha con datos reales + simulados) |
| 15 | 21:55 | "Quita esto, no me sirve" | Elemento retirado |
| 16 | 22:02 | "Dame un **plan** de qué datos hay al apretar el ojito y qué tendríamos que agregar a la BD" | `plan_datos_conductor.md` |
| 17 | 22:04 | "¿Dónde está la BD? **Duplícala** fuera de la carpeta continental" | `d:\PROYECTO_GRADO\continental_dump.sql` |
| 18 | 22:29 | "Haz ese plan" | Migración **v2** + guardar datos reales de la ficha |
| 19 | 22:48 | "Para **crear conductor** que no sea modal sino **pantalla**, con todos los datos nuevos" | `conductor_form_screen.dart` (crear/editar) |
| 20 | 23:28 | "Al añadir una **imagen** que funcione y si no hay, un **avatar**" | `image_picker` + `avatar_conductor.dart`; assets `conductor_default.jpg`, `trufi_minibus.jpg` |

### 8.2 Jornada 2 — 22 oct 2026 (economía) 
| # | Hora | Petición del usuario | Resultado |
|---|---|---|---|
| 21 | 00:14 | Entregó el **"Plan de vistas — Objetivo e) Control económico"** (E1 Panel de Hacienda, E2 Cobrar, E3 Recibo, E4 Estado de cuenta, E5 Lista de cuotas, E6 Cobro masivo, E7 Reuniones, E8 Tipos de cuota, Pasanaco…) | Se implementó **migración v3** y se crearon ~10 pantallas + `economia_repo.dart` + PDFs |
| 22 | 00:57 | "¿Por qué aparece esto cuando quiero correr/emular la app?" | Diagnóstico del error al ejecutar |
| 23 | 00:58 | "Presioné el botón **Sobrescribir** :(" | Aclarado el aviso de reemplazo de archivos |
| 24 | 01:04 | "Al emular, la app no funciona" | Corregido para que corra |
| 25 | 01:32 | "**Todo lo que creaste de cuotas está mal**, desordenado, no se entiende" | ⚠️ Punto de giro: se abandona el enfoque de 10 pantallas por **una sola pantalla simple** |
| 26 | 01:47 | "**BÓRRAME TODO**, que no haya cuotas creadas aún" | v5: se borran `pago`/`cuota`/`tipo_cuota`; las pantallas viejas quedaron **huérfanas** |
| 27 | 02:03 | "3 cuadrados: **Ya pagaron** (solo los que pagaron: de 100, 60), **No pagaron**, y el total de todo con sus montos" | 3 tarjetas informativas que filtran |
| 28 | 02:12 | "¿Por qué hay **recibo**? Quítalo. Sí es necesario un **informe de todas las cuotas de todos los conductores**" | Botón Informe + `generarPdfInformeCuotasConductores`; se quita Ver recibo |
| 29 | 02:20 | Pegó los **datos de 20 conductores** (nombre, CI, teléfono, contraseña, correo, nacimiento, estado civil, dirección, licencia, categoría, fechas, placa, RUAT, marca, modelo, color, capacidad, SOAT) | `seed_data.dart` + inyección en emulador + BD **v6** |
| 30 | 02:31 | "Al crear: **Título** (ej. Apoyo económico) y **Motivo** (aquí describimos todo)" | Campo `descripcion` (BD **v7**), diálogo con 3 campos |
| 31 | 02:43 | "Que aparezca en la pantalla: Título, Motivo, Monto que debe dar cada chofer" | Tarjeta superior + **botón Editar** (`actualizarTipoCuota`) |
| 32 | 02:56 | "**Analiza** qué columnas de `cuota` ya no se usan; **no borres nada**; ¿estamos usando la BD?" | Informe: BD en uso (SQLite), 5 columnas sin uso (§4.4) |
| 33 | 03:03 | "En Inicio, la tarjeta de Cuotas que muestre **cuántas cuotas hay creadas**, no los Bs." | `cuotas_creadas` en `resumenHome` + tarjeta táctil |
| 34 | 03:14 | "Sube todo a git con los commits que hicimos" | 2 commits `1b864dc` y `69d2272` → `origin/main` |
| 35 | 03:30 | Entregó el **Plan GPS** (asistencia automática, vueltas, ruta/alerta; 7 etapas; parámetros; riesgos) y pidió empezar por etapas explicando cada una | Se explicaron las 7 etapas y se propuso arrancar la Etapa 1. **Aún no se ejecutó nada del GPS** |

### 8.3 Jornada 3 — 25 oct 2026
| # | Hora | Petición | Resultado |
|---|---|---|---|
| 36 | 18:24 | "Hazme un **tablero Kanban** de lo hecho y lo que hay que hacer; analiza todo el chat" | `tablero_kanban.md` (artefacto) |
| 37 | 18:32 | "Aumenta ese md: **todo el informe del proyecto**, lo que falta, lo a medias, todo, **incluso la conversación**, en la carpeta continental, pensado para que la IA lo lea" | **Este archivo** |

### 8.4 Commits en Git
| Hash | Mensaje |
|---|---|
| `be9c8e4` | rediseño moderno de la UI, widgets, temas y servicios |
| `3339030` | integración de SQLite, sesión, RBAC y CRUD de usuarios |
| `1b864dc` | **feat(conductores):** ficha ampliada, sembrado de 20 conductores y gestión vehicular |
| `69d2272` | **feat(economia):** control de cuotas con título y motivo, reportes PDF y métricas de inicio |

---

## 9. 🐞 PROBLEMAS CONOCIDOS Y DEUDA TÉCNICA

| # | Severidad | Problema | Dónde | Sugerencia |
|---|---|---|---|---|
| 1 | 🔴 Bug real | `cerrarReunion` **lanza excepción** si no existe el tipo de cuota `'Falta a reunión'`. La migración v5 borró los tipos y `_seed` ya no los crea. | `economia_repo.dart` ~L809 | Crear el tipo si no existe (como hace Pasanaco, que sí se crea bajo demanda) o sembrarlo |
| 2 | 🟠 Lógica | `resumenHome` / `resumenConductor` suman `monto` solo de cuotas con `estado='pendiente'`; ignoran las `parcial` y no restan lo ya pagado. Afecta "Mis Cuotas" del conductor. | `database_helper.dart` ~L1521 | Usar `SUM(monto − monto_pagado)` para `pendiente` y `parcial` |
| 3 | 🟠 Permisos | Comentarios de `permisos.dart` contradicen el código (supervisor, tesorero) | `core/permisos.dart` | Definir la política y actualizar comentarios |
| 4 | 🟡 Limpieza | 8 pantallas de economía **sin acceso** + `register_screen` + `welcome_screen` sin uso | `lib/screens/` | Decidir: conectar (pasanaco/reuniones son del obj. e) o eliminar |
| 5 | 🟡 Limpieza | 5 columnas de `cuota` en NULL | `cuota` | Decidir tras resolver #4 |
| 6 | 🟡 Datos | `nro_recibo` es `NOT NULL UNIQUE` aunque la UI ya no usa recibos | tabla `pago` | Mantener (auditoría) o relajar |
| 7 | 🟡 Duplicados | CI y placa solo se validan por `UNIQUE` (mensaje técnico); no se normalizan (`"1234567 LP"` ≠ `"1234567"`) | `conductor`, `automovil` | Normalizar + validación en vivo (obj. a) |
| 8 | 🟡 Seguridad | Datos solo en el celular; contraseña de superadmin de desarrollo en el código | `_seed` | Backend + cambiar credenciales |
| 9 | 🟡 Arquitectura | Solo economía tiene repositorio; el resto llama directo a `DatabaseHelper`; no hay `domain/` | `lib/` | Refactor gradual |
| 10 | ⚪ Menor | Comentario de `_seed` menciona "7 tipos de cuota base" que ya no se crean | `database_helper.dart` | Corregir comentario |
| 11 | ⚪ Menor | `informes_screen` solo tiene 4 contadores | `informes_screen.dart` | Ver obj. d |

---

## 10. 📋 KANBAN COMPLETO

### ✅ HECHO
**Base y navegación**
- [x] Análisis de módulos · [x] Corregido error al crear conductor · [x] Mensaje de éxito limpio
- [x] Barra inferior: Inicio · Asistencias · Vueltas · Cuotas
- [x] Menú hamburguesa (Drawer) · [x] Logo translúcido del sindicato
- [x] Login, sesión persistente y RBAC con 5 roles (incluye `tesorero`)
- [x] BD SQLite con migraciones versionadas (v7)

**Objetivo a) Conductores**
- [x] Directorio y Conductores en **tarjetas cuadradas** · [x] Botón 👁️ → ficha
- [x] Ficha completa en pantalla propia · [x] Plan de datos del conductor
- [x] Crear/Editar conductor en **pantalla** (no modal) con todos los datos
- [x] Foto con `image_picker` + avatar con iniciales · [x] 20 conductores oficiales sembrados
- [x] Alertas de vencimiento de SOAT/licencia (`documentos_alerta.dart`)
- [x] Copia de la BD fuera de la carpeta (`continental_dump.sql`)

**Objetivo e) Cuotas**
- [x] Tablas `tipo_cuota`, `cuota`, `pago`, `reunion`, `asistencia_reunion`, `pasanaco`, `participante_pasanaco`, `ronda_pasanaco`
- [x] Pantalla única **Control de Cuotas** · [x] 3 cuadrados que filtran (Ya pagaron / No pagaron / Total)
- [x] Crear cuota con **Título + Motivo + Monto** · [x] **Editar** cuota · [x] Eliminar / borrar todas
- [x] Cobro total o parcial · [x] Buscador por nombre/CI
- [x] **Informe PDF** de todos los conductores · [x] Quitado el recibo
- [x] Tarjeta "Cuotas" del Inicio = **cantidad de cuotas creadas**

**Entorno / entrega**
- [x] `flutter analyze` sin problemas · [x] App corre en emulador
- [x] 2 commits subidos a GitHub · [x] Plan GPS definido y explicado

### 🟡 A MEDIAS
- [ ] **Asistencia** → manual (falta GPS) · [ ] **Vueltas** → manual · [ ] **Sanciones** → manual
- [ ] **Informes** → solo 4 contadores · [ ] **GPS** → mapa estático
- [ ] **Puntos de control** → "Parada Central" / "Terminal Central" sin coordenadas (deben ser Cruce Villadela y Teleférico Amarillo)
- [ ] **8 pantallas de economía sin conectar** (cobro masivo, caja del día, lista de cuotas, estado de cuenta, informe económico, tipos de cuota, reuniones, pasanaco)
- [ ] **5 columnas sin uso** en `cuota` (decidir)
- [ ] `register_screen` / `welcome_screen` sin uso (decidir autorregistro)
- [ ] Bugs #1 y #2 de la sección 9

### 🔜 SIGUIENTE — MÓDULO GPS (una etapa a la vez, esperar confirmación)
**Parámetros iniciales (se calibran en calle):** lectura cada **5 s** · radio del punto **40 m** · precisión mínima **30 m** · tolerancia de ruta **60 m** · **3** lecturas seguidas fuera de ruta = alerta.

| Etapa | Qué se hace | Cambios técnicos | Listo cuando |
|---|---|---|---|
| **1 · Puntos con coordenadas** ← EMPEZAR | Guardar Cruce y Teleférico con GPS real | `flutter pub add geolocator permission_handler flutter_foreground_task` · permisos Android · BD v8: `punto_de_control` +`latitud`,`longitud`,`radio_metros`(40),`tipo` · pantalla admin con mapa, círculo de radio y botón **"Usar mi ubicación actual"** | Ves ambos puntos en el mapa |
| **2 · Servicio GPS y turno** | Botón **Iniciar / Terminar turno** | Servicio en 2.º plano con notificación "Rastreo activo" · tabla `turno` | Sigue leyendo con pantalla apagada |
| **3 · Asistencia automática** | Marca sola al entrar al radio | Distancia (Haversine) ≤ radio → insertar `asistencia`; 1 por punto por día | Aparece en `asistencia_screen` sin tocar nada |
| **4 · Detección de vuelta** | A → B → A = 1 vuelta | Estado de etapa guardado en `turno` (sobrevive al cierre de la app) | A→B→A crea 1 fila en `vueltas` |
| **5 · Ruta y alerta** | Grabar ruta y detectar desvío | Tablas `ruta`, `ruta_punto`, `alerta` · distancia a la polilínea | Salirse del recorrido guarda una alerta |
| **6 · Pantallas supervisor** | Mapa en vivo + lista de alertas | Conectar `gps_screen`, `vueltas_screen`, `asistencia_screen` | Supervisor ve ruta, posición y alertas |
| **7 · Calle y APK** | Calibrar y generar APK | Ajustar radio/tolerancia; sirve como pruebas de aceptación del **Capítulo III** | APK instalable probado |

**Decisiones del usuario que bloquean etapas:**
| Para | Pregunta | Respuesta |
|---|---|---|
| Etapa 3 | ¿Hay **hora límite** ("tarde" después de las 6:00) o solo se guarda la hora de llegada? | ⏳ sin responder |
| Etapa 5 | ¿Ida y vuelta van por la **misma calle** o por calles distintas? | ⏳ sin responder |
| Riesgo | ¿Qué **marca de celular** usa el papá del usuario? (Xiaomi/Huawei/Samsung matan apps en 2.º plano) | ⏳ sin responder |
| Etapa 1 | Ir **físicamente** al Cruce y al Teleférico para capturar coordenadas reales (**no inventarlas**) | ⏳ pendiente del usuario |

### 📋 PENDIENTE (Backlog por objetivo)
**Fase 0 — Fundamentos:** tabla `configuracion` (hora de entrada, tolerancia, radio…) · **bitácora/auditoría** · refactor en capas (`repositories/`, `domain/`) · definir política de permisos del supervisor.
**a) Conductores:** normalizar CI y placa · validación en vivo ("Ya registrado… Ver ficha") · **dar de baja** (inactivo) en vez de borrar · número interno único · decidir autorregistro con aprobación.
**b) Asistencia:** tabla `horario` (entrada, tolerancia, límite de falta) · estado automático presente/tardanza/falta · **antifraude** (`isMocked`, marcar desde lejos) · registro manual **con justificación** · **cierre de jornada** que genera faltas.
**c) Vueltas:** `marcacion_punto` · tiempo mínimo entre puntos · **vueltas de castigo** que descuentan de la sanción correcta.
**d) Sanciones/Informes:** `regla_sancion` configurable (ej. tardanza 11–30 min → 1 vuelta) · sanción automática (+ multa económica vinculada) · anulación solo admin con motivo · **informe diario PDF** (<5 s) + Excel + gráficos `fl_chart` + compartir · informes por rango, por conductor y económico.
**e) Económico:** conectar **reuniones** (falta ⇒ cuota automática) · conectar **pasanaco** (sorteo, rondas, entrega) · cobro masivo y estado de cuenta accesibles · multas por sanción que aparezcan solas como deuda · panel de Hacienda (recaudado hoy/mes, top deudores).
**Centralización:** elegir backend (**Supabase** recomendado / Firebase / API propia) · `SyncService` offline-first (columnas `sincronizado` ya existen) · hora oficial del servidor.
**Tesis:** pruebas de aceptación en campo · piloto en Cruce Villadela y Teleférico Amarillo · evidencias para la defensa (Capítulo III).

---

## 11. 🧭 PLAN DE VUELO RECOMENDADO

```
[Resolver bugs #1 y #2] → [Decidir qué hacer con pantallas huérfanas y columnas sin uso]
        ↓
[Etapa 1 GPS: puntos] → [Etapa 2: turno + servicio] → [Etapa 3: asistencia auto] → [Etapa 4: vueltas]
        ↓                                                       ↓
[Etapa 5-6: ruta, alertas, supervisor]                  [Sanciones automáticas + Informes]
        ↓                                                       ↓
        └──────────────→ [Nube + APK + Pruebas en calle + Capítulo III] ←─────┘
```

---

## 12. 🧠 GUÍA PARA LA IA (cómo trabajar con este usuario y este repo)

1. **Lee este archivo primero**, luego `docs/plan_objetivos.md` si necesitas el detalle técnico de un objetivo.
2. **Responde en español**, conciso, en markdown, con enlaces `file:///` a los archivos.
3. **Avanza UNA etapa a la vez** y espera confirmación (así lo pidió para el GPS).
4. **No borres datos ni código sin pedirlo.** Si el usuario dice "analiza", **solo analiza**.
5. **Pregunta antes de asumir** si la intención no es clara; el usuario escribe rápido y con errores.
6. **Mantén el diseño** (§7). Pantalla propia para formularios grandes; tarjetas cuadradas; colores definidos.
7. **No inventes coordenadas GPS.** Se capturan en el lugar real.
8. **Después de cambiar código:** `flutter analyze` debe quedar en 0 problemas.
9. **Migraciones:** subir `_dbVersion`, añadir bloque `if (oldVersion < N)` en `_onUpgrade` **y** reflejarlo en `_onCreate`. Usar `try { ALTER … } catch (_) {}`.
10. **PowerShell:** evitar SQL con comillas/tildes por `adb shell`; usar Python con stdin (§2.4).
11. **BD del emulador** vive en `/data/data/com.example.continental/databases/continental.db`; acceso con `su 0 sqlite3`.
12. **Git:** commitear/pushear **solo cuando el usuario lo pida**. Mensajes en formato `feat(modulo): descripción`.
13. Las **pantallas huérfanas (🔴)** contienen lógica útil (reuniones, pasanaco, cobro masivo): **no las borres** sin preguntar; el objetivo e) las necesita.
14. El usuario es **estudiante**: explica brevemente el "para qué" de cada etapa; su tesis necesita evidencia de pruebas reales.

---

## 13. 📚 ARTEFACTOS Y ARCHIVOS RELACIONADOS

| Archivo | Contenido |
|---|---|
| `docs/plan_objetivos.md` | Plan técnico completo por objetivo a–e, modelo de datos propuesto, algoritmos, criterios de aceptación y cronograma por sprints |
| `docs/plan_datos_conductor.md` | Qué datos muestra la ficha del conductor y qué columnas se agregaron |
| `BASE_DE_DATOS.md` | Documentación original de la migración a SQLite (anterior a v2) |
| `continental_dump.sql` | Volcado SQL de la BD del emulador (22 oct) |
| `tablero_kanban.md` (artefacto del chat) | Versión corta del tablero Kanban |
| `plan_objetivos.md` (raíz) | Copia previa del plan por objetivos |
