# 🗄️ Documentación de Base de Datos y Migración SQLite

> **Proyecto de Grado:** Continental Trufi  
> **Sistema:** Control, Gestión y Monitoreo de Transporte Público  
> **Motor de Persistencia:** SQLite Local (mediante `sqflite`, `crypto`, `uuid`, `path`)  
> **Fecha de Implementación:** Octubre 2026  

---

## 📋 Resumen de la Intervención

Se realizó una **depuración integral del proyecto**, eliminando el 100% de los datos quemados (*mock data* / listas estáticas en memoria) que simulaban el funcionamiento del sistema.

Se implementó una arquitectura relacional robusta en **SQLite** mediante la clase centralizada [`DatabaseHelper`](file:///d:/PROYECTO_GRADO/continental/lib/services/database_helper.dart), conectando todas las pantallas de la aplicación a consultas SQL dinámicas en tiempo real con transacciones atómicas y seguridad mediante cifrado de contraseñas.

---

## 🗂️ Modelo Entidad - Relación (Diagrama de Tablas)

```mermaid
erDiagram
    usuario ||--o| conductor : "id_usuario"
    conductor ||--o{ conductor_automovil : "id_conductor"
    automovil ||--o{ conductor_automovil : "id_auto"
    conductor ||--o{ asistencia : "id_conductor"
    punto_de_control ||--o{ asistencia : "id_punto"
    conductor ||--o{ vueltas : "id_conductor"
    asistencia ||--o{ vueltas : "id_asistencia"
    conductor ||--o{ cuota : "id_conductor"
    tipo_cuota ||--o{ cuota : "id_tipo_cuota"
    conductor ||--o{ sancion : "id_conductor"
    asistencia ||--o{ sancion : "id_asistencia"

    usuario {
        TEXT id_usuario PK
        TEXT rol "superadmin, admin, supervisor, conductor"
        TEXT nombre
        TEXT estado "activo / inactivo"
        TEXT gmail UK
        TEXT password "SHA-256 Hash"
        TEXT fecha_creacion
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    conductor {
        TEXT id_conductor PK
        TEXT id_usuario FK
        TEXT nombre
        TEXT ci UK
        TEXT licencia
        TEXT telefono "Nuevo v2"
        TEXT fecha_nacimiento "Nuevo v2"
        TEXT direccion "Nuevo v2"
        TEXT estado_civil "Nuevo v2"
        TEXT foto "Nuevo v2"
        TEXT licencia_categoria "Nuevo v2"
        TEXT licencia_emision "Nuevo v2"
        TEXT licencia_vencimiento "Nuevo v2"
        TEXT fecha_incorporacion
        TEXT estado
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    automovil {
        TEXT id_auto PK
        TEXT placa UK
        TEXT ruat
        TEXT soat
        TEXT fecha_vencimiento_soat
        TEXT marca "Nuevo v2"
        TEXT modelo "Nuevo v2"
        TEXT color "Nuevo v2"
        INTEGER capacidad "Nuevo v2"
        TEXT foto
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    conductor_automovil {
        TEXT id_conductor PK,FK
        TEXT id_auto PK,FK
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    punto_de_control {
        TEXT id_punto PK
        TEXT nombre
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    asistencia {
        TEXT id_asistencia PK
        TEXT id_conductor FK
        TEXT id_punto FK
        TEXT fecha
        TEXT hora_llegada
        TEXT estado "presente, tardanza, falta"
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    vueltas {
        TEXT id_vuelta PK
        TEXT id_conductor FK
        TEXT id_asistencia FK
        TEXT fecha
        TEXT hora
        TEXT tipo "Completa, Media Vuelta, etc."
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    tipo_cuota {
        TEXT id_tipo_cuota PK
        TEXT nombre UK
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    cuota {
        TEXT id_cuota PK
        TEXT id_conductor FK
        TEXT id_tipo_cuota FK
        REAL monto
        TEXT fecha
        TEXT estado "pendiente, pagado"
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }

    sancion {
        TEXT id_sancion PK
        TEXT id_conductor FK
        TEXT id_asistencia FK
        TEXT motivo
        INTEGER vueltas_asignadas
        INTEGER vueltas_cumplidas
        TEXT estado "pendiente, cumplida"
        TEXT fecha
        TEXT hora
        TEXT created_at
        TEXT updated_at
        INTEGER sincronizado
    }
```

---

## 🏛️ Descripción Detallada de las Tablas (SQLite)

Todas las tablas cuentan con llaves primarias universales (`UUID v4`) y columnas estándar preparadas para sincronización bidireccional con una futura nube:
* `created_at` (TEXT en formato ISO 8601).
* `updated_at` (TEXT en formato ISO 8601).
* `sincronizado` (INTEGER: `0` = pendiente de subir, `1` = sincronizado con el servidor).

### 1. `usuario`
Almacena las credenciales principales del sistema.
* **Roles soportados:** `superadmin`, `admin`, `supervisor`, `conductor` (validado mediante `CHECK`).
* **Regla de negocio:** El personal administrativo debe registrar obligatoriamente correo electrónico (`gmail IS NOT NULL`), mientras que el conductor puede ingresar únicamente con su Cédula de Identidad (**CI**).

### 2. `conductor`
Ficha técnica del afiliado / chofer. Vinculado a `usuario` mediante `id_usuario` (`FOREIGN KEY ... ON DELETE CASCADE`).
* **Columnas base:** `id_conductor`, `id_usuario`, `nombre`, `ci`, `licencia`, `fecha_incorporacion`, `estado`.
* **Nuevas columnas v2 (Ficha del Conductor):**
  * `telefono` (TEXT): Número de contacto telefónico / celular.
  * `fecha_nacimiento` (TEXT en formato ISO `YYYY-MM-DD`).
  * `direccion` (TEXT): Domicilio particular del chofer.
  * `estado_civil` (TEXT): Soltero(a), Casado(a), etc.
  * `foto` (TEXT): Ruta local del archivo de foto de perfil.
  * `licencia_categoria` (TEXT): Ej. *Categoría Profesional C*, *Categoría B*.
  * `licencia_emision` (TEXT en formato ISO `YYYY-MM-DD`).
  * `licencia_vencimiento` (TEXT en formato ISO `YYYY-MM-DD`): Utilizado para cálculo automático de caducidad.

### 3. `automovil`
Vehículos pertenecientes a la línea/sindicato Continental.
* **Columnas base:** `id_auto`, `placa`, `ruat`, `soat`, `fecha_vencimiento_soat`, `foto`.
* **Nuevas columnas v2 (Ficha Técnica de Unidad):**
  * `marca` (TEXT): Marca del trufi/minibús (ej. *Toyota*).
  * `modelo` (TEXT): Modelo (ej. *Hiace*).
  * `color` (TEXT): Ej. *Blanco / Azul*.
  * `capacidad` (INTEGER): Cantidad de pasajeros (ej. *14*).

### 4. `conductor_automovil`
Tabla de asociación de muchos a muchos (N:M) con llave primaria compuesta `(id_conductor, id_auto)` para gestionar qué conductor maneja qué unidad o cambio de turnos de vehículos.

### 5. `punto_de_control`
Puntos geográficos o paradas estratégicas de control (ej. Cruce Villadela, Parada Central, Teleférico, etc.).

### 6. `asistencia`
Control de registro diario de llegada a puntos de control.
* Estados: `presente`, `tardanza`, `falta`.

### 7. `vueltas`
Cronometraje y conteo de recorridos o turnos realizados por cada unidad en el día.

### 8. `tipo_cuota`
Catálogo de conceptos de pago (ej. *Cuota Mensual*, *Extraordinaria*, *Multa*).

### 9. `cuota`
Registro contable de aportes económicos y deudas.
* Vinculada a conductor y tipo de cuota, registrando el monto y estado (`pendiente` o `pagado`).

### 10. `sancion`
Infracciones registradas a conductores (retrasos, faltas a asambleas, desvíos).
* Gestiona vueltas de castigo asignadas y cumplidas.

---

## 🔑 Cuentas Semilla Iniciales (*Seed Data*)

Al iniciarse la aplicación por primera vez, SQLite autoejecuta el método `_seed(...)` insertando automáticamente las cuentas base del personal administrativo y los tipos de cuotas con contraseñas hasheadas en SHA-256:

| Rol | Nombre | Identificador / Correo | Contraseña Plana |
| :--- | :--- | :--- | :--- |
| **Superadmin** | Super Administrador | `superadmin@continental.com` | `super123` |
| **Admin** | Administrador | `admin@continental.com` | `admin123` |
| **Supervisor** | Supervisor | `supervisor@continental.com` | `supervisor123` |

> 💡 **Nota:** Los conductores pueden registrarse desde la pantalla de Registro o mediante el botón "Agregar Conductor" e ingresarán con su **CI** y su contraseña personal.

---

## 🔄 Detalle de Archivos Modificados y Datos Borrados

A continuación se detalla todo el trabajo realizado archivo por archivo:

### 1. `continental/pubspec.yaml`
* **Agregado:** Paquetes `uuid: ^4.4.0` (generación de llaves primarias únicas) y `crypto: ^3.0.3` (algoritmo SHA-256 para contraseñas).
* Se ejecutó `flutter pub get` con resolución exitosa de dependencias.

### 2. `lib/services/database_helper.dart`
* **Antes:** Contenía una lista simulada en memoria `_webDb` y una tabla básica `users` sin relaciones.
* **Ahora:** Clase `DatabaseHelper` completa con:
  * Creación e indexación de las 9 tablas (`PRAGMA foreign_keys = ON`).
  * Índices rápidos para asistencias, vueltas, cuotas y sanciones.
  * CRUD Genérico (`insertar`, `listar`, `obtener`, `actualizar`, `eliminar`).
  * Autenticación dual inteligente (`login(identificador, password)`). Si contiene `@` busca por correo; si no, busca por CI del conductor.
  * Transacciones ACID (`registrarConductor`) que crean el usuario y la ficha del conductor de forma indivisible.
  * Métodos especializados con `JOIN` para pantallas (`conductoresConAuto`, `asistenciasDetalle`, `vueltasDetalle`, `sancionesDetalle`, `cuotasDetalle`).
  * Cálculo estadístico dinámico (`resumenHome`).

### 3. `lib/models/usuario_model.dart`
* **Datos quemados eliminados:** Se borró por completo el bloque estático `currentUser => Usuario(id: 'U001', nombre: 'Michael Crispin Mamani', rol: 'Encargado', ci: '12345678', numeroTrufi: '115', estado: 'Activo')`.
* **Nueva implementación:** Se agregó `static Usuario? currentUser;` (dinámico en sesión), constructor `Usuario.fromMap(...)` y método `toMap()`.

### 4. `lib/models/ruta_model.dart`
* **Datos quemados eliminados:** Se borró el getter estático `currentRuta` con nombres de conductor ficticios y paradas duras en el código.
* **Nueva implementación:** Modelos `Ruta` y `Parada` preparados para recibir registros de puntos desde SQLite.

### 5. `lib/screens/login_screen.dart`
* **Antes:** Verificaba contra un método dummy y navegaba directamente sin guardar sesión.
* **Ahora:** Consume `DatabaseHelper.instance.login(user, pass)`. Al autenticar, mapea el registro a `Usuario.currentUser` y navega al Dashboard con el perfil autenticado.

### 6. `lib/screens/register_screen.dart`
* **Antes:** Solo tenía un botón que abría `HomeScreen` sin guardar nada.
* **Ahora:** Conectado con controladores a `DatabaseHelper.instance.registrarConductor(...)`. Valida campos, confirma contraseñas, encripta y guarda el conductor en SQLite.

### 7. `lib/screens/home_screen.dart`
* **Datos quemados eliminados:**
  * Tarjetas con números inventados: *"38 / 40 conductores"*, *"76 vueltas"*, *"2 sanciones"*, *"Bs. 1.250 en cuotas"*.
  * Saludo estático *"Hola, Encargado"* y fecha estática *"17 de septiembre de 2026"*.
* **Ahora:**
  * Saludo personalizado con `Usuario.currentUser?.nombre`.
  * Fecha actual dinámica calculada con `DateTime.now()`.
  * Estadísticas en tiempo real obtenidas de `DatabaseHelper.instance.resumenHome()` y conteo de vueltas de hoy.

### 8. `lib/screens/conductores_screen.dart`
* **Datos quemados eliminados:** La lista dura en memoria:
  ```dart
  final List<Map<String, dynamic>> _conductores = const [
    {'name': 'Juan Pérez', 'ci': '12345678', 'unit': '115'},
    {'name': 'Pedro Quispe', ...}, ...
  ];
  ```
* **Ahora:** Consulta en vivo `DatabaseHelper.instance.conductoresConAuto()`, buscador en tiempo real por nombre/CI/placa, mensaje de lista vacía cuando no hay registros y diálogo modal "Agregar Conductor" con guardado directo en SQLite.

### 9. `lib/screens/asistencia_screen.dart`
* **Datos quemados eliminados:** Lista estática de choferes con estados inventados y fecha fija.
* **Ahora:** Selector interactivo de fecha con `showDatePicker`, consulta en tiempo real mediante `asistenciasDetalle(fecha)`, listado de puntos de control de SQLite y botón "Registrar Asistencia" con selección de chofer y punto de control.

### 10. `lib/screens/sanciones_screen.dart`
* **Datos quemados eliminados:** Lista estática de sanciones pendientes y en proceso.
* **Ahora:** Consulta `sancionesDetalle(estado)` filtrando por pestañas (*Todas / Pendientes / Cumplidas*), buscador y diálogo para registrar sanciones en la base de datos.

### 11. `lib/screens/control_economico_screen.dart`
* **Datos quemados eliminados:** Los valores fijos *"Bs. 2.450"* (Recaudación) y *"Bs. 350"* (Pagos pendientes).
* **Ahora:** Suma aritmética en vivo de las cuotas con estado `pagado` y `pendiente`, muestra los tipos de cuota registrados en la base de datos y permite registrar nuevas cuotas/aportes.

### 12. `lib/screens/vueltas_screen.dart`
* **Antes:** Pantalla con texto de marcador de posición *"Vista de Vueltas"*.
* **Ahora:** Pantalla funcional conectada a `vueltasDetalle(fecha)`, con selector de fecha, lista de vueltas completadas y modal para despachar turnos a conductores.

### 13. `lib/screens/informes_screen.dart`
* **Datos quemados eliminados:** Resumen con datos fijos ("38 presentes", "76 completadas", etc.).
* **Ahora:** Genera informes diarios automáticos sumando asistencias, vueltas, sanciones y montos recaudados de la base de datos para cualquier fecha elegida.

### 14. `lib/screens/gps_screen.dart`
* **Datos quemados eliminados:** Texto fijo *"Trufi 115 • Juan Pérez"*.
* **Ahora:** Carga unidades reales de SQLite y puntos de control, permitiendo alternar entre conductores registrados.

### 15. `lib/screens/perfil_screen.dart`
* **Antes:** Invocaba el mock hardcodeado.
* **Ahora:** Lee los datos de `Usuario.currentUser`, muestra el rol y datos reales, y al presionar "Cerrar sesión" limpia la sesión y redirige a `LoginScreen`.

### 16. `lib/core/documentos_alerta.dart` (Nuevo)
* Módulo centralizado para cálculo dinámico del estado de vigencia de licencias y pólizas SOAT (`Vigente`, `Por vencer`, `Vencida`, `No registrado`).
* Define los colores semánticos y fondos de advertencia (rojo para vencido, ámbar para <= 30 días restantes, verde para vigentes).

### 17. `lib/screens/conductor_detalle_screen.dart` (Ficha del Conductor / "Ojito")
* **Antes:** Pantalla con datos estáticos de prueba (mock).
* **Ahora:** Conectada a `DatabaseHelper.instance.fichaConductor(idConductor)`.
  * Muestra banner reactivo superior de alertas de vencimiento si la Licencia o el SOAT están vencidos o próximos a caducar.
  * Pestaña *Información General*: Datos personales reales (teléfono, nacimiento, dirección, estado civil, correo vinculado) con fallback limpio a "No registrado".
  * Pestaña *Documentos*: Número de licencia, categoría, fechas de emisión y vencimiento con badge dinámico de validez.
  * Pestaña *Trufi*: Placa, marca, modelo, color, capacidad de pasajeros, SOAT y RUAT extraídos de SQLite.
  * Pestañas *Asistencias* y *Observaciones*: Conectadas al historial real en base de datos.

---

## 🚀 Migración a Versión 2 de la Base de Datos

Para dispositivos con bases de datos ya creadas, se implementó el manejador `onUpgrade` en [`DatabaseHelper`](file:///d:/PROYECTO_GRADO/continental/lib/services/database_helper.dart) que ejecuta las siguientes sentencias DDL de manera no destructiva:

```sql
-- Versión 2: Columnas de Ficha y Documentos en conductor
ALTER TABLE conductor ADD COLUMN telefono TEXT;
ALTER TABLE conductor ADD COLUMN fecha_nacimiento TEXT;
ALTER TABLE conductor ADD COLUMN direccion TEXT;
ALTER TABLE conductor ADD COLUMN estado_civil TEXT;
ALTER TABLE conductor ADD COLUMN foto TEXT;
ALTER TABLE conductor ADD COLUMN licencia_categoria TEXT;
ALTER TABLE conductor ADD COLUMN licencia_emision TEXT;
ALTER TABLE conductor ADD COLUMN licencia_vencimiento TEXT;

-- Versión 2: Columnas de Unidad Móvil en automovil
ALTER TABLE automovil ADD COLUMN marca TEXT;
ALTER TABLE automovil ADD COLUMN modelo TEXT;
ALTER TABLE automovil ADD COLUMN color TEXT;
ALTER TABLE automovil ADD COLUMN capacidad INTEGER;
```

---

## 🎯 Verificación y Calidad de Código
Se ejecutó la herramienta de análisis estático del SDK de Flutter:
```bash
flutter analyze
```
* **Errores:** 0
* **Advertencias:** 0
* **Compilación:** Limpia y lista para ejecución en dispositivos o emuladores Android/iOS/Desktop.
