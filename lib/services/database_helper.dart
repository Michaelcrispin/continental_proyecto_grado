import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'seed_data.dart';

/// Base de datos local (SQLite) del sistema Continental Trufi.
///
/// Dependencias en pubspec.yaml:
///   sqflite: ^2.3.0
///   path: ^1.9.0
///   uuid: ^4.4.0
///   crypto: ^3.0.3
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'continental.db';
  static const _dbVersion = 7;
  static const _uuid = Uuid();

  Database? _db;

  /// Nombre de la llave primaria de cada tabla.
  /// (conductor_automovil usa llave compuesta, por eso no está aquí)
  static const Map<String, String> _pk = {
    'usuario': 'id_usuario',
    'conductor': 'id_conductor',
    'automovil': 'id_auto',
    'punto_de_control': 'id_punto',
    'asistencia': 'id_asistencia',
    'vueltas': 'id_vuelta',
    'tipo_cuota': 'id_tipo_cuota',
    'cuota': 'id_cuota',
    'pago': 'id_pago',
    'reunion': 'id_reunion',
    'asistencia_reunion': 'id_asistencia_reunion',
    'pasanaco': 'id_pasanaco',
    'participante_pasanaco': 'id_participante',
    'ronda_pasanaco': 'id_ronda',
    'sancion': 'id_sancion',
  };

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ---------------------------------------------------------------------------
  // MIGRACIÓN DE BASE DE DATOS
  // ---------------------------------------------------------------------------
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Columnas nuevas para conductor
      await db.execute('ALTER TABLE conductor ADD COLUMN telefono TEXT');
      await db.execute('ALTER TABLE conductor ADD COLUMN fecha_nacimiento TEXT');
      await db.execute('ALTER TABLE conductor ADD COLUMN direccion TEXT');
      await db.execute('ALTER TABLE conductor ADD COLUMN estado_civil TEXT');
      await db.execute('ALTER TABLE conductor ADD COLUMN foto TEXT');
      await db.execute('ALTER TABLE conductor ADD COLUMN licencia_categoria TEXT');
      await db.execute('ALTER TABLE conductor ADD COLUMN licencia_emision TEXT');
      await db.execute('ALTER TABLE conductor ADD COLUMN licencia_vencimiento TEXT');

      // Columnas nuevas para automovil
      await db.execute('ALTER TABLE automovil ADD COLUMN marca TEXT');
      await db.execute('ALTER TABLE automovil ADD COLUMN modelo TEXT');
      await db.execute('ALTER TABLE automovil ADD COLUMN color TEXT');
      await db.execute('ALTER TABLE automovil ADD COLUMN capacidad INTEGER');
    }

    if (oldVersion < 3) {
      // 1. Recrear tabla usuario para permitir el rol 'tesorero'
      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS usuario_v3 (
          id_usuario     TEXT PRIMARY KEY,
          rol            TEXT NOT NULL
                         CHECK (rol IN ('superadmin','admin','supervisor','conductor','tesorero')),
          nombre         TEXT NOT NULL,
          estado         TEXT NOT NULL DEFAULT 'activo',
          gmail          TEXT UNIQUE,
          password       TEXT NOT NULL,
          fecha_creacion TEXT NOT NULL,
          created_at     TEXT NOT NULL,
          updated_at     TEXT NOT NULL,
          sincronizado   INTEGER NOT NULL DEFAULT 0,
          CHECK (rol = 'conductor' OR gmail IS NOT NULL)
        )
      ''');
      await db.execute('''
        INSERT OR IGNORE INTO usuario_v3 (id_usuario, rol, nombre, estado, gmail, password, fecha_creacion, created_at, updated_at, sincronizado)
        SELECT id_usuario, rol, nombre, estado, gmail, password, fecha_creacion, created_at, updated_at, sincronizado FROM usuario
      ''');
      await db.execute('DROP TABLE usuario');
      await db.execute('ALTER TABLE usuario_v3 RENAME TO usuario');
      await db.execute('PRAGMA foreign_keys = ON');

      // 2. Ampliar tabla tipo_cuota
      try {
        await db.execute('ALTER TABLE tipo_cuota ADD COLUMN monto_sugerido REAL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tipo_cuota ADD COLUMN activo INTEGER NOT NULL DEFAULT 1');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tipo_cuota ADD COLUMN es_fijo INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}

      // 3. Ampliar tabla cuota
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN monto_pagado REAL NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN concepto TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN fecha_vencimiento TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN id_lote TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN registrado_por TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN motivo_anulacion TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN id_reunion TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cuota ADD COLUMN id_ronda TEXT');
      } catch (_) {}

      // 4. Crear tabla pago
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pago (
          id_pago       TEXT PRIMARY KEY,
          id_cuota      TEXT NOT NULL,
          monto         REAL NOT NULL,
          fecha         TEXT NOT NULL,
          metodo        TEXT NOT NULL DEFAULT 'efectivo',
          nro_recibo    TEXT NOT NULL UNIQUE,
          observacion   TEXT,
          id_usuario    TEXT NOT NULL,
          created_at    TEXT NOT NULL,
          updated_at    TEXT NOT NULL,
          sincronizado  INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (id_cuota) REFERENCES cuota (id_cuota) ON DELETE CASCADE,
          FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        )
      ''');

      // 5. Crear tablas de Reuniones y Pasanaco
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reunion (
          id_reunion    TEXT PRIMARY KEY,
          fecha         TEXT NOT NULL,
          tema          TEXT NOT NULL,
          monto_multa   REAL NOT NULL DEFAULT 50.0,
          estado        TEXT NOT NULL DEFAULT 'pendiente',
          cerrada_en    TEXT,
          created_at    TEXT NOT NULL,
          updated_at    TEXT NOT NULL,
          sincronizado  INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS asistencia_reunion (
          id_asistencia_reunion TEXT PRIMARY KEY,
          id_reunion            TEXT NOT NULL,
          id_conductor          TEXT NOT NULL,
          estado                TEXT NOT NULL DEFAULT 'falta',
          created_at            TEXT NOT NULL,
          updated_at            TEXT NOT NULL,
          sincronizado          INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (id_reunion) REFERENCES reunion (id_reunion) ON DELETE CASCADE,
          FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS pasanaco (
          id_pasanaco   TEXT PRIMARY KEY,
          nombre        TEXT NOT NULL,
          monto_aporte  REAL NOT NULL,
          periodicidad  TEXT NOT NULL DEFAULT 'semanal',
          fecha_inicio  TEXT NOT NULL,
          estado        TEXT NOT NULL DEFAULT 'activo',
          created_at    TEXT NOT NULL,
          updated_at    TEXT NOT NULL,
          sincronizado  INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS participante_pasanaco (
          id_participante TEXT PRIMARY KEY,
          id_pasanaco     TEXT NOT NULL,
          id_conductor    TEXT NOT NULL,
          numero_turno    INTEGER NOT NULL,
          created_at      TEXT NOT NULL,
          updated_at      TEXT NOT NULL,
          sincronizado    INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (id_pasanaco) REFERENCES pasanaco (id_pasanaco) ON DELETE CASCADE,
          FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ronda_pasanaco (
          id_ronda                  TEXT PRIMARY KEY,
          id_pasanaco               TEXT NOT NULL,
          numero_ronda              INTEGER NOT NULL,
          id_conductor_beneficiario TEXT NOT NULL,
          fecha_limite              TEXT NOT NULL,
          monto_total               REAL NOT NULL,
          estado                    TEXT NOT NULL DEFAULT 'pendiente',
          fecha_entrega             TEXT,
          created_at                TEXT NOT NULL,
          updated_at                TEXT NOT NULL,
          sincronizado              INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (id_pasanaco) REFERENCES pasanaco (id_pasanaco) ON DELETE CASCADE,
          FOREIGN KEY (id_conductor_beneficiario) REFERENCES conductor (id_conductor)
        )
      ''');

      // Índices
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pago_cuota ON pago (id_cuota)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pago_fecha ON pago (fecha)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cuota_lote ON cuota (id_lote)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_reunion_fecha ON reunion (fecha)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pasanaco_estado ON pasanaco (estado)');
    }

    if (oldVersion < 5) {
      // Limpiar completamente cualquier cuota previa para que el usuario inicie desde cero
      await db.delete('pago');
      await db.delete('cuota');
      await db.delete('tipo_cuota');
    }

    if (oldVersion < 6) {
      await _seedConductores(db, _now());
    }

    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE tipo_cuota ADD COLUMN descripcion TEXT');
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // CREACIÓN DE TABLAS
  // ---------------------------------------------------------------------------
  // Columnas de sincronización en todas las tablas:
  //   created_at, updated_at (texto ISO8601) y sincronizado (0 = pendiente, 1 = subido)

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id_usuario     TEXT PRIMARY KEY,
        rol            TEXT NOT NULL
                       CHECK (rol IN ('superadmin','admin','supervisor','conductor','tesorero')),
        nombre         TEXT NOT NULL,
        estado         TEXT NOT NULL DEFAULT 'activo',
        gmail          TEXT UNIQUE,
        password       TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        created_at     TEXT NOT NULL,
        updated_at     TEXT NOT NULL,
        sincronizado   INTEGER NOT NULL DEFAULT 0,
        -- Solo el conductor puede no tener correo (entra con su CI)
        CHECK (rol = 'conductor' OR gmail IS NOT NULL)
      )
    ''');

    await db.execute('''
      CREATE TABLE conductor (
        id_conductor         TEXT PRIMARY KEY,
        id_usuario           TEXT NOT NULL UNIQUE,
        nombre               TEXT NOT NULL,
        ci                   TEXT NOT NULL UNIQUE,
        licencia             TEXT,
        fecha_incorporacion  TEXT,
        estado               TEXT NOT NULL DEFAULT 'activo',
        telefono             TEXT,
        fecha_nacimiento     TEXT,
        direccion            TEXT,
        estado_civil         TEXT,
        foto                 TEXT,
        licencia_categoria   TEXT,
        licencia_emision     TEXT,
        licencia_vencimiento TEXT,
        created_at           TEXT NOT NULL,
        updated_at           TEXT NOT NULL,
        sincronizado         INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE automovil (
        id_auto                TEXT PRIMARY KEY,
        placa                  TEXT NOT NULL UNIQUE,
        ruat                   TEXT,
        soat                   TEXT,
        fecha_vencimiento_soat TEXT,
        foto                   TEXT,
        marca                  TEXT,
        modelo                 TEXT,
        color                  TEXT,
        capacidad              INTEGER,
        created_at             TEXT NOT NULL,
        updated_at             TEXT NOT NULL,
        sincronizado           INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE conductor_automovil (
        id_conductor TEXT NOT NULL,
        id_auto      TEXT NOT NULL,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id_conductor, id_auto),
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_auto) REFERENCES automovil (id_auto)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE punto_de_control (
        id_punto     TEXT PRIMARY KEY,
        nombre       TEXT NOT NULL,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE asistencia (
        id_asistencia TEXT PRIMARY KEY,
        id_conductor  TEXT NOT NULL,
        id_punto      TEXT NOT NULL,
        fecha         TEXT NOT NULL,
        hora_llegada  TEXT NOT NULL,
        estado        TEXT NOT NULL DEFAULT 'presente',
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_punto) REFERENCES punto_de_control (id_punto)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE vueltas (
        id_vuelta     TEXT PRIMARY KEY,
        id_conductor  TEXT NOT NULL,
        id_asistencia TEXT,
        fecha         TEXT NOT NULL,
        hora          TEXT NOT NULL,
        tipo          TEXT,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_asistencia) REFERENCES asistencia (id_asistencia)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tipo_cuota (
        id_tipo_cuota  TEXT PRIMARY KEY,
        nombre         TEXT NOT NULL UNIQUE,
        descripcion    TEXT,
        monto_sugerido REAL DEFAULT 0,
        activo         INTEGER NOT NULL DEFAULT 1,
        es_fijo        INTEGER NOT NULL DEFAULT 0,
        created_at     TEXT NOT NULL,
        updated_at     TEXT NOT NULL,
        sincronizado   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cuota (
        id_cuota          TEXT PRIMARY KEY,
        id_conductor      TEXT NOT NULL,
        id_tipo_cuota     TEXT NOT NULL,
        monto             REAL NOT NULL,
        monto_pagado      REAL NOT NULL DEFAULT 0,
        fecha             TEXT NOT NULL,
        fecha_vencimiento TEXT,
        concepto          TEXT,
        id_lote           TEXT,
        registrado_por    TEXT,
        estado            TEXT NOT NULL DEFAULT 'pendiente',
        motivo_anulacion  TEXT,
        id_reunion        TEXT,
        id_ronda          TEXT,
        created_at        TEXT NOT NULL,
        updated_at        TEXT NOT NULL,
        sincronizado      INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_tipo_cuota) REFERENCES tipo_cuota (id_tipo_cuota)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE pago (
        id_pago       TEXT PRIMARY KEY,
        id_cuota      TEXT NOT NULL,
        monto         REAL NOT NULL,
        fecha         TEXT NOT NULL,
        metodo        TEXT NOT NULL DEFAULT 'efectivo',
        nro_recibo    TEXT NOT NULL UNIQUE,
        observacion   TEXT,
        id_usuario    TEXT NOT NULL,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_cuota) REFERENCES cuota (id_cuota) ON DELETE CASCADE,
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
      )
    ''');

    await db.execute('''
      CREATE TABLE reunion (
        id_reunion    TEXT PRIMARY KEY,
        fecha         TEXT NOT NULL,
        tema          TEXT NOT NULL,
        monto_multa   REAL NOT NULL DEFAULT 50.0,
        estado        TEXT NOT NULL DEFAULT 'pendiente',
        cerrada_en    TEXT,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE asistencia_reunion (
        id_asistencia_reunion TEXT PRIMARY KEY,
        id_reunion            TEXT NOT NULL,
        id_conductor          TEXT NOT NULL,
        estado                TEXT NOT NULL DEFAULT 'falta',
        created_at            TEXT NOT NULL,
        updated_at            TEXT NOT NULL,
        sincronizado          INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_reunion) REFERENCES reunion (id_reunion) ON DELETE CASCADE,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pasanaco (
        id_pasanaco   TEXT PRIMARY KEY,
        nombre        TEXT NOT NULL,
        monto_aporte  REAL NOT NULL,
        periodicidad  TEXT NOT NULL DEFAULT 'semanal',
        fecha_inicio  TEXT NOT NULL,
        estado        TEXT NOT NULL DEFAULT 'activo',
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE participante_pasanaco (
        id_participante TEXT PRIMARY KEY,
        id_pasanaco     TEXT NOT NULL,
        id_conductor    TEXT NOT NULL,
        numero_turno    INTEGER NOT NULL,
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL,
        sincronizado    INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_pasanaco) REFERENCES pasanaco (id_pasanaco) ON DELETE CASCADE,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ronda_pasanaco (
        id_ronda                  TEXT PRIMARY KEY,
        id_pasanaco               TEXT NOT NULL,
        numero_ronda              INTEGER NOT NULL,
        id_conductor_beneficiario TEXT NOT NULL,
        fecha_limite              TEXT NOT NULL,
        monto_total               REAL NOT NULL,
        estado                    TEXT NOT NULL DEFAULT 'pendiente',
        fecha_entrega             TEXT,
        created_at                TEXT NOT NULL,
        updated_at                TEXT NOT NULL,
        sincronizado              INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_pasanaco) REFERENCES pasanaco (id_pasanaco) ON DELETE CASCADE,
        FOREIGN KEY (id_conductor_beneficiario) REFERENCES conductor (id_conductor)
      )
    ''');

    await db.execute('''
      CREATE TABLE sancion (
        id_sancion        TEXT PRIMARY KEY,
        id_conductor      TEXT NOT NULL,
        id_asistencia     TEXT,
        motivo            TEXT NOT NULL,
        vueltas_asignadas INTEGER NOT NULL DEFAULT 0,
        vueltas_cumplidas INTEGER NOT NULL DEFAULT 0,
        estado            TEXT NOT NULL DEFAULT 'pendiente',
        fecha             TEXT NOT NULL,
        hora              TEXT NOT NULL,
        created_at        TEXT NOT NULL,
        updated_at        TEXT NOT NULL,
        sincronizado      INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_asistencia) REFERENCES asistencia (id_asistencia)
          ON DELETE SET NULL
      )
    ''');

    // Índices para las consultas más comunes
    await db.execute(
        'CREATE INDEX idx_asistencia_conductor ON asistencia (id_conductor, fecha)');
    await db.execute(
        'CREATE INDEX idx_vueltas_conductor ON vueltas (id_conductor, fecha)');
    await db.execute(
        'CREATE INDEX idx_cuota_conductor ON cuota (id_conductor, estado)');
    await db.execute(
        'CREATE INDEX idx_cuota_lote ON cuota (id_lote)');
    await db.execute(
        'CREATE INDEX idx_pago_cuota ON pago (id_cuota)');
    await db.execute(
        'CREATE INDEX idx_pago_fecha ON pago (fecha)');
    await db.execute(
        'CREATE INDEX idx_sancion_conductor ON sancion (id_conductor, estado)');
    await db.execute(
        'CREATE INDEX idx_reunion_fecha ON reunion (fecha)');
    await db.execute(
        'CREATE INDEX idx_pasanaco_estado ON pasanaco (estado)');

    await _seed(db);
  }

  /// Datos iniciales: Único usuario predeterminado del sistema (superadmin) y los 7 tipos de cuota base.
  Future<void> _seed(Database db) async {
    final now = _now();

    // 1. Único usuario maestro predeterminado: SUPERADMIN
    await db.insert('usuario', {
      'id_usuario': _uuid.v4(),
      'rol': 'superadmin',
      'nombre': 'Super Administrador',
      'estado': 'activo',
      'gmail': 'superadmin@continental.com',
      'password': hashPassword('super123'),
      'fecha_creacion': now,
      'created_at': now,
      'updated_at': now,
      'sincronizado': 0,
    });



    for (final nombre in ['Parada Central', 'Terminal Central']) {
      await db.insert('punto_de_control', {
        'id_punto': _uuid.v4(),
        'nombre': nombre,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });
    }

    // 2. Siembra de los 20 conductores oficiales del sindicato con sus vehículos
    await _seedConductores(db, now);
  }

  /// Siembra los 20 conductores institucionales con su usuario, licencia y vehículo asignado.
  Future<void> _seedConductores(Database db, String now) async {
    for (final c in conductoresSeed) {
      final existe = await db.query(
        'conductor',
        where: 'ci = ?',
        whereArgs: [c['ci']],
        limit: 1,
      );
      if (existe.isNotEmpty) continue;

      final idUsuario = _uuid.v4();
      final idConductor = _uuid.v4();
      final idAuto = _uuid.v4();

      await db.insert('usuario', {
        'id_usuario': idUsuario,
        'rol': 'conductor',
        'nombre': c['nombre'],
        'estado': 'activo',
        'gmail': c['gmail'],
        'password': hashPassword(c['password']),
        'fecha_creacion': now,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      await db.insert('conductor', {
        'id_conductor': idConductor,
        'id_usuario': idUsuario,
        'nombre': c['nombre'],
        'ci': c['ci'],
        'licencia': c['licencia'],
        'fecha_incorporacion': now.substring(0, 10),
        'estado': 'activo',
        'telefono': c['telefono'],
        'fecha_nacimiento': c['fecha_nacimiento'],
        'direccion': c['direccion'],
        'estado_civil': c['estado_civil'],
        'foto': null,
        'licencia_categoria': c['licencia_categoria'],
        'licencia_emision': c['licencia_emision'],
        'licencia_vencimiento': c['licencia_vencimiento'],
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      await db.insert('automovil', {
        'id_auto': idAuto,
        'placa': c['placa'],
        'marca': c['marca'],
        'modelo': c['modelo'],
        'color': c['color'],
        'capacidad': c['capacidad'],
        'soat': c['soat'],
        'fecha_vencimiento_soat': c['fecha_vencimiento_soat'],
        'ruat': c['ruat'],
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      await db.insert(
        'conductor_automovil',
        {
          'id_conductor': idConductor,
          'id_auto': idAuto,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES
  // ---------------------------------------------------------------------------

  String _now() => DateTime.now().toIso8601String();

  /// Hash SHA-256 (suficiente para la demo local).
  /// Cuando pasemos a la nube, la contraseña la manejará el servidor.
  String hashPassword(String plain) =>
      sha256.convert(utf8.encode(plain)).toString();

  // ---------------------------------------------------------------------------
  // CRUD GENÉRICO (sirve para todas las tablas con llave primaria simple)
  // ---------------------------------------------------------------------------

  /// CREATE: genera el id (UUID) y los campos de sincronización.
  /// Devuelve el id creado.
  Future<String> insertar(String tabla, Map<String, dynamic> datos) async {
    final db = await database;
    final pk = _pk[tabla]!;
    final now = _now();
    final id = (datos[pk] as String?) ?? _uuid.v4();

    await db.insert(
      tabla,
      {
        ...datos,
        pk: id,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return id;
  }

  /// READ: todos los registros (con filtro y orden opcionales).
  Future<List<Map<String, dynamic>>> listar(
    String tabla, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(
      tabla,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  /// READ: un registro por id.
  Future<Map<String, dynamic>?> obtener(String tabla, String id) async {
    final db = await database;
    final res = await db.query(
      tabla,
      where: '${_pk[tabla]} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return res.isEmpty ? null : res.first;
  }

  /// UPDATE: actualiza campos y marca el registro como pendiente de sincronizar.
  Future<int> actualizar(
    String tabla,
    String id,
    Map<String, dynamic> datos,
  ) async {
    final db = await database;
    return db.update(
      tabla,
      {
        ...datos,
        'updated_at': _now(),
        'sincronizado': 0,
      },
      where: '${_pk[tabla]} = ?',
      whereArgs: [id],
    );
  }

  /// DELETE: elimina por id.
  Future<int> eliminar(String tabla, String id) async {
    final db = await database;
    return db.delete(
      tabla,
      where: '${_pk[tabla]} = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // AUTENTICACIÓN (login_screen / register_screen)
  // ---------------------------------------------------------------------------

  /// Login con CORREO o CI en un solo campo.
  /// - Si [identificador] contiene '@' → busca por correo (cualquier rol).
  /// - Si no → lo trata como CI y busca en la ficha del conductor.
  /// Devuelve el usuario (incluye 'rol') si las credenciales son correctas
  /// y la cuenta está activa; si no, null.
  Future<Map<String, dynamic>?> login(
    String identificador,
    String password,
  ) async {
    final db = await database;
    final id = identificador.trim();
    final hash = hashPassword(password);

    final List<Map<String, dynamic>> res;
    if (id.contains('@')) {
      res = await db.query(
        'usuario',
        where: 'gmail = ? AND password = ? AND estado = ?',
        whereArgs: [id.toLowerCase(), hash, 'activo'],
        limit: 1,
      );
    } else {
      res = await db.rawQuery('''
        SELECT u.*
        FROM usuario u
        JOIN conductor c ON c.id_usuario = u.id_usuario
        WHERE c.ci = ? AND u.password = ? AND u.estado = 'activo'
        LIMIT 1
      ''', [id, hash]);
    }
    return res.isEmpty ? null : res.first;
  }

  /// Crea un usuario de personal (superadmin, admin o supervisor).
  /// Siempre requiere correo, porque no tienen CI en el sistema.
  Future<String> crearUsuarioStaff({
    required String rol,
    required String nombre,
    required String gmail,
    required String password,
  }) async {
    assert(['superadmin', 'admin', 'supervisor'].contains(rol));
    final db = await database;
    final now = _now();
    final id = _uuid.v4();
    await db.insert('usuario', {
      'id_usuario': id,
      'rol': rol,
      'nombre': nombre,
      'estado': 'activo',
      'gmail': gmail.trim().toLowerCase(),
      'password': hashPassword(password),
      'fecha_creacion': now,
      'created_at': now,
      'updated_at': now,
      'sincronizado': 0,
    });
    return id;
  }

  /// Lista todos los usuarios con datos de conductor y vehículo si corresponde.
  Future<List<Map<String, dynamic>>> usuariosDetalle({
    String? rol,
    String? busqueda,
  }) async {
    final db = await database;
    final condiciones = <String>[];
    final args = <Object?>[];

    if (rol != null && rol != 'todos') {
      condiciones.add('u.rol = ?');
      args.add(rol);
    }

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final q = '%${busqueda.trim().toLowerCase()}%';
      condiciones.add('(LOWER(u.nombre) LIKE ? OR LOWER(COALESCE(u.gmail, "")) LIKE ? OR LOWER(COALESCE(c.ci, "")) LIKE ?)');
      args.addAll([q, q, q]);
    }

    final where = condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    return db.rawQuery('''
      SELECT u.id_usuario, u.rol, u.nombre, u.gmail, u.estado, u.fecha_creacion,
             c.id_conductor, c.ci, c.licencia,
             a.id_auto, a.placa
      FROM usuario u
      LEFT JOIN conductor c ON c.id_usuario = u.id_usuario
      LEFT JOIN conductor_automovil ca ON ca.id_conductor = c.id_conductor
      LEFT JOIN automovil a ON a.id_auto = ca.id_auto
      $where
      ORDER BY u.fecha_creacion DESC
    ''', args);
  }

  /// Crea cualquier tipo de usuario en el sistema con su correspondiente rol,
  /// estado y credenciales hasheadas con SHA-256.
  Future<String> crearUsuarioCompleto({
    required String rol,
    required String nombre,
    String? gmail,
    String? ci,
    required String password,
    String estado = 'activo',
    String? placa,
    String? licencia,
    String? telefono,
    String? fechaNacimiento,
    String? direccion,
    String? estadoCivil,
    String? foto,
    String? licenciaCategoria,
    String? licenciaEmision,
    String? licenciaVencimiento,
    String? marca,
    String? modelo,
    String? color,
    int? capacidad,
    String? soat,
    String? fechaVencimientoSoat,
    String? ruat,
  }) async {
    final db = await database;
    final now = _now();
    final idUsuario = _uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('usuario', {
        'id_usuario': idUsuario,
        'rol': rol,
        'nombre': nombre,
        'estado': estado,
        'gmail': (gmail != null && gmail.trim().isNotEmpty)
            ? gmail.trim().toLowerCase()
            : null,
        'password': hashPassword(password),
        'fecha_creacion': now,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      if (rol == 'conductor') {
        final idConductor = _uuid.v4();
        await txn.insert('conductor', {
          'id_conductor': idConductor,
          'id_usuario': idUsuario,
          'nombre': nombre,
          'ci': ci ?? '',
          'licencia': licencia,
          'fecha_incorporacion': now.substring(0, 10),
          'estado': estado,
          'telefono': telefono,
          'fecha_nacimiento': fechaNacimiento,
          'direccion': direccion,
          'estado_civil': estadoCivil,
          'foto': foto,
          'licencia_categoria': licenciaCategoria,
          'licencia_emision': licenciaEmision,
          'licencia_vencimiento': licenciaVencimiento,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });

        if (placa != null && placa.trim().isNotEmpty) {
          final placaLimpia = placa.trim().toUpperCase();
          final autoExistente = await txn.query(
            'automovil',
            where: 'placa = ?',
            whereArgs: [placaLimpia],
            limit: 1,
          );

          final String idAuto;
          if (autoExistente.isNotEmpty) {
            idAuto = autoExistente.first['id_auto'] as String;
            final Map<String, dynamic> datosAuto = {
              'updated_at': now,
              'sincronizado': 0,
            };
            if (marca != null) datosAuto['marca'] = marca;
            if (modelo != null) datosAuto['modelo'] = modelo;
            if (color != null) datosAuto['color'] = color;
            if (capacidad != null) datosAuto['capacidad'] = capacidad;
            if (soat != null) datosAuto['soat'] = soat;
            if (fechaVencimientoSoat != null) datosAuto['fecha_vencimiento_soat'] = fechaVencimientoSoat;
            if (ruat != null) datosAuto['ruat'] = ruat;

            await txn.update(
              'automovil',
              datosAuto,
              where: 'id_auto = ?',
              whereArgs: [idAuto],
            );
          } else {
            idAuto = _uuid.v4();
            await txn.insert('automovil', {
              'id_auto': idAuto,
              'placa': placaLimpia,
              'marca': marca,
              'modelo': modelo,
              'color': color,
              'capacidad': capacidad,
              'soat': soat,
              'fecha_vencimiento_soat': fechaVencimientoSoat,
              'ruat': ruat,
              'created_at': now,
              'updated_at': now,
              'sincronizado': 0,
            });
          }

          await txn.insert(
            'conductor_automovil',
            {
              'id_conductor': idConductor,
              'id_auto': idAuto,
              'created_at': now,
              'updated_at': now,
              'sincronizado': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });

    return idUsuario;
  }

  /// Actualiza los datos de un usuario, su rol, su estado y opcionalmente sus datos de conductor y vehículo.
  Future<void> actualizarUsuarioCompleto({
    required String idUsuario,
    required String nombre,
    String? gmail,
    required String rol,
    required String estado,
    String? newPassword,
    String? ci,
    String? licencia,
    String? telefono,
    String? fechaNacimiento,
    String? direccion,
    String? estadoCivil,
    String? foto,
    String? licenciaCategoria,
    String? licenciaEmision,
    String? licenciaVencimiento,
    String? placa,
    String? marca,
    String? modelo,
    String? color,
    int? capacidad,
    String? soat,
    String? fechaVencimientoSoat,
    String? ruat,
  }) async {
    final db = await database;
    final now = _now();

    final Map<String, dynamic> datosUsuario = {
      'nombre': nombre,
      'rol': rol,
      'estado': estado,
      'gmail': (gmail != null && gmail.trim().isNotEmpty)
          ? gmail.trim().toLowerCase()
          : null,
      'updated_at': now,
      'sincronizado': 0,
    };

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      datosUsuario['password'] = hashPassword(newPassword.trim());
    }

    await db.transaction((txn) async {
      await txn.update(
        'usuario',
        datosUsuario,
        where: 'id_usuario = ?',
        whereArgs: [idUsuario],
      );

      // Si es conductor, actualizamos o insertamos la ficha conductor correspondiente
      if (rol == 'conductor') {
        final cond = await txn.query(
          'conductor',
          where: 'id_usuario = ?',
          whereArgs: [idUsuario],
        );
        String idConductor;
        if (cond.isNotEmpty) {
          idConductor = cond.first['id_conductor'] as String;
          final Map<String, dynamic> datosCond = {
            'nombre': nombre,
            'ci': ci ?? cond.first['ci'],
            'licencia': licencia ?? cond.first['licencia'],
            'estado': estado,
            'updated_at': now,
            'sincronizado': 0,
          };
          if (telefono != null) datosCond['telefono'] = telefono;
          if (fechaNacimiento != null) datosCond['fecha_nacimiento'] = fechaNacimiento;
          if (direccion != null) datosCond['direccion'] = direccion;
          if (estadoCivil != null) datosCond['estado_civil'] = estadoCivil;
          if (foto != null) datosCond['foto'] = foto;
          if (licenciaCategoria != null) datosCond['licencia_categoria'] = licenciaCategoria;
          if (licenciaEmision != null) datosCond['licencia_emision'] = licenciaEmision;
          if (licenciaVencimiento != null) datosCond['licencia_vencimiento'] = licenciaVencimiento;

          await txn.update(
            'conductor',
            datosCond,
            where: 'id_usuario = ?',
            whereArgs: [idUsuario],
          );
        } else {
          idConductor = _uuid.v4();
          await txn.insert('conductor', {
            'id_conductor': idConductor,
            'id_usuario': idUsuario,
            'nombre': nombre,
            'ci': ci ?? '',
            'licencia': licencia,
            'fecha_incorporacion': now.substring(0, 10),
            'estado': estado,
            'telefono': telefono,
            'fecha_nacimiento': fechaNacimiento,
            'direccion': direccion,
            'estado_civil': estadoCivil,
            'foto': foto,
            'licencia_categoria': licenciaCategoria,
            'licencia_emision': licenciaEmision,
            'licencia_vencimiento': licenciaVencimiento,
            'created_at': now,
            'updated_at': now,
            'sincronizado': 0,
          });
        }

        if (placa != null && placa.trim().isNotEmpty) {
          final placaLimpia = placa.trim().toUpperCase();
          final autos = await txn.query('automovil', where: 'placa = ?', whereArgs: [placaLimpia], limit: 1);
          String idAuto;
          if (autos.isNotEmpty) {
            idAuto = autos.first['id_auto'] as String;
            final Map<String, dynamic> datosAuto = {
              'updated_at': now,
              'sincronizado': 0,
            };
            if (marca != null) datosAuto['marca'] = marca;
            if (modelo != null) datosAuto['modelo'] = modelo;
            if (color != null) datosAuto['color'] = color;
            if (capacidad != null) datosAuto['capacidad'] = capacidad;
            if (soat != null) datosAuto['soat'] = soat;
            if (fechaVencimientoSoat != null) datosAuto['fecha_vencimiento_soat'] = fechaVencimientoSoat;
            if (ruat != null) datosAuto['ruat'] = ruat;

            await txn.update(
              'automovil',
              datosAuto,
              where: 'id_auto = ?',
              whereArgs: [idAuto],
            );
          } else {
            idAuto = _uuid.v4();
            await txn.insert('automovil', {
              'id_auto': idAuto,
              'placa': placaLimpia,
              'marca': marca,
              'modelo': modelo,
              'color': color,
              'capacidad': capacidad,
              'soat': soat,
              'fecha_vencimiento_soat': fechaVencimientoSoat,
              'ruat': ruat,
              'created_at': now,
              'updated_at': now,
              'sincronizado': 0,
            });
          }
          await txn.insert(
            'conductor_automovil',
            {
              'id_conductor': idConductor,
              'id_auto': idAuto,
              'created_at': now,
              'updated_at': now,
              'sincronizado': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  /// Activa o desactiva un usuario (y su ficha de conductor asociada).
  Future<void> cambiarEstadoUsuario(String idUsuario, String nuevoEstado) async {
    final db = await database;
    final now = _now();
    await db.transaction((txn) async {
      await txn.update(
        'usuario',
        {
          'estado': nuevoEstado,
          'updated_at': now,
          'sincronizado': 0,
        },
        where: 'id_usuario = ?',
        whereArgs: [idUsuario],
      );
      await txn.update(
        'conductor',
        {
          'estado': nuevoEstado,
          'updated_at': now,
          'sincronizado': 0,
        },
        where: 'id_usuario = ?',
        whereArgs: [idUsuario],
      );
    });
  }

  /// Elimina un usuario por completo (su ficha de conductor y relaciones se eliminan en cascada).
  Future<void> eliminarUsuarioCompleto(String idUsuario) async {
    final db = await database;
    await db.delete(
      'usuario',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  /// Actualiza únicamente la foto de perfil de un conductor.
  Future<void> actualizarFotoConductor(String idConductor, String? foto) async {
    final db = await database;
    await db.update(
      'conductor',
      {
        'foto': (foto != null && foto.trim().isNotEmpty) ? foto.trim() : null,
        'updated_at': _now(),
        'sincronizado': 0,
      },
      where: 'id_conductor = ?',
      whereArgs: [idConductor],
    );
  }

  /// Registra un usuario (rol conductor) y su ficha de conductor en una sola
  /// transacción: si algo falla, no se guarda nada.
  /// El correo es opcional: el conductor puede entrar solo con su CI.
  Future<String> registrarConductor({
    required String nombre,
    String? gmail,
    required String password,
    required String ci,
    String? licencia,
    String? fechaIncorporacion,
  }) async {
    final db = await database;
    final now = _now();
    final idUsuario = _uuid.v4();
    final idConductor = _uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('usuario', {
        'id_usuario': idUsuario,
        'rol': 'conductor',
        'nombre': nombre,
        'estado': 'activo',
        'gmail': (gmail == null || gmail.trim().isEmpty)
            ? null
            : gmail.trim().toLowerCase(),
        'password': hashPassword(password),
        'fecha_creacion': now,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });
      await txn.insert('conductor', {
        'id_conductor': idConductor,
        'id_usuario': idUsuario,
        'nombre': nombre,
        'ci': ci,
        'licencia': licencia,
        'fecha_incorporacion': fechaIncorporacion,
        'estado': 'activo',
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });
    });
    return idConductor;
  }

  /// Conductor asociado a un usuario (para el conductor que inicia sesión).
  Future<Map<String, dynamic>?> conductorDeUsuario(String idUsuario) async {
    final db = await database;
    final res = await db.query(
      'conductor',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      limit: 1,
    );
    return res.isEmpty ? null : res.first;
  }

  // ---------------------------------------------------------------------------
  // CONSULTAS CON JOIN (para las pantallas)
  // ---------------------------------------------------------------------------

  /// conductores_screen: conductores con su(s) auto(s) y datos ampliados.
  Future<List<Map<String, dynamic>>> conductoresConAuto() async {
    final db = await database;
    return db.rawQuery('''
      SELECT 
        c.id_conductor, c.id_usuario, c.nombre, c.ci, c.licencia,
        c.fecha_incorporacion, c.estado, c.telefono, c.fecha_nacimiento,
        c.direccion, c.estado_civil, c.foto, c.licencia_categoria,
        c.licencia_emision, c.licencia_vencimiento, c.created_at, c.updated_at,
        u.gmail,
        a.id_auto, a.placa, a.marca, a.modelo, a.color, a.capacidad,
        a.ruat, a.soat, a.fecha_vencimiento_soat
      FROM conductor c
      LEFT JOIN usuario u ON u.id_usuario = c.id_usuario
      LEFT JOIN conductor_automovil ca ON ca.id_conductor = c.id_conductor
      LEFT JOIN automovil a ON a.id_auto = ca.id_auto
      ORDER BY c.nombre
    ''');
  }

  /// Obtiene la ficha completa y detallada de un conductor por su id_conductor.
  Future<Map<String, dynamic>?> fichaConductor(String idConductor) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        c.id_conductor, c.id_usuario, c.nombre, c.ci, c.licencia,
        c.fecha_incorporacion, c.estado, c.telefono, c.fecha_nacimiento,
        c.direccion, c.estado_civil, c.foto, c.licencia_categoria,
        c.licencia_emision, c.licencia_vencimiento, c.created_at, c.updated_at,
        u.gmail,
        a.id_auto, a.placa, a.marca, a.modelo, a.color, a.capacidad,
        a.ruat, a.soat, a.fecha_vencimiento_soat
      FROM conductor c
      LEFT JOIN usuario u ON u.id_usuario = c.id_usuario
      LEFT JOIN conductor_automovil ca ON ca.id_conductor = c.id_conductor
      LEFT JOIN automovil a ON a.id_auto = ca.id_auto
      WHERE c.id_conductor = ?
      LIMIT 1
    ''', [idConductor]);
    return res.isEmpty ? null : res.first;
  }

  /// Asigna un auto a un conductor.
  Future<void> asignarAuto(String idConductor, String idAuto) async {
    final db = await database;
    final now = _now();
    await db.insert(
      'conductor_automovil',
      {
        'id_conductor': idConductor,
        'id_auto': idAuto,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Quita un auto a un conductor.
  Future<void> quitarAuto(String idConductor, String idAuto) async {
    final db = await database;
    await db.delete(
      'conductor_automovil',
      where: 'id_conductor = ? AND id_auto = ?',
      whereArgs: [idConductor, idAuto],
    );
  }

  /// asistencia_screen: asistencias con nombre de conductor y punto.
  /// Si [idConductor] es null (admin), trae las de todos.
  Future<List<Map<String, dynamic>>> asistenciasDetalle({
    String? idConductor,
    String? fecha,
  }) async {
    final db = await database;
    final condiciones = <String>[];
    final args = <Object?>[];
    if (idConductor != null) {
      condiciones.add('a.id_conductor = ?');
      args.add(idConductor);
    }
    if (fecha != null) {
      condiciones.add('a.fecha = ?');
      args.add(fecha);
    }
    final where = condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    return db.rawQuery('''
      SELECT a.*, c.nombre AS conductor_nombre, p.nombre AS punto_nombre
      FROM asistencia a
      JOIN conductor c ON c.id_conductor = a.id_conductor
      JOIN punto_de_control p ON p.id_punto = a.id_punto
      $where
      ORDER BY a.fecha DESC, a.hora_llegada DESC
    ''', args);
  }

  /// vueltas_screen: vueltas con nombre del conductor.
  Future<List<Map<String, dynamic>>> vueltasDetalle({
    String? idConductor,
    String? fecha,
  }) async {
    final db = await database;
    final condiciones = <String>[];
    final args = <Object?>[];
    if (idConductor != null) {
      condiciones.add('v.id_conductor = ?');
      args.add(idConductor);
    }
    if (fecha != null) {
      condiciones.add('v.fecha = ?');
      args.add(fecha);
    }
    final where = condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    return db.rawQuery('''
      SELECT v.*, c.nombre AS conductor_nombre
      FROM vueltas v
      JOIN conductor c ON c.id_conductor = v.id_conductor
      $where
      ORDER BY v.fecha DESC, v.hora DESC
    ''', args);
  }

  /// sanciones_screen: sanciones con nombre del conductor.
  Future<List<Map<String, dynamic>>> sancionesDetalle({
    String? idConductor,
    String? estado,
  }) async {
    final db = await database;
    final condiciones = <String>[];
    final args = <Object?>[];
    if (idConductor != null) {
      condiciones.add('s.id_conductor = ?');
      args.add(idConductor);
    }
    if (estado != null) {
      condiciones.add('s.estado = ?');
      args.add(estado);
    }
    final where = condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    return db.rawQuery('''
      SELECT s.*, c.nombre AS conductor_nombre
      FROM sancion s
      JOIN conductor c ON c.id_conductor = s.id_conductor
      $where
      ORDER BY s.fecha DESC, s.hora DESC
    ''', args);
  }

  /// control_economico_screen: cuotas con conductor, tipo y saldo calculado.
  Future<List<Map<String, dynamic>>> cuotasDetalle({
    String? idConductor,
    String? estado,
    String? idTipoCuota,
    String? fechaDesde,
    String? fechaHasta,
    String? busqueda,
  }) async {
    final db = await database;
    final condiciones = <String>[];
    final args = <Object?>[];

    if (idConductor != null && idConductor.isNotEmpty) {
      condiciones.add('q.id_conductor = ?');
      args.add(idConductor);
    }
    if (estado != null && estado.isNotEmpty && estado.toLowerCase() != 'todos') {
      condiciones.add('LOWER(q.estado) = ?');
      args.add(estado.toLowerCase());
    }
    if (idTipoCuota != null && idTipoCuota.isNotEmpty && idTipoCuota != 'todos') {
      condiciones.add('q.id_tipo_cuota = ?');
      args.add(idTipoCuota);
    }
    if (fechaDesde != null && fechaDesde.isNotEmpty) {
      condiciones.add('q.fecha >= ?');
      args.add(fechaDesde);
    }
    if (fechaHasta != null && fechaHasta.isNotEmpty) {
      condiciones.add('q.fecha <= ?');
      args.add(fechaHasta);
    }
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final q = '%${busqueda.trim().toLowerCase()}%';
      condiciones.add('(LOWER(c.nombre) LIKE ? OR LOWER(c.ci) LIKE ? OR LOWER(COALESCE(q.concepto, \'\')) LIKE ?)');
      args.addAll([q, q, q]);
    }

    final where = condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    return db.rawQuery('''
      SELECT 
        q.*, 
        c.nombre AS conductor_nombre, 
        c.ci AS conductor_ci, 
        c.foto AS conductor_foto,
        t.nombre AS tipo_nombre,
        (q.monto - COALESCE(q.monto_pagado, 0)) AS saldo
      FROM cuota q
      JOIN conductor c ON c.id_conductor = q.id_conductor
      JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
      $where
      ORDER BY q.fecha DESC, q.created_at DESC
    ''', args);
  }

  // ---------------------------------------------------------------------------
  // RESÚMENES (home_screen / informes_screen)
  // ---------------------------------------------------------------------------

  Future<int> _contar(String sql, [List<Object?>? args]) async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(sql, args)) ?? 0;
  }

  /// Números del tablero principal.
  Future<Map<String, num>> resumenHome() async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final db = await database;
    final deuda = await db.rawQuery(
        "SELECT COALESCE(SUM(monto), 0) AS total FROM cuota WHERE estado = 'pendiente'");
    final cuotasCreadas = await _contar(
        "SELECT COUNT(*) FROM tipo_cuota WHERE activo = 1");

    return {
      'conductores_activos':
          await _contar("SELECT COUNT(*) FROM conductor WHERE estado = 'activo'"),
      'asistencias_hoy':
          await _contar('SELECT COUNT(*) FROM asistencia WHERE fecha = ?', [hoy]),
      'sanciones_pendientes': await _contar(
          "SELECT COUNT(*) FROM sancion WHERE estado = 'pendiente'"),
      'cuotas_pendientes_monto': (deuda.first['total'] as num?) ?? 0,
      'cuotas_creadas': cuotasCreadas,
    };
  }

  /// Números personalizados para la vista de inicio del Conductor autenticado.
  Future<Map<String, num>> resumenConductor(String idConductor) async {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final db = await database;
    final deuda = await db.rawQuery(
        "SELECT COALESCE(SUM(monto), 0) AS total FROM cuota WHERE id_conductor = ? AND estado = 'pendiente'",
        [idConductor]);

    final asistioHoy = await _contar(
        'SELECT COUNT(*) FROM asistencia WHERE id_conductor = ? AND fecha = ?',
        [idConductor, hoy]);

    final vueltasHoy = await _contar(
        'SELECT COUNT(*) FROM vueltas WHERE id_conductor = ? AND fecha = ?',
        [idConductor, hoy]);

    final sancionesPendientes = await _contar(
        "SELECT COUNT(*) FROM sancion WHERE id_conductor = ? AND estado = 'pendiente'",
        [idConductor]);

    return {
      'asistio_hoy': asistioHoy,
      'vueltas_hoy': vueltasHoy,
      'sanciones_pendientes': sancionesPendientes,
      'cuotas_pendientes_monto': (deuda.first['total'] as num?) ?? 0,
    };
  }

  // ---------------------------------------------------------------------------
  // SINCRONIZACIÓN (para la etapa de la nube)
  // ---------------------------------------------------------------------------

  /// Registros que aún no se subieron a la base central.
  Future<List<Map<String, dynamic>>> pendientesDeSincronizar(
      String tabla) async {
    final db = await database;
    return db.query(tabla, where: 'sincronizado = 0');
  }

  /// Marca un registro como ya subido.
  Future<void> marcarSincronizado(String tabla, String id) async {
    final db = await database;
    await db.update(
      tabla,
      {'sincronizado': 1},
      where: '${_pk[tabla]} = ?',
      whereArgs: [id],
    );
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }
}
