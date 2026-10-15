import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
  static const _dbVersion = 1;
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
    );
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
                       CHECK (rol IN ('superadmin','admin','supervisor','conductor')),
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
        id_conductor        TEXT PRIMARY KEY,
        id_usuario          TEXT NOT NULL UNIQUE,
        nombre              TEXT NOT NULL,
        ci                  TEXT NOT NULL UNIQUE,
        licencia            TEXT,
        fecha_incorporacion TEXT,
        estado              TEXT NOT NULL DEFAULT 'activo',
        created_at          TEXT NOT NULL,
        updated_at          TEXT NOT NULL,
        sincronizado        INTEGER NOT NULL DEFAULT 0,
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
        id_tipo_cuota TEXT PRIMARY KEY,
        nombre        TEXT NOT NULL UNIQUE,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cuota (
        id_cuota      TEXT PRIMARY KEY,
        id_conductor  TEXT NOT NULL,
        id_tipo_cuota TEXT NOT NULL,
        monto         REAL NOT NULL,
        fecha         TEXT NOT NULL,
        estado        TEXT NOT NULL DEFAULT 'pendiente',
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        sincronizado  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_conductor) REFERENCES conductor (id_conductor)
          ON DELETE CASCADE,
        FOREIGN KEY (id_tipo_cuota) REFERENCES tipo_cuota (id_tipo_cuota)
          ON DELETE RESTRICT
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
        'CREATE INDEX idx_sancion_conductor ON sancion (id_conductor, estado)');

    await _seed(db);
  }

  /// Datos iniciales: Único usuario predeterminado del sistema (superadmin) y los tipos de cuota base.
  /// Los demás usuarios (admin, supervisor, conductor) son creados posteriormente por el superadmin/admin.
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

    for (final nombre in ['Mensual', 'Extraordinaria', 'Multa']) {
      await db.insert('tipo_cuota', {
        'id_tipo_cuota': _uuid.v4(),
        'nombre': nombre,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });
    }

    for (final nombre in ['Parada Central', 'Terminal Central']) {
      await db.insert('punto_de_control', {
        'id_punto': _uuid.v4(),
        'nombre': nombre,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });
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
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });

        if (placa != null && placa.trim().isNotEmpty) {
          final idAuto = _uuid.v4();
          await txn.insert('automovil', {
            'id_auto': idAuto,
            'placa': placa.trim().toUpperCase(),
            'estado': 'activo',
            'created_at': now,
            'updated_at': now,
            'sincronizado': 0,
          });
          await txn.insert('conductor_automovil', {
            'id_conductor': idConductor,
            'id_auto': idAuto,
            'created_at': now,
            'updated_at': now,
            'sincronizado': 0,
          });
        }
      }
    });

    return idUsuario;
  }

  /// Actualiza los datos de un usuario, su rol, su estado y opcionalmente su contraseña.
  Future<void> actualizarUsuarioCompleto({
    required String idUsuario,
    required String nombre,
    String? gmail,
    required String rol,
    required String estado,
    String? newPassword,
    String? ci,
    String? licencia,
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
        if (cond.isNotEmpty) {
          await txn.update(
            'conductor',
            {
              'nombre': nombre,
              'ci': ci ?? cond.first['ci'],
              'licencia': licencia ?? cond.first['licencia'],
              'estado': estado,
              'updated_at': now,
              'sincronizado': 0,
            },
            where: 'id_usuario = ?',
            whereArgs: [idUsuario],
          );
        } else {
          await txn.insert('conductor', {
            'id_conductor': _uuid.v4(),
            'id_usuario': idUsuario,
            'nombre': nombre,
            'ci': ci ?? '',
            'licencia': licencia,
            'fecha_incorporacion': now.substring(0, 10),
            'estado': estado,
            'created_at': now,
            'updated_at': now,
            'sincronizado': 0,
          });
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

  /// conductores_screen: conductores con su(s) auto(s).
  Future<List<Map<String, dynamic>>> conductoresConAuto() async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.*, a.id_auto, a.placa
      FROM conductor c
      LEFT JOIN conductor_automovil ca ON ca.id_conductor = c.id_conductor
      LEFT JOIN automovil a ON a.id_auto = ca.id_auto
      ORDER BY c.nombre
    ''');
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

  /// control_economico_screen: cuotas con conductor y tipo.
  Future<List<Map<String, dynamic>>> cuotasDetalle({
    String? idConductor,
    String? estado,
  }) async {
    final db = await database;
    final condiciones = <String>[];
    final args = <Object?>[];
    if (idConductor != null) {
      condiciones.add('q.id_conductor = ?');
      args.add(idConductor);
    }
    if (estado != null) {
      condiciones.add('q.estado = ?');
      args.add(estado);
    }
    final where = condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    return db.rawQuery('''
      SELECT q.*, c.nombre AS conductor_nombre, t.nombre AS tipo_nombre
      FROM cuota q
      JOIN conductor c ON c.id_conductor = q.id_conductor
      JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
      $where
      ORDER BY q.fecha DESC
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

    return {
      'conductores_activos':
          await _contar("SELECT COUNT(*) FROM conductor WHERE estado = 'activo'"),
      'asistencias_hoy':
          await _contar('SELECT COUNT(*) FROM asistencia WHERE fecha = ?', [hoy]),
      'sanciones_pendientes': await _contar(
          "SELECT COUNT(*) FROM sancion WHERE estado = 'pendiente'"),
      'cuotas_pendientes_monto': (deuda.first['total'] as num?) ?? 0,
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
