# Plan de Datos: Ficha del Conductor (Perfil Detalle)
**Proyecto de Grado: Grupo Continental Trufi 101 – 127**

Este documento detalla todos los campos que se presentan actualmente al presionar el botón de consulta (**Ojito** / [ConductorDetalleScreen](file:///d:/PROYECTO_GRADO/continental/lib/screens/conductor_detalle_screen.dart)), clasificándolos entre los que **ya existen** en la base de datos SQLite y los **nuevos campos que se deben agregar** para que la información sea 100% real y modificable.

---

## 1. Comparativa General de Datos

| Sección en Pantalla | Campo Mostrado | Origen Actual | ¿Existe en SQLite? | Tabla Sugerida |
| :--- | :--- | :--- | :--- | :--- |
| **Cabecera** | Nombre completo | `c['nombre']` | ✅ Sí | `conductor` / `usuario` |
| **Cabecera** | Estado (Habilitado / Inhabilitado) | `c['estado']` | ✅ Sí | `conductor` / `usuario` |
| **Cabecera** | Carnet de Identidad (CI) | `c['ci']` | ✅ Sí | `conductor` |
| **Cabecera** | Código sindical (`CON-XXXXX`) | Calculado de CI | ⚠️ Derivado | `conductor` (`codigo`) |
| **Cabecera** | Foto de perfil | Asset por defecto | ❌ No | `conductor` (`foto`) |
| **Info Personal** | Carnet de identidad | `c['ci']` | ✅ Sí | `conductor` |
| **Info Personal** | Teléfono / Celular | Mock: `+591 70000000` | ❌ No | `conductor` (`telefono`) |
| **Info Personal** | Fecha de nacimiento | Mock: `12/03/1998` | ❌ No | `conductor` (`fecha_nacimiento`) |
| **Info Personal** | Correo electrónico | `c['gmail']` o simulado | ✅ Sí (en `usuario`) | `usuario` (`gmail`) |
| **Info Personal** | Dirección de domicilio | Mock: `Zona 16 de Julio` | ❌ No | `conductor` (`direccion`) |
| **Info Personal** | Estado civil | Mock: `Soltero` | ❌ No | `conductor` (`estado_civil`) |
| **Estado** | Estado (Habilitado) | `c['estado']` | ✅ Sí | `conductor` |
| **Estado** | Fecha de registro | `c['fecha_incorporacion']` | ✅ Sí | `conductor` |
| **Estado** | Última actualización | `c['updated_at']` | ✅ Sí | `conductor` |
| **Licencia** | Número de licencia | `c['licencia']` | ✅ Sí | `conductor` |
| **Licencia** | Categoría de licencia | Mock: `Categoría C` | ❌ No | `conductor` (`licencia_categoria`) |
| **Licencia** | Fecha de emisión | Mock: `15/08/2022` | ❌ No | `conductor` (`licencia_emision`) |
| **Licencia** | Fecha de vencimiento | Mock: `15/08/2027` | ❌ No | `conductor` (`licencia_vencimiento`) |
| **Licencia** | Entidad emisora | Mock: `Tránsito / SEGIP` | ❌ No | `conductor` (`licencia_emisor`) |
| **Licencia** | Estado de licencia | Mock: `Vigente` | ❌ No | `conductor` (`licencia_estado`) |
| **Vehículo** | N° de móvil / interno | Mock: `101` | ❌ No | `automovil` (`num_interno`) |
| **Vehículo** | Placa de control | `c['placa']` | ✅ Sí | `automovil` |
| **Vehículo** | Marca y modelo | Mock: `Toyota Hiace` | ❌ No | `automovil` (`marca`, `modelo`) |
| **Vehículo** | Color de vehículo | Mock: `Blanco / Azul` | ❌ No | `automovil` (`color`) |
| **Vehículo** | Ruta asignada | Mock: `Ruta 1 - 16 de Julio` | ❌ No | `automovil` (`ruta_asignada`) |
| **Vehículo** | Capacidad de pasajeros | Mock: `14 pasajeros` | ❌ No | `automovil` (`capacidad`) |
| **Vehículo** | Tipo de combustible | Mock: `Gasolina / GNV` | ❌ No | `automovil` (`combustible`) |
| **Documentos** | SOAT | `soat`, `vencimiento_soat` | ✅ Sí | `automovil` |
| **Documentos** | RUAT | `ruat` | ✅ Sí | `automovil` |
| **Documentos** | Certificado FELCC / Antecedentes | Mock: `Aprobado` | ❌ No | Nueva tabla / campos |
| **Documentos** | Carnet Sindical / Afiliación | Mock: `Activo` | ❌ No | Nueva tabla / campos |
| **Actividad** | Asistencias (Villadela / Teleférico) | SQLite `asistencia` | ✅ Sí | `asistencia` |
| **Actividad** | Sanciones y observaciones | SQLite `sancion` | ✅ Sí | `sancion` |
| **Actividad** | Ubicación en tiempo real | GPS en vivo | ✅ Sí | GPS Screen |

---

## 2. Propuesta de Modificación a la Base de Datos SQLite

Para que todos los datos mostrados en la ficha del conductor sean reales, persistentes y editables, se proponen los siguientes cambios en [database_helper.dart](file:///d:/PROYECTO_GRADO/continental/lib/services/database_helper.dart):

### A. Modificación a la tabla `conductor`
Agregar las siguientes columnas:
```sql
ALTER TABLE conductor ADD COLUMN telefono TEXT;
ALTER TABLE conductor ADD COLUMN fecha_nacimiento TEXT;
ALTER TABLE conductor ADD COLUMN direccion TEXT;
ALTER TABLE conductor ADD COLUMN estado_civil TEXT;
ALTER TABLE conductor ADD COLUMN foto TEXT;
ALTER TABLE conductor ADD COLUMN codigo TEXT;
ALTER TABLE conductor ADD COLUMN licencia_categoria TEXT DEFAULT 'Categoría Profesional C';
ALTER TABLE conductor ADD COLUMN licencia_emision TEXT;
ALTER TABLE conductor ADD COLUMN licencia_vencimiento TEXT;
ALTER TABLE conductor ADD COLUMN licencia_emisor TEXT DEFAULT 'Dirección de Tránsito / SEGIP';
ALTER TABLE conductor ADD COLUMN licencia_estado TEXT DEFAULT 'Vigente';
```

### B. Modificación a la tabla `automovil`
Agregar columnas para los datos técnicos del Trufi:
```sql
ALTER TABLE automovil ADD COLUMN num_interno TEXT;        -- Ej: '101' o '127'
ALTER TABLE automovil ADD COLUMN marca TEXT DEFAULT 'Toyota';
ALTER TABLE automovil ADD COLUMN modelo TEXT DEFAULT 'Hiace';
ALTER TABLE automovil ADD COLUMN color TEXT DEFAULT 'Blanco / Azul';
ALTER TABLE automovil ADD COLUMN ruta_asignada TEXT DEFAULT 'Ruta 1 - Cruce Villadela / 16 de Julio';
ALTER TABLE automovil ADD COLUMN capacidad INTEGER DEFAULT 14;
ALTER TABLE automovil ADD COLUMN combustible TEXT DEFAULT 'Gasolina / GNV';
```

### C. (Opcional recomendado) Tabla `documento_conductor`
Para gestionar vencimientos y fotos de documentos oficiales:
```sql
CREATE TABLE documento_conductor (
  id_documento   TEXT PRIMARY KEY,
  id_conductor   TEXT NOT NULL,
  tipo_documento TEXT NOT NULL, -- 'CI', 'LICENCIA', 'SOAT', 'RUAT', 'FELCC', 'SINDICAL'
  numero_doc     TEXT,
  fecha_emision  TEXT,
  fecha_vence    TEXT,
  estado         TEXT DEFAULT 'Vigente',
  foto_archivo   TEXT,
  FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor) ON DELETE CASCADE
);
```

---

## 3. Plan de Implementación por Fases

1. **Fase 1: Datos Personales y de Licencia en `conductor`**
   - Permitir guardar teléfono, dirección, fecha de nacimiento y vigencia de licencia al registrar o editar al conductor.
2. **Fase 2: Datos de Unidad en `automovil`**
   - Incorporar número de interno (`101`, `127`, etc.), modelo y color al asignar vehículo.
3. **Fase 3: Pantalla de Edición Integral**
   - Habilitar que el formulario de creación/edición de conductor incluya estos nuevos campos en lugar de valores fijos.
