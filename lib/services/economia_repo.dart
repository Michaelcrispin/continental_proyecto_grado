import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

/// Repositorio especializado para la gestión del Objetivo e) Control Económico.
///
/// Implementa lógica de negocio para:
/// - Cobranzas atómicas con cálculo automático de saldos y estados.
/// - Generación correlativa sin saltos de números de recibo (REC-YYYY-NNNNNN).
/// - Estado de cuenta individual para conductores y tesoreros.
/// - Cobro masivo unificado (lotes).
/// - Resumen en tiempo real del Panel de Hacienda y Caja del Día.
class EconomiaRepo {
  EconomiaRepo._internal();
  static final EconomiaRepo instance = EconomiaRepo._internal();

  static const _uuid = Uuid();

  DatabaseHelper get _dh => DatabaseHelper.instance;

  String _nowIso() => DateTime.now().toIso8601String();
  String _hoyFecha() => DateTime.now().toIso8601String().substring(0, 10);

  // ---------------------------------------------------------------------------
  // GESTIÓN DIRECTA DE CUOTAS POR TIPO (FLUJO LIMPIO)
  // ---------------------------------------------------------------------------
  /// Obtiene los conceptos/tipos de cuota disponibles.
  Future<List<Map<String, dynamic>>> listarTiposCuota() async {
    final db = await _dh.database;
    return db.query('tipo_cuota', where: 'activo = 1', orderBy: 'nombre ASC');
  }

  /// Obtiene los tipos de cuota con resumen calculado para las tarjetas UI:
  /// total recaudado, total pendiente, conductores que pagaron y estado ('en_cobro', 'pendiente', 'completada').
  Future<List<Map<String, dynamic>>> listarCuotasConResumen() async {
    final db = await _dh.database;
    final sql = '''
      SELECT 
        t.id_tipo_cuota,
        t.nombre,
        t.descripcion,
        COALESCE(t.categoria, 'ayuda') AS categoria,
        t.monto_sugerido,
        t.activo,
        t.es_fijo,
        t.created_at,
        COUNT(DISTINCT q.id_conductor) AS total_conductores,
        COUNT(q.id_cuota) AS total_asignados,
        COALESCE(SUM(q.monto), 0.0) AS total_monto,
        COALESCE(SUM(q.monto_pagado), 0.0) AS total_pagado,
        COALESCE(SUM(q.monto - q.monto_pagado), 0.0) AS total_falta,
        (
          SELECT COUNT(DISTINCT q2.id_conductor)
          FROM cuota q2
          WHERE q2.id_tipo_cuota = t.id_tipo_cuota
            AND q2.id_conductor NOT IN (
              SELECT q3.id_conductor
              FROM cuota q3
              WHERE q3.id_tipo_cuota = t.id_tipo_cuota
                AND (q3.monto - q3.monto_pagado) > 0.001
            )
        ) AS cant_pagados,
        (
          SELECT COUNT(DISTINCT q4.id_conductor)
          FROM cuota q4
          WHERE q4.id_tipo_cuota = t.id_tipo_cuota
            AND (q4.monto - q4.monto_pagado) > 0.001
        ) AS cant_deben
      FROM tipo_cuota t
      LEFT JOIN cuota q ON q.id_tipo_cuota = t.id_tipo_cuota
      WHERE t.activo = 1
      GROUP BY t.id_tipo_cuota
      ORDER BY t.created_at DESC, t.nombre ASC
    ''';
    final rows = await db.rawQuery(sql);
    return rows.map((r) {
      final totalAsignados = (r['total_asignados'] as num?)?.toInt() ?? 0;
      final totalPagado = (r['total_pagado'] as num?)?.toDouble() ?? 0.0;
      final cantDeben = (r['cant_deben'] as num?)?.toInt() ?? 0;
      final cantPagados = (r['cant_pagados'] as num?)?.toInt() ?? 0;

      String estado;
      if (totalAsignados == 0 || totalPagado <= 0.001) {
        estado = 'pendiente';
      } else if (cantDeben == 0 && cantPagados > 0) {
        estado = 'completada';
      } else {
        estado = 'en_cobro';
      }

      final map = Map<String, dynamic>.from(r);
      map['estado_calculado'] = estado;
      return map;
    }).toList();
  }

  /// Crea un nuevo tipo de cuota (ej: "Apoyo económico", motivo: "Gastos médicos", monto: 200) y
  /// genera automáticamente la deuda para todos los conductores activos.
  Future<String> crearNuevoConceptoCuota({
    required String nombre,
    String? descripcion,
    String categoria = 'ayuda',
    required double monto,
    required String idUsuario,
  }) async {
    final db = await _dh.database;
    final idTipo = _uuid.v4();
    final now = _nowIso();
    final fechaHoy = now.substring(0, 10);
    final descTrim = descripcion?.trim();

    return await db.transaction<String>((txn) async {
      await txn.insert('tipo_cuota', {
        'id_tipo_cuota': idTipo,
        'nombre': nombre.trim(),
        'descripcion': (descTrim != null && descTrim.isNotEmpty) ? descTrim : null,
        'categoria': categoria,
        'monto_sugerido': monto,
        'activo': 1,
        'es_fijo': 0,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      final conductores = await txn.rawQuery(
        "SELECT id_conductor FROM conductor WHERE LOWER(estado) = 'activo'",
      );

      final batch = txn.batch();
      for (final c in conductores) {
        batch.insert('cuota', {
          'id_cuota': _uuid.v4(),
          'id_conductor': c['id_conductor'],
          'id_tipo_cuota': idTipo,
          'monto': monto,
          'monto_pagado': 0.0,
          'fecha': fechaHoy,
          'estado': 'pendiente',
          'concepto': nombre.trim(),
          'registrado_por': idUsuario,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });
      }
      await batch.commit(noResult: true);

      return idTipo;
    });
  }

  /// Retorna la lista de todos los conductores con estado activo, con id, nombre, ci y foto.
  Future<List<Map<String, dynamic>>> listarConductoresActivos() async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT id_conductor, nombre, ci, foto, telefono
      FROM conductor
      WHERE LOWER(estado) = 'activo'
      ORDER BY nombre ASC
    ''');
  }

  /// Crea la cuota de Canastón y genera el lote de cobros periódicos en base
  /// al cronograma de fechas para cada conductor seleccionado.
  Future<Map<String, dynamic>> crearCanastonConCronograma({
    required String nombre,
    String? descripcion,
    required double importeCuota,
    required String frecuencia,
    required String reglaDia,
    required List<DateTime> fechasCronograma,
    required List<String> idsConductores,
    required String idUsuario,
  }) async {
    final nombreLimpio = nombre.trim();
    if (nombreLimpio.isEmpty) {
      throw Exception('El nombre del canastón no puede estar vacío.');
    }
    if (importeCuota <= 0) {
      throw Exception('El importe por conductor debe ser mayor a 0 Bs.');
    }
    if (fechasCronograma.isEmpty) {
      throw Exception('El cronograma no contiene fechas de cobro válidas.');
    }
    if (idsConductores.isEmpty) {
      throw Exception('Debe seleccionar al menos un conductor.');
    }

    final db = await _dh.database;
    final idTipo = _uuid.v4();
    final idLote = _uuid.v4();
    final now = _nowIso();
    final fechaHoy = now.substring(0, 10);

    return await db.transaction<Map<String, dynamic>>((txn) async {
      // 1. Validar que no exista otra cuota con el mismo nombre
      final existente = await txn.query(
        'tipo_cuota',
        where: 'LOWER(nombre) = ? AND activo = 1',
        whereArgs: [nombreLimpio.toLowerCase()],
      );
      if (existente.isNotEmpty) {
        throw Exception('Ya existe una cuota activa con el nombre "$nombreLimpio".');
      }

      // 2. Construir detalle informativo descriptivo
      final descFinal = (descripcion != null && descripcion.trim().isNotEmpty)
          ? descripcion.trim()
          : 'Canastón Navideño · Frecuencia: $frecuencia ($reglaDia) · ${fechasCronograma.length} cuotas fijas de Bs. ${importeCuota.toStringAsFixed(2)}';

      // 3. Insertar tipo_cuota
      await txn.insert('tipo_cuota', {
        'id_tipo_cuota': idTipo,
        'nombre': nombreLimpio,
        'descripcion': descFinal,
        'categoria': 'canaston',
        'monto_sugerido': importeCuota,
        'activo': 1,
        'es_fijo': 0,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      // 4. Insertar las cuotas calendarizadas por lote para cada chofer
      final batch = txn.batch();
      final totalFechas = fechasCronograma.length;

      for (final idConductor in idsConductores) {
        for (int i = 0; i < totalFechas; i++) {
          final f = fechasCronograma[i];
          final fVencStr = '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
          final nroCuota = i + 1;

          batch.insert('cuota', {
            'id_cuota': _uuid.v4(),
            'id_conductor': idConductor,
            'id_tipo_cuota': idTipo,
            'monto': importeCuota,
            'monto_pagado': 0.0,
            'fecha': fechaHoy,
            'fecha_vencimiento': fVencStr,
            'concepto': '$nombreLimpio · Cuota $nroCuota de $totalFechas',
            'id_lote': idLote,
            'registrado_por': idUsuario,
            'estado': 'pendiente',
            'created_at': now,
            'updated_at': now,
            'sincronizado': 0,
          });
        }
      }

      await batch.commit(noResult: true);

      return {
        'id_tipo_cuota': idTipo,
        'id_lote': idLote,
        'total_cuotas_generadas': idsConductores.length * totalFechas,
        'total_fechas': totalFechas,
        'total_conductores': idsConductores.length,
        'monto_total_por_conductor': importeCuota * totalFechas,
      };
    });
  }

  /// Crea una cuota de Apoyo Económico (Solidaria) para un conductor beneficiario.
  /// Genera una cuota por cada conductor aportante (excluyendo automáticamente al beneficiario).
  Future<Map<String, dynamic>> crearApoyoEconomico({
    required String nombre,
    required String motivo,
    required String modalidad, // 'obligatoria' | 'voluntaria'
    required String idConductorBeneficiario,
    required String nombreBeneficiario,
    required double importePorChofer,
    DateTime? fechaLimite,
    required List<String> idsAportantes,
    required String idUsuario,
  }) async {
    final nombreLimpio = nombre.trim();
    if (nombreLimpio.isEmpty) {
      throw Exception('El título del apoyo económico no puede estar vacío.');
    }
    if (idConductorBeneficiario.trim().isEmpty) {
      throw Exception('Debe seleccionar al conductor beneficiario.');
    }
    if (importePorChofer <= 0) {
      throw Exception('El importe por conductor debe ser mayor a 0 Bs.');
    }

    // Filtrar al beneficiario para que no aporte a su propia ayuda
    final aportantesFiltrados = idsAportantes
        .where((id) => id != idConductorBeneficiario)
        .toList();

    if (aportantesFiltrados.isEmpty) {
      throw Exception('Debe haber al menos un conductor aportante.');
    }

    final db = await _dh.database;
    final idTipo = _uuid.v4();
    final idLote = _uuid.v4();
    final now = _nowIso();
    final fechaHoy = now.substring(0, 10);
    final fVencStr = fechaLimite != null
        ? '${fechaLimite.year.toString().padLeft(4, '0')}-${fechaLimite.month.toString().padLeft(2, '0')}-${fechaLimite.day.toString().padLeft(2, '0')}'
        : null;

    final modLabel = modalidad == 'obligatoria' ? 'Obligatoria' : 'Voluntaria';
    final motivoLimpio = motivo.trim().isNotEmpty ? motivo.trim() : 'Apoyo económico solidario';
    final descFinal = 'Beneficiario: $nombreBeneficiario | Modalidad: $modLabel | Motivo: $motivoLimpio';

    return await db.transaction<Map<String, dynamic>>((txn) async {
      // 1. Validar que no exista otra cuota activa con el mismo nombre
      final existente = await txn.query(
        'tipo_cuota',
        where: 'LOWER(nombre) = ? AND activo = 1',
        whereArgs: [nombreLimpio.toLowerCase()],
      );
      if (existente.isNotEmpty) {
        throw Exception('Ya existe una cuota activa con el nombre "$nombreLimpio".');
      }

      // 2. Insertar en tipo_cuota
      await txn.insert('tipo_cuota', {
        'id_tipo_cuota': idTipo,
        'nombre': nombreLimpio,
        'descripcion': descFinal,
        'categoria': 'ayuda',
        'monto_sugerido': importePorChofer,
        'activo': 1,
        'es_fijo': modalidad == 'obligatoria' ? 1 : 0,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      // 3. Insertar cuota para cada chofer aportante
      final batch = txn.batch();
      for (final idConductor in aportantesFiltrados) {
        batch.insert('cuota', {
          'id_cuota': _uuid.v4(),
          'id_conductor': idConductor,
          'id_tipo_cuota': idTipo,
          'monto': importePorChofer,
          'monto_pagado': 0.0,
          'fecha': fechaHoy,
          'fecha_vencimiento': fVencStr,
          'concepto': '$nombreLimpio · Solidaridad con $nombreBeneficiario',
          'id_lote': idLote,
          'registrado_por': idUsuario,
          'estado': 'pendiente',
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });
      }

      await batch.commit(noResult: true);

      return {
        'id_tipo_cuota': idTipo,
        'id_lote': idLote,
        'total_cuotas_generadas': aportantesFiltrados.length,
        'total_aportantes': aportantesFiltrados.length,
        'monto_total_esperado': importePorChofer * aportantesFiltrados.length,
      };
    });
  }

  /// Actualiza el título, motivo descriptivo, categoría y monto de una cuota existente.
  Future<void> actualizarTipoCuota({
    required String idTipoCuota,
    required String nombre,
    String? descripcion,
    String? categoria,
    required double monto,
  }) async {
    final db = await _dh.database;
    final now = _nowIso();
    final descTrim = descripcion?.trim();

    await db.transaction((txn) async {
      final updateData = <String, dynamic>{
        'nombre': nombre.trim(),
        'descripcion': (descTrim != null && descTrim.isNotEmpty) ? descTrim : null,
        'monto_sugerido': monto,
        'updated_at': now,
      };
      if (categoria != null) {
        updateData['categoria'] = categoria;
      }

      await txn.update(
        'tipo_cuota',
        updateData,
        where: 'id_tipo_cuota = ?',
        whereArgs: [idTipoCuota],
      );

      await txn.rawUpdate('''
        UPDATE cuota 
        SET monto = ?, concepto = ?, updated_at = ?
        WHERE id_tipo_cuota = ? AND monto_pagado = 0
      ''', [monto, nombre.trim(), now, idTipoCuota]);
    });
  }

  /// Elimina una cuota específica y todos sus registros asociados.
  Future<void> eliminarTipoCuota(String idTipoCuota) async {
    final db = await _dh.database;
    await db.transaction((txn) async {
      final cuotas = await txn.query('cuota', where: 'id_tipo_cuota = ?', whereArgs: [idTipoCuota]);
      for (final q in cuotas) {
        await txn.delete('pago', where: 'id_cuota = ?', whereArgs: [q['id_cuota']]);
      }
      await txn.delete('cuota', where: 'id_tipo_cuota = ?', whereArgs: [idTipoCuota]);
      await txn.delete('tipo_cuota', where: 'id_tipo_cuota = ?', whereArgs: [idTipoCuota]);
    });
  }

  /// Borra absolutamente todas las cuotas, pagos y tipos de cuota creados para iniciar desde cero.
  Future<void> vaciarTodasLasCuotas() async {
    final db = await _dh.database;
    await db.transaction((txn) async {
      await txn.delete('pago');
      await txn.delete('cuota');
      await txn.delete('tipo_cuota');
    });
  }

  /// Retorna la lista de TODOS los conductores activos con su estado financiero para una cuota dada.
  /// Muestra: conductor_nombre, ci, foto, monto_total, monto_pagado (verde) y monto_falta (rojo).
  /// Retorna la lista de conductores asociados a una cuota sin duplicados (1 fila por chofer).
  /// Calcula el total acumulado de cuotas, lo pagado, lo pendiente, el conteo de cuotas
  /// pagadas vs pendientes y la próxima fecha de vencimiento a pagar.
  Future<List<Map<String, dynamic>>> estadoConductoresPorCuota(String idTipoCuota) async {
    final db = await _dh.database;

    final countRes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cuota WHERE id_tipo_cuota = ?', [idTipoCuota]),
    ) ?? 0;

    if (countRes > 0) {
      return await db.rawQuery('''
        SELECT 
          c.id_conductor,
          c.nombre AS conductor_nombre,
          c.ci AS conductor_ci,
          c.foto AS conductor_foto,
          c.telefono AS conductor_telefono,
          t.nombre AS tipo_nombre,
          t.id_tipo_cuota,
          COALESCE(t.categoria, 'ayuda') AS categoria,
          t.monto_sugerido,
          COALESCE(SUM(q.monto), t.monto_sugerido) AS monto_total,
          COALESCE(SUM(q.monto_pagado), 0.0) AS monto_pagado,
          COALESCE(SUM(q.monto - q.monto_pagado), 0.0) AS monto_falta,
          COUNT(q.id_cuota) AS total_cuotas,
          SUM(CASE WHEN q.monto_pagado >= (q.monto - 0.001) AND q.monto > 0 THEN 1 ELSE 0 END) AS cuotas_pagadas,
          SUM(CASE WHEN (q.monto - q.monto_pagado) > 0.001 THEN 1 ELSE 0 END) AS cuotas_pendientes,
          MIN(CASE WHEN (q.monto - q.monto_pagado) > 0.001 THEN q.fecha_vencimiento ELSE NULL END) AS proxima_fecha_pago,
          MIN(CASE WHEN (q.monto - q.monto_pagado) > 0.001 THEN (q.monto - q.monto_pagado) ELSE NULL END) AS proximo_monto_pago,
          (
            SELECT q2.id_cuota 
            FROM cuota q2 
            WHERE q2.id_conductor = c.id_conductor 
              AND q2.id_tipo_cuota = t.id_tipo_cuota 
              AND (q2.monto - q2.monto_pagado) > 0.001
            ORDER BY COALESCE(q2.fecha_vencimiento, q2.fecha) ASC, q2.created_at ASC
            LIMIT 1
          ) AS proxima_id_cuota
        FROM conductor c
        JOIN cuota q ON q.id_conductor = c.id_conductor AND q.id_tipo_cuota = ?
        JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
        WHERE LOWER(c.estado) = 'activo'
        GROUP BY c.id_conductor
        ORDER BY c.nombre ASC
      ''', [idTipoCuota]);
    } else {
      return await db.rawQuery('''
        SELECT 
          c.id_conductor,
          c.nombre AS conductor_nombre,
          c.ci AS conductor_ci,
          c.foto AS conductor_foto,
          c.telefono AS conductor_telefono,
          t.nombre AS tipo_nombre,
          t.id_tipo_cuota,
          COALESCE(t.categoria, 'ayuda') AS categoria,
          t.monto_sugerido,
          COALESCE(t.monto_sugerido, 0.0) AS monto_total,
          0.0 AS monto_pagado,
          COALESCE(t.monto_sugerido, 0.0) AS monto_falta,
          0 AS total_cuotas,
          0 AS cuotas_pagadas,
          1 AS cuotas_pendientes,
          NULL AS proxima_fecha_pago,
          t.monto_sugerido AS proximo_monto_pago,
          NULL AS proxima_id_cuota
        FROM conductor c
        CROSS JOIN tipo_cuota t ON t.id_tipo_cuota = ?
        WHERE LOWER(c.estado) = 'activo'
        ORDER BY c.nombre ASC
      ''', [idTipoCuota]);
    }
  }

  /// Retorna la lista detallada de cuotas/fechas programadas de un conductor
  /// para un tipo de cuota específico, ordenadas cronológicamente con datos de recibo si fue pagada.
  Future<List<Map<String, dynamic>>> obtenerCronogramaConductor({
    required String idTipoCuota,
    required String idConductor,
  }) async {
    final db = await _dh.database;
    final sql = '''
      SELECT 
        q.id_cuota,
        q.id_conductor,
        q.id_tipo_cuota,
        q.monto,
        COALESCE(q.monto_pagado, 0.0) AS monto_pagado,
        (q.monto - COALESCE(q.monto_pagado, 0.0)) AS monto_falta,
        q.fecha,
        q.fecha_vencimiento,
        q.concepto,
        q.estado,
        (SELECT p.id_pago FROM pago p WHERE p.id_cuota = q.id_cuota ORDER BY p.fecha DESC, p.created_at DESC LIMIT 1) AS id_pago,
        (SELECT p.nro_recibo FROM pago p WHERE p.id_cuota = q.id_cuota ORDER BY p.fecha DESC, p.created_at DESC LIMIT 1) AS nro_recibo,
        (SELECT p.fecha FROM pago p WHERE p.id_cuota = q.id_cuota ORDER BY p.fecha DESC, p.created_at DESC LIMIT 1) AS fecha_pago,
        (SELECT p.metodo FROM pago p WHERE p.id_cuota = q.id_cuota ORDER BY p.fecha DESC, p.created_at DESC LIMIT 1) AS metodo_pago,
        (SELECT p.observacion FROM pago p WHERE p.id_cuota = q.id_cuota ORDER BY p.fecha DESC, p.created_at DESC LIMIT 1) AS pago_observacion
      FROM cuota q
      WHERE q.id_tipo_cuota = ? AND q.id_conductor = ?
      ORDER BY COALESCE(q.fecha_vencimiento, q.fecha) ASC, q.created_at ASC
    ''';
    return await db.rawQuery(sql, [idTipoCuota, idConductor]);
  }

  /// Obtiene la información completa de un pago/recibo para previsualización e impresión en PDF.
  Future<Map<String, dynamic>?> obtenerDatosReciboPorPago({String? idPago, String? idCuota}) async {
    final db = await _dh.database;
    final whereClause = idPago != null ? 'p.id_pago = ?' : 'p.id_cuota = ?';
    final arg = idPago ?? idCuota;
    if (arg == null) return null;

    final rows = await db.rawQuery('''
      SELECT 
        p.id_pago,
        p.nro_recibo,
        p.fecha,
        p.created_at,
        p.monto AS monto_pagado,
        p.metodo,
        p.observacion,
        q.id_cuota,
        t.nombre AS tipo_nombre,
        COALESCE(q.concepto, t.nombre) AS concepto,
        c.nombre AS conductor_nombre,
        c.ci AS conductor_ci,
        q.monto AS total_cuota,
        (q.monto - q.monto_pagado) AS saldo_restante
      FROM pago p
      JOIN cuota q ON q.id_cuota = p.id_cuota
      JOIN conductor c ON c.id_conductor = q.id_conductor
      JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
      WHERE $whereClause
      ORDER BY p.fecha DESC, p.created_at DESC
      LIMIT 1
    ''', [arg]);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  /// Registra el cobro a un conductor distribuyendo el monto en orden cronológico (FIFO)
  /// a las cuotas periódicas pendientes, o a una cuota específica si se proporciona su id.
  Future<Map<String, dynamic>> cobrarAConductor({
    required String idConductor,
    required String idTipoCuota,
    required double montoACobrar,
    String metodo = 'efectivo',
    required String idUsuario,
    String? idCuotaEspecifica,
  }) async {
    final db = await _dh.database;
    final now = _nowIso();
    final fechaHoy = now.substring(0, 10);

    return await db.transaction<Map<String, dynamic>>((txn) async {
      List<Map<String, dynamic>> cuotasPendientes;
      if (idCuotaEspecifica != null) {
        cuotasPendientes = await txn.rawQuery(
          'SELECT * FROM cuota WHERE id_cuota = ?',
          [idCuotaEspecifica],
        );
      } else {
        cuotasPendientes = await txn.rawQuery('''
          SELECT * FROM cuota 
          WHERE id_conductor = ? AND id_tipo_cuota = ? AND (monto - monto_pagado) > 0.001
          ORDER BY COALESCE(fecha_vencimiento, fecha) ASC, created_at ASC
        ''', [idConductor, idTipoCuota]);
      }

      if (cuotasPendientes.isEmpty) {
        final cuotasExistentes = await txn.rawQuery(
          'SELECT * FROM cuota WHERE id_conductor = ? AND id_tipo_cuota = ? LIMIT 1',
          [idConductor, idTipoCuota],
        );
        if (cuotasExistentes.isEmpty) {
          final tipo = (await txn.query('tipo_cuota', where: 'id_tipo_cuota = ?', whereArgs: [idTipoCuota])).first;
          final totalDeuda = (tipo['monto_sugerido'] as num).toDouble();
          final idCuotaNueva = _uuid.v4();
          await txn.insert('cuota', {
            'id_cuota': idCuotaNueva,
            'id_conductor': idConductor,
            'id_tipo_cuota': idTipoCuota,
            'monto': totalDeuda,
            'monto_pagado': 0.0,
            'fecha': fechaHoy,
            'estado': 'pendiente',
            'concepto': tipo['nombre'],
            'registrado_por': idUsuario,
            'created_at': now,
            'updated_at': now,
            'sincronizado': 0,
          });
          cuotasPendientes = await txn.rawQuery(
            'SELECT * FROM cuota WHERE id_cuota = ?',
            [idCuotaNueva],
          );
        } else {
          throw Exception('El conductor ya no tiene cuotas pendientes por pagar.');
        }
      }

      double totalPendiente = 0;
      for (final q in cuotasPendientes) {
        final m = (q['monto'] as num).toDouble();
        final p = (q['monto_pagado'] as num?)?.toDouble() ?? 0.0;
        totalPendiente += (m - p);
      }

      if (montoACobrar > (totalPendiente + 0.01)) {
        throw Exception('El monto ingresado (Bs. $montoACobrar) supera lo que falta pagar (Bs. ${totalPendiente.toStringAsFixed(2)}).');
      }

      double restante = montoACobrar;
      String primerNroRecibo = '';
      String primerIdPago = '';
      String primerIdCuota = '';
      int cuotasAfectadas = 0;

      for (final q in cuotasPendientes) {
        if (restante <= 0.001) break;

        final idCuota = q['id_cuota'].toString();
        final montoCuota = (q['monto'] as num).toDouble();
        final pagadoAntes = (q['monto_pagado'] as num?)?.toDouble() ?? 0.0;
        final saldoCuota = montoCuota - pagadoAntes;

        final abono = (restante >= saldoCuota) ? saldoCuota : restante;
        final nroRecibo = await siguienteNroRecibo(txn: txn);
        final idPago = _uuid.v4();

        if (primerNroRecibo.isEmpty) {
          primerNroRecibo = nroRecibo;
          primerIdPago = idPago;
          primerIdCuota = idCuota;
        }

        await txn.insert('pago', {
          'id_pago': idPago,
          'id_cuota': idCuota,
          'monto': abono,
          'fecha': fechaHoy,
          'metodo': metodo.toLowerCase().trim(),
          'nro_recibo': nroRecibo,
          'id_usuario': idUsuario,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });

        final nuevoPagado = pagadoAntes + abono;
        final nuevoEstado = nuevoPagado >= (montoCuota - 0.001) ? 'pagado' : 'parcial';

        await txn.update(
          'cuota',
          {
            'monto_pagado': nuevoPagado,
            'estado': nuevoEstado,
            'updated_at': now,
            'sincronizado': 0,
          },
          where: 'id_cuota = ?',
          whereArgs: [idCuota],
        );

        cuotasAfectadas++;
        restante -= abono;
      }

      final cond = (await txn.query('conductor', where: 'id_conductor = ?', whereArgs: [idConductor])).first;
      final tipo = (await txn.query('tipo_cuota', where: 'id_tipo_cuota = ?', whereArgs: [idTipoCuota])).first;

      return {
        'id_pago': primerIdPago,
        'id_cuota': primerIdCuota,
        'nro_recibo': primerNroRecibo,
        'fecha': fechaHoy,
        'monto_pagado': montoACobrar,
        'total_cuota': totalPendiente,
        'saldo_restante': (totalPendiente - montoACobrar).clamp(0.0, double.infinity),
        'metodo': metodo,
        'conductor_nombre': cond['nombre'],
        'conductor_ci': cond['ci'],
        'tipo_nombre': tipo['nombre'],
        'concepto': tipo['nombre'],
        'cuotas_afectadas': cuotasAfectadas,
      };
    });
  }

  // ---------------------------------------------------------------------------
  // 1. CORRELATIVO ÚNICO DE RECIBO (REC-YYYY-NNNNNN)
  // ---------------------------------------------------------------------------
  /// Genera el siguiente número correlativo de recibo para el año actual.
  /// Si se pasa un objeto [txn], se ejecuta dentro de dicha transacción.
  Future<String> siguienteNroRecibo({Transaction? txn}) async {
    final anioActual = DateTime.now().year.toString();
    final prefijo = 'REC-$anioActual-';

    final executor = txn ?? await _dh.database;
    final res = await executor.rawQuery('''
      SELECT nro_recibo 
      FROM pago 
      WHERE nro_recibo LIKE ? 
      ORDER BY nro_recibo DESC 
      LIMIT 1
    ''', ['$prefijo%']);

    if (res.isEmpty) {
      return '${prefijo}000001';
    }

    final ultimo = res.first['nro_recibo']?.toString() ?? '';
    final parteNumero = ultimo.replaceFirst(prefijo, '');
    final correlativo = int.tryParse(parteNumero) ?? 0;
    final siguiente = correlativo + 1;

    return '$prefijo${siguiente.toString().padLeft(6, '0')}';
  }

  // ---------------------------------------------------------------------------
  // 2. REGISTRAR PAGO (TRANSACCIÓN ATÓMICA DE 3 TOQUES)
  // ---------------------------------------------------------------------------
  /// Registra un abono o pago total a una deuda existente.
  /// Valida saldos, recalcula el estado de la cuota y emite el recibo correlativo.
  Future<Map<String, dynamic>> registrarPago({
    required String idCuota,
    required double monto,
    String metodo = 'efectivo',
    String? observacion,
    required String idUsuario,
  }) async {
    if (monto <= 0) {
      throw Exception('El monto a cobrar debe ser mayor a 0 Bs.');
    }

    final db = await _dh.database;

    return await db.transaction<Map<String, dynamic>>((txn) async {
      // 1. Obtener datos actuales de la cuota
      final cuotas = await txn.rawQuery('''
        SELECT q.*, c.nombre AS conductor_nombre, c.ci AS conductor_ci, t.nombre AS tipo_nombre
        FROM cuota q
        JOIN conductor c ON c.id_conductor = q.id_conductor
        JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
        WHERE q.id_cuota = ?
        LIMIT 1
      ''', [idCuota]);

      if (cuotas.isEmpty) {
        throw Exception('La cuota solicitada no existe.');
      }

      final cuota = cuotas.first;
      final estadoActual = cuota['estado']?.toString().toLowerCase() ?? 'pendiente';

      if (estadoActual == 'anulado') {
        throw Exception('No se puede cobrar una cuota que ha sido anulada.');
      }

      final totalDeuda = (cuota['monto'] as num).toDouble();
      final montoPagadoActual = (cuota['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final saldoActual = totalDeuda - montoPagadoActual;

      // Validación con margen de centavos para redondeo
      if (monto > (saldoActual + 0.01)) {
        throw Exception(
          'El monto ingresado (Bs. ${monto.toStringAsFixed(2)}) supera el saldo restante de la deuda (Bs. ${saldoActual.toStringAsFixed(2)}).',
        );
      }

      // 2. Generar correlativo de recibo único
      final nroRecibo = await siguienteNroRecibo(txn: txn);
      final idPago = _uuid.v4();
      final now = _nowIso();
      final fechaHoy = now.substring(0, 10);

      // 3. Insertar pago
      await txn.insert('pago', {
        'id_pago': idPago,
        'id_cuota': idCuota,
        'monto': monto,
        'fecha': fechaHoy,
        'metodo': metodo.toLowerCase().trim(),
        'nro_recibo': nroRecibo,
        'observacion': (observacion != null && observacion.trim().isNotEmpty) ? observacion.trim() : null,
        'id_usuario': idUsuario,
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      // 4. Recalcular nuevo monto pagado y nuevo estado de la cuota
      final nuevoPagado = montoPagadoActual + monto;
      final String nuevoEstado;
      if (nuevoPagado >= (totalDeuda - 0.001)) {
        nuevoEstado = 'pagado';
      } else if (nuevoPagado > 0) {
        nuevoEstado = 'parcial';
      } else {
        nuevoEstado = 'pendiente';
      }

      await txn.update(
        'cuota',
        {
          'monto_pagado': nuevoPagado,
          'estado': nuevoEstado,
          'updated_at': now,
          'sincronizado': 0,
        },
        where: 'id_cuota = ?',
        whereArgs: [idCuota],
      );

      final nuevoSaldo = (totalDeuda - nuevoPagado).clamp(0.0, double.infinity);

      // 5. Retornar paquete de confirmación completo para mostrar/imprimir recibo
      return {
        'id_pago': idPago,
        'nro_recibo': nroRecibo,
        'fecha': fechaHoy,
        'hora': now.length >= 19 ? now.substring(11, 19) : '',
        'monto_pagado': monto,
        'metodo': metodo,
        'observacion': observacion,
        'id_cuota': idCuota,
        'tipo_nombre': cuota['tipo_nombre'],
        'concepto': cuota['concepto'] ?? cuota['tipo_nombre'],
        'conductor_nombre': cuota['conductor_nombre'],
        'conductor_ci': cuota['conductor_ci'],
        'total_cuota': totalDeuda,
        'saldo_restante': nuevoSaldo,
        'nuevo_estado': nuevoEstado,
      };
    });
  }

  // ---------------------------------------------------------------------------
  // 3. DEUDAS DE CONDUCTOR (PARA COBRAR)
  // ---------------------------------------------------------------------------
  /// Retorna las cuotas activas que tienen saldo pendiente de un conductor.
  Future<List<Map<String, dynamic>>> deudasDeConductor(String idConductor) async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT 
        q.*,
        t.nombre AS tipo_nombre,
        c.nombre AS conductor_nombre,
        c.ci AS conductor_ci,
        (q.monto - COALESCE(q.monto_pagado, 0)) AS saldo
      FROM cuota q
      JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
      JOIN conductor c ON c.id_conductor = q.id_conductor
      WHERE q.id_conductor = ?
        AND LOWER(q.estado) IN ('pendiente', 'parcial')
        AND (q.monto - COALESCE(q.monto_pagado, 0)) > 0
      ORDER BY q.fecha ASC, q.created_at ASC
    ''', [idConductor]);
  }

  // ---------------------------------------------------------------------------
  // 4. ESTADO DE CUENTA INTEGRAL (CONDUCTOR O TESORERO)
  // ---------------------------------------------------------------------------
  /// Obtiene los totales acumulados, lista de todas las cuotas y pagos de un conductor.
  Future<Map<String, dynamic>> estadoDeCuenta(String idConductor) async {
    final db = await _dh.database;

    // Conductor
    final condRes = await db.query(
      'conductor',
      where: 'id_conductor = ?',
      whereArgs: [idConductor],
      limit: 1,
    );
    if (condRes.isEmpty) {
      throw Exception('Conductor no encontrado.');
    }
    final conductor = condRes.first;

    // Cuotas
    final cuotas = await db.rawQuery('''
      SELECT 
        q.*,
        t.nombre AS tipo_nombre,
        (q.monto - COALESCE(q.monto_pagado, 0)) AS saldo
      FROM cuota q
      JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
      WHERE q.id_conductor = ?
      ORDER BY q.fecha DESC, q.created_at DESC
    ''', [idConductor]);

    // Pagos
    final pagos = await db.rawQuery('''
      SELECT 
        p.*,
        q.concepto,
        t.nombre AS tipo_nombre,
        u.nombre AS cobrador_nombre
      FROM pago p
      JOIN cuota q ON q.id_cuota = p.id_cuota
      JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
      LEFT JOIN usuario u ON u.id_usuario = p.id_usuario
      WHERE q.id_conductor = ?
      ORDER BY p.fecha DESC, p.created_at DESC
    ''', [idConductor]);

    double totalDebe = 0.0;
    double totalPagado = 0.0;
    double saldoPendiente = 0.0;

    for (final c in cuotas) {
      final estado = c['estado']?.toString().toLowerCase();
      if (estado == 'anulado') continue;

      final monto = (c['monto'] as num).toDouble();
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      totalDebe += monto;
      totalPagado += pagado;
      saldoPendiente += (monto - pagado).clamp(0.0, double.infinity);
    }

    return {
      'conductor': conductor,
      'total_debe': totalDebe,
      'total_pagado': totalPagado,
      'saldo_pendiente': saldoPendiente,
      'cuotas': cuotas,
      'pagos': pagos,
    };
  }

  // ---------------------------------------------------------------------------
  // 5. CREACIÓN DE DEUDA INDIVIDUAL
  // ---------------------------------------------------------------------------
  Future<String> crearCuota({
    required String idConductor,
    required String idTipoCuota,
    required double monto,
    String? concepto,
    String? fechaVencimiento,
    String? fecha,
    required String registradoPor,
    String? idReunion,
    String? idRonda,
  }) async {
    if (monto <= 0) {
      throw Exception('El monto de la deuda debe ser mayor a 0 Bs.');
    }

    final db = await _dh.database;
    final idCuota = _uuid.v4();
    final now = _nowIso();

    await db.insert('cuota', {
      'id_cuota': idCuota,
      'id_conductor': idConductor,
      'id_tipo_cuota': idTipoCuota,
      'monto': monto,
      'monto_pagado': 0.0,
      'fecha': fecha ?? now.substring(0, 10),
      'fecha_vencimiento': fechaVencimiento,
      'concepto': concepto?.trim(),
      'registrado_por': registradoPor,
      'estado': 'pendiente',
      'id_reunion': idReunion,
      'id_ronda': idRonda,
      'created_at': now,
      'updated_at': now,
      'sincronizado': 0,
    });

    return idCuota;
  }

  // ---------------------------------------------------------------------------
  // 6. COBRO MASIVO (TRANSACCIÓN TODO O NADA CON ID_LOTE)
  // ---------------------------------------------------------------------------
  /// Genera una misma cuota a todos los conductores activos (ej. Canastón Navideño),
  /// permitiendo excluir conductores específicos.
  Future<Map<String, dynamic>> crearCobroMasivo({
    required String idTipoCuota,
    required double monto,
    required String concepto,
    String? fechaVencimiento,
    String? fecha,
    required String registradoPor,
    List<String> idsConductoresExcluidos = const [],
  }) async {
    if (monto <= 0) {
      throw Exception('El monto del cobro masivo debe ser mayor a 0 Bs.');
    }

    final db = await _dh.database;
    final now = _nowIso();
    final fechaHoy = fecha ?? now.substring(0, 10);
    final idLote = _uuid.v4();

    return await db.transaction<Map<String, dynamic>>((txn) async {
      final conductores = await txn.rawQuery('''
        SELECT id_conductor, nombre 
        FROM conductor 
        WHERE LOWER(estado) = 'activo'
      ''');

      final conductoresAfectados = conductores.where((c) {
        final id = c['id_conductor']?.toString();
        return id != null && !idsConductoresExcluidos.contains(id);
      }).toList();

      if (conductoresAfectados.isEmpty) {
        throw Exception('No hay conductores activos seleccionados para aplicar el cobro masivo.');
      }

      final batch = txn.batch();
      for (final c in conductoresAfectados) {
        batch.insert('cuota', {
          'id_cuota': _uuid.v4(),
          'id_conductor': c['id_conductor'],
          'id_tipo_cuota': idTipoCuota,
          'monto': monto,
          'monto_pagado': 0.0,
          'fecha': fechaHoy,
          'fecha_vencimiento': fechaVencimiento,
          'concepto': concepto.trim(),
          'id_lote': idLote,
          'registrado_por': registradoPor,
          'estado': 'pendiente',
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });
      }

      await batch.commit(noResult: true);

      final totalBs = monto * conductoresAfectados.length;

      return {
        'id_lote': idLote,
        'cantidad_conductores': conductoresAfectados.length,
        'monto_individual': monto,
        'total_generado_bs': totalBs,
      };
    });
  }

  // ---------------------------------------------------------------------------
  // 7. CAJA DEL DÍA / HISTORIAL DE PAGOS
  // ---------------------------------------------------------------------------
  /// Consulta los pagos cobrados en una fecha (por defecto hoy).
  Future<Map<String, dynamic>> pagosDelDia({String? fecha}) async {
    final db = await _dh.database;
    final fechaFiltro = fecha ?? _hoyFecha();

    final pagos = await db.rawQuery('''
      SELECT 
        p.*,
        c.nombre AS conductor_nombre,
        c.ci AS conductor_ci,
        c.foto AS conductor_foto,
        t.nombre AS tipo_nombre,
        COALESCE(q.concepto, t.nombre) AS concepto_cuota,
        u.nombre AS cobrador_nombre
      FROM pago p
      JOIN cuota q ON q.id_cuota = p.id_cuota
      JOIN conductor c ON c.id_conductor = q.id_conductor
      JOIN tipo_cuota t ON t.id_tipo_cuota = q.id_tipo_cuota
      LEFT JOIN usuario u ON u.id_usuario = p.id_usuario
      WHERE p.fecha = ?
      ORDER BY p.created_at DESC
    ''', [fechaFiltro]);

    double total = 0.0;
    double totalEfectivo = 0.0;
    double totalQr = 0.0;
    double totalTransferencia = 0.0;

    for (final p in pagos) {
      final m = (p['monto'] as num).toDouble();
      final metodo = p['metodo']?.toString().toLowerCase() ?? 'efectivo';
      total += m;
      if (metodo == 'efectivo') {
        totalEfectivo += m;
      } else if (metodo == 'qr') {
        totalQr += m;
      } else if (metodo == 'transferencia') {
        totalTransferencia += m;
      }
    }

    return {
      'fecha': fechaFiltro,
      'pagos': pagos,
      'total_dia': total,
      'total_efectivo': totalEfectivo,
      'total_qr': totalQr,
      'total_transferencia': totalTransferencia,
      'cantidad_cobros': pagos.length,
    };
  }

  // ---------------------------------------------------------------------------
  // 8. RESUMEN DEL PANEL DE HACIENDA
  // ---------------------------------------------------------------------------
  /// Resumen ejecutivo: recaudado hoy, del mes, pendiente total y top 5 deudores.
  Future<Map<String, dynamic>> resumenHacienda() async {
    final db = await _dh.database;
    final hoy = _hoyFecha();
    final inicioMes = '${hoy.substring(0, 7)}-01';

    // 1. Recaudado hoy
    final hoyRes = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS total FROM pago WHERE fecha = ?',
      [hoy],
    );
    final recaudadoHoy = (hoyRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Recaudado del mes
    final mesRes = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS total FROM pago WHERE fecha >= ? AND fecha <= ?',
      [inicioMes, hoy],
    );
    final recaudadoMes = (mesRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Pendiente total de la línea (cuotas no anuladas)
    final pendRes = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(monto - COALESCE(monto_pagado, 0)), 0) AS total_pendiente,
        COUNT(DISTINCT id_conductor) AS conductores_deudores
      FROM cuota 
      WHERE LOWER(estado) IN ('pendiente', 'parcial')
        AND (monto - COALESCE(monto_pagado, 0)) > 0
    ''');
    final pendienteTotal = (pendRes.first['total_pendiente'] as num?)?.toDouble() ?? 0.0;
    final conductoresDeudores = (pendRes.first['conductores_deudores'] as num?)?.toInt() ?? 0;

    // 4. Top 5 deudores
    final topDeudores = await db.rawQuery('''
      SELECT 
        c.id_conductor,
        c.nombre AS conductor_nombre,
        c.ci AS conductor_ci,
        c.foto AS conductor_foto,
        SUM(q.monto - COALESCE(q.monto_pagado, 0)) AS deuda_total,
        COUNT(q.id_cuota) AS cantidad_cuotas
      FROM cuota q
      JOIN conductor c ON c.id_conductor = q.id_conductor
      WHERE LOWER(q.estado) IN ('pendiente', 'parcial')
        AND (q.monto - COALESCE(q.monto_pagado, 0)) > 0
      GROUP BY c.id_conductor, c.nombre, c.ci, c.foto
      ORDER BY deuda_total DESC
      LIMIT 5
    ''');

    // 5. Historial últimos 6 meses para gráfico
    final historialMeses = await db.rawQuery('''
      SELECT 
        SUBSTR(fecha, 1, 7) AS mes,
        SUM(monto) AS total
      FROM pago
      GROUP BY SUBSTR(fecha, 1, 7)
      ORDER BY mes DESC
      LIMIT 6
    ''');

    return {
      'recaudado_hoy': recaudadoHoy,
      'recaudado_mes': recaudadoMes,
      'pendiente_total': pendienteTotal,
      'conductores_deudores': conductoresDeudores,
      'top_deudores': topDeudores,
      'historial_meses': historialMeses.reversed.toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // 9. ANULACIÓN DE CUOTA (SOLO SUPERADMIN O TESORERO)
  // ---------------------------------------------------------------------------
  Future<void> anularCuota({
    required String idCuota,
    required String motivo,
    required String idUsuario,
  }) async {
    final db = await _dh.database;
    final res = await db.query('cuota', where: 'id_cuota = ?', whereArgs: [idCuota], limit: 1);
    if (res.isEmpty) throw Exception('Cuota no encontrada.');

    final cuota = res.first;
    final pagado = (cuota['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    if (pagado > 0) {
      throw Exception('No es posible anular una cuota con pagos ya registrados (Bs. ${pagado.toStringAsFixed(2)}).');
    }

    final now = _nowIso();
    await db.update(
      'cuota',
      {
        'estado': 'anulado',
        'motivo_anulacion': motivo.trim(),
        'updated_at': now,
        'sincronizado': 0,
      },
      where: 'id_cuota = ?',
      whereArgs: [idCuota],
    );
  }

  // ---------------------------------------------------------------------------
  // 10. REUNIONES (CERRAR Y GENERAR MULTAS POR FALTA)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> cerrarReunion(String idReunion, String idUsuario) async {
    final db = await _dh.database;
    final now = _nowIso();
    final fechaHoy = now.substring(0, 10);

    return await db.transaction<Map<String, dynamic>>((txn) async {
      final reunionRes = await txn.query('reunion', where: 'id_reunion = ?', whereArgs: [idReunion], limit: 1);
      if (reunionRes.isEmpty) throw Exception('Reunión no encontrada.');

      final reunion = reunionRes.first;
      if (reunion['estado']?.toString().toLowerCase() == 'cerrada') {
        throw Exception('La reunión ya se encuentra cerrada y sus multas fueron generadas.');
      }

      final montoMulta = (reunion['monto_multa'] as num?)?.toDouble() ?? 50.0;
      final tema = reunion['tema']?.toString() ?? 'Reunión Ordinaria';
      final fecha = reunion['fecha']?.toString() ?? fechaHoy;

      // Obtener asistencias marcadas como falta
      final faltas = await txn.query(
        'asistencia_reunion',
        where: 'id_reunion = ? AND LOWER(estado) = ?',
        whereArgs: [idReunion, 'falta'],
      );

      String? idTipoCuota;
      if (faltas.isNotEmpty) {
        idTipoCuota = _uuid.v4();
        final nombreTipo = 'Multa: $tema';
        final descTipo = 'Multas por falta a la asamblea "$tema" ($fecha). Sanción individual: Bs. ${montoMulta.toStringAsFixed(2)}';

        await txn.insert('tipo_cuota', {
          'id_tipo_cuota': idTipoCuota,
          'nombre': nombreTipo,
          'descripcion': descTipo,
          'categoria': 'multa',
          'monto_sugerido': montoMulta,
          'activo': 1,
          'es_fijo': 1,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });

        final batch = txn.batch();
        for (final f in faltas) {
          batch.insert('cuota', {
            'id_cuota': _uuid.v4(),
            'id_conductor': f['id_conductor'],
            'id_tipo_cuota': idTipoCuota,
            'monto': montoMulta,
            'monto_pagado': 0.0,
            'fecha': fecha,
            'concepto': 'Multa por falta a reunión: $tema',
            'registrado_por': idUsuario,
            'estado': 'pendiente',
            'id_reunion': idReunion,
            'created_at': now,
            'updated_at': now,
            'sincronizado': 0,
          });
        }
        await batch.commit(noResult: true);
      }

      // Marcar reunión como cerrada
      await txn.update(
        'reunion',
        {
          'estado': 'cerrada',
          'cerrada_en': now,
          'updated_at': now,
          'sincronizado': 0,
        },
        where: 'id_reunion = ?',
        whereArgs: [idReunion],
      );

      return {
        'id_reunion': idReunion,
        'id_tipo_cuota': idTipoCuota,
        'multas_generadas': faltas.length,
        'monto_multa': montoMulta,
        'total_multas_bs': montoMulta * faltas.length,
      };
    });
  }

  /// Lista todas las reuniones con el conteo de asistentes, faltas y el id_tipo_cuota generado si fue cerrada.
  Future<List<Map<String, dynamic>>> listarReuniones() async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT 
        r.*,
        COUNT(ar.id_asistencia_reunion) AS total_asistentes,
        SUM(CASE WHEN LOWER(ar.estado) = 'presente' THEN 1 ELSE 0 END) AS presentes,
        SUM(CASE WHEN LOWER(ar.estado) = 'falta' THEN 1 ELSE 0 END) AS faltas,
        SUM(CASE WHEN LOWER(ar.estado) = 'licencia' THEN 1 ELSE 0 END) AS licencias,
        (SELECT q.id_tipo_cuota FROM cuota q WHERE q.id_reunion = r.id_reunion LIMIT 1) AS id_tipo_cuota
      FROM reunion r
      LEFT JOIN asistencia_reunion ar ON ar.id_reunion = r.id_reunion
      GROUP BY r.id_reunion
      ORDER BY r.fecha DESC, r.created_at DESC
    ''');
  }

  /// Crea una nueva reunión y asigna a todos los conductores activos como asistentes.
  Future<String> crearReunion({
    required String tema,
    required String fecha,
    double montoMulta = 50.0,
    String estadoInicial = 'presente',
  }) async {
    final db = await _dh.database;
    final idReunion = _uuid.v4();
    final now = _nowIso();

    return await db.transaction<String>((txn) async {
      await txn.insert('reunion', {
        'id_reunion': idReunion,
        'fecha': fecha,
        'tema': tema.trim(),
        'monto_multa': montoMulta,
        'estado': 'pendiente',
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      final conductores = await txn.rawQuery('''
        SELECT id_conductor 
        FROM conductor 
        WHERE LOWER(estado) = 'activo'
        ORDER BY nombre ASC
      ''');

      final batch = txn.batch();
      for (final c in conductores) {
        batch.insert('asistencia_reunion', {
          'id_asistencia_reunion': _uuid.v4(),
          'id_reunion': idReunion,
          'id_conductor': c['id_conductor'],
          'estado': estadoInicial.toLowerCase(),
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });
      }
      await batch.commit(noResult: true);

      return idReunion;
    });
  }

  /// Obtiene la lista de asistencia de una reunión con datos del conductor.
  Future<List<Map<String, dynamic>>> asistenciasDeReunion(String idReunion) async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT 
        ar.*,
        c.nombre AS conductor_nombre,
        c.ci AS conductor_ci,
        c.foto AS conductor_foto,
        c.telefono AS conductor_telefono
      FROM asistencia_reunion ar
      JOIN conductor c ON c.id_conductor = ar.id_conductor
      WHERE ar.id_reunion = ?
      ORDER BY c.nombre ASC
    ''', [idReunion]);
  }

  /// Actualiza el estado de asistencia de un chofer en una reunión (presente, falta, licencia).
  Future<void> actualizarAsistenciaReunion(String idAsistenciaReunion, String nuevoEstado) async {
    final db = await _dh.database;
    final now = _nowIso();
    await db.update(
      'asistencia_reunion',
      {
        'estado': nuevoEstado.toLowerCase(),
        'updated_at': now,
        'sincronizado': 0,
      },
      where: 'id_asistencia_reunion = ?',
      whereArgs: [idAsistenciaReunion],
    );
  }

  /// Marca masivamente a todos los conductores de una reunión con el mismo estado ('presente', 'falta' o 'licencia').
  Future<void> marcarTodosAsistenciaReunion(String idReunion, String nuevoEstado) async {
    final db = await _dh.database;
    final now = _nowIso();
    await db.update(
      'asistencia_reunion',
      {
        'estado': nuevoEstado.toLowerCase(),
        'updated_at': now,
        'sincronizado': 0,
      },
      where: 'id_reunion = ?',
      whereArgs: [idReunion],
    );
  }

  /// Elimina una reunión y sus registros de asistencia. Si generó cuotas asociadas, las elimina limpiamente.
  Future<void> eliminarReunion(String idReunion) async {
    final db = await _dh.database;
    await db.transaction((txn) async {
      final cuotas = await txn.query(
        'cuota',
        columns: ['id_tipo_cuota'],
        where: 'id_reunion = ?',
        whereArgs: [idReunion],
        limit: 1,
      );
      if (cuotas.isNotEmpty) {
        final idTipoCuota = cuotas.first['id_tipo_cuota'] as String?;
        if (idTipoCuota != null) {
          await txn.delete('cuota', where: 'id_tipo_cuota = ?', whereArgs: [idTipoCuota]);
          await txn.delete('tipo_cuota', where: 'id_tipo_cuota = ?', whereArgs: [idTipoCuota]);
        }
      }
      await txn.delete('asistencia_reunion', where: 'id_reunion = ?', whereArgs: [idReunion]);
      await txn.delete('reunion', where: 'id_reunion = ?', whereArgs: [idReunion]);
    });
  }

  // ---------------------------------------------------------------------------
  // 11. PASANACO (GESTIÓN COMPLETA)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> listarPasanacos() async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT 
        p.*,
        COUNT(DISTINCT pp.id_conductor) AS cantidad_participantes,
        COUNT(DISTINCT rp.id_ronda) AS total_rondas,
        SUM(CASE WHEN LOWER(rp.estado) = 'entregada' THEN 1 ELSE 0 END) AS rondas_entregadas
      FROM pasanaco p
      LEFT JOIN participante_pasanaco pp ON pp.id_pasanaco = p.id_pasanaco
      LEFT JOIN ronda_pasanaco rp ON rp.id_pasanaco = p.id_pasanaco
      GROUP BY p.id_pasanaco
      ORDER BY p.fecha_inicio DESC
    ''');
  }

  Future<String> crearPasanaco({
    required String nombre,
    required double montoAporte,
    String periodicidad = 'semanal',
    required String fechaInicio,
    required List<String> idsConductores,
  }) async {
    final db = await _dh.database;
    final idPasanaco = _uuid.v4();
    final now = _nowIso();

    return await db.transaction<String>((txn) async {
      await txn.insert('pasanaco', {
        'id_pasanaco': idPasanaco,
        'nombre': nombre.trim(),
        'monto_aporte': montoAporte,
        'periodicidad': periodicidad,
        'fecha_inicio': fechaInicio,
        'estado': 'activo',
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      // Crear participantes con orden por defecto
      final batch = txn.batch();
      for (int i = 0; i < idsConductores.length; i++) {
        batch.insert('participante_pasanaco', {
          'id_participante': _uuid.v4(),
          'id_pasanaco': idPasanaco,
          'id_conductor': idsConductores[i],
          'numero_turno': i + 1,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });
      }
      await batch.commit(noResult: true);

      return idPasanaco;
    });
  }

  Future<List<Map<String, dynamic>>> participantesPasanaco(String idPasanaco) async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT 
        pp.*,
        c.nombre AS conductor_nombre,
        c.ci AS conductor_ci,
        c.foto AS conductor_foto
      FROM participante_pasanaco pp
      JOIN conductor c ON c.id_conductor = pp.id_conductor
      WHERE pp.id_pasanaco = ?
      ORDER BY pp.numero_turno ASC
    ''', [idPasanaco]);
  }

  Future<void> sortearTurnosPasanaco(String idPasanaco) async {
    final db = await _dh.database;
    final participantes = await db.query(
      'participante_pasanaco',
      where: 'id_pasanaco = ?',
      whereArgs: [idPasanaco],
    );
    final listaModificable = List<Map<String, dynamic>>.from(participantes)..shuffle();

    final now = _nowIso();
    final batch = db.batch();
    for (int i = 0; i < listaModificable.length; i++) {
      batch.update(
        'participante_pasanaco',
        {
          'numero_turno': i + 1,
          'updated_at': now,
          'sincronizado': 0,
        },
        where: 'id_participante = ?',
        whereArgs: [listaModificable[i]['id_participante']],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Lista las rondas creadas de un pasanaco con el beneficiario y totales recaudados.
  Future<List<Map<String, dynamic>>> rondasDePasanaco(String idPasanaco) async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT 
        rp.*,
        c.nombre AS beneficiario_nombre,
        c.ci AS beneficiario_ci,
        c.foto AS beneficiario_foto,
        COUNT(q.id_cuota) AS total_aportes_esperados,
        SUM(CASE WHEN LOWER(q.estado) = 'pagado' THEN 1 ELSE 0 END) AS aportes_pagados,
        SUM(CASE WHEN LOWER(q.estado) IN ('pendiente', 'parcial') THEN 1 ELSE 0 END) AS aportes_pendientes,
        COALESCE(SUM(q.monto_pagado), 0) AS total_recaudado
      FROM ronda_pasanaco rp
      JOIN conductor c ON c.id_conductor = rp.id_conductor_beneficiario
      LEFT JOIN cuota q ON q.id_ronda = rp.id_ronda
      WHERE rp.id_pasanaco = ?
      GROUP BY rp.id_ronda
      ORDER BY rp.numero_ronda ASC
    ''', [idPasanaco]);
  }

  /// Genera la siguiente ronda del pasanaco y las obligaciones (cuotas) de aporte para cada participante.
  Future<String> generarSiguienteRondaPasanaco({
    required String idPasanaco,
    required String fechaLimite,
    required String idUsuario,
  }) async {
    final db = await _dh.database;
    final now = _nowIso();
    final fechaHoy = now.substring(0, 10);

    return await db.transaction<String>((txn) async {
      // 1. Obtener datos del pasanaco
      final pasanacos = await txn.query(
        'pasanaco',
        where: 'id_pasanaco = ?',
        whereArgs: [idPasanaco],
        limit: 1,
      );
      if (pasanacos.isEmpty) {
        throw Exception('El pasanaco no existe.');
      }
      final pasanaco = pasanacos.first;
      final montoAporte = (pasanaco['monto_aporte'] as num).toDouble();
      final nombrePasanaco = pasanaco['nombre']?.toString() ?? 'Pasanaco';

      // 2. Participantes ordenados por número de turno
      final participantes = await txn.rawQuery('''
        SELECT pp.*, c.nombre AS conductor_nombre
        FROM participante_pasanaco pp
        JOIN conductor c ON c.id_conductor = pp.id_conductor
        WHERE pp.id_pasanaco = ?
        ORDER BY pp.numero_turno ASC
      ''', [idPasanaco]);

      if (participantes.isEmpty) {
        throw Exception('El pasanaco no tiene participantes registrados.');
      }

      // 3. Determinar número de la siguiente ronda
      final ultimasRondas = await txn.rawQuery('''
        SELECT MAX(numero_ronda) AS max_ronda 
        FROM ronda_pasanaco 
        WHERE id_pasanaco = ?
      ''', [idPasanaco]);

      final int maxRonda = (ultimasRondas.first['max_ronda'] as num?)?.toInt() ?? 0;
      final int siguienteNumero = maxRonda + 1;

      if (siguienteNumero > participantes.length) {
        throw Exception(
          'Ya se han generado todas las rondas ($maxRonda de ${participantes.length}) para este pasanaco.',
        );
      }

      // Beneficiario correspondiente al turno de esta ronda
      final beneficiario = participantes[siguienteNumero - 1];
      final idBeneficiario = beneficiario['id_conductor']?.toString() ?? '';
      final nombreBeneficiario = beneficiario['conductor_nombre']?.toString() ?? '';

      // 4. Obtener id_tipo_cuota para Pasanaco
      final tipoCuotaRes = await txn.query(
        'tipo_cuota',
        where: 'nombre = ?',
        whereArgs: ['Pasanaco'],
        limit: 1,
      );
      String idTipoCuota;
      if (tipoCuotaRes.isNotEmpty) {
        idTipoCuota = tipoCuotaRes.first['id_tipo_cuota']?.toString() ?? '';
      } else {
        idTipoCuota = _uuid.v4();
        await txn.insert('tipo_cuota', {
          'id_tipo_cuota': idTipoCuota,
          'nombre': 'Pasanaco',
          'monto_sugerido': montoAporte,
          'activo': 1,
          'es_fijo': 1,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });
      }

      // 5. Crear la ronda
      final idRonda = _uuid.v4();
      final totalRonda = montoAporte * participantes.length;

      await txn.insert('ronda_pasanaco', {
        'id_ronda': idRonda,
        'id_pasanaco': idPasanaco,
        'numero_ronda': siguienteNumero,
        'id_conductor_beneficiario': idBeneficiario,
        'fecha_limite': fechaLimite,
        'monto_total': totalRonda,
        'estado': 'pendiente',
        'created_at': now,
        'updated_at': now,
        'sincronizado': 0,
      });

      // 6. Generar la cuota de aporte para CADA participante
      final batch = txn.batch();
      for (final p in participantes) {
        batch.insert('cuota', {
          'id_cuota': _uuid.v4(),
          'id_conductor': p['id_conductor'],
          'id_tipo_cuota': idTipoCuota,
          'monto': montoAporte,
          'monto_pagado': 0.0,
          'fecha': fechaHoy,
          'estado': 'pendiente',
          'concepto': '$nombrePasanaco - Ronda #$siguienteNumero (Beneficiario: $nombreBeneficiario)',
          'fecha_vencimiento': fechaLimite,
          'id_ronda': idRonda,
          'registrado_por': idUsuario,
          'created_at': now,
          'updated_at': now,
          'sincronizado': 0,
        });
      }
      await batch.commit(noResult: true);

      return idRonda;
    });
  }

  /// Retorna las cuotas de aporte asociadas a una ronda específica de pasanaco.
  Future<List<Map<String, dynamic>>> aportesDeRonda(String idRonda) async {
    final db = await _dh.database;
    return db.rawQuery('''
      SELECT 
        q.*,
        c.nombre AS conductor_nombre,
        c.ci AS conductor_ci,
        c.foto AS conductor_foto,
        (q.monto - COALESCE(q.monto_pagado, 0)) AS saldo
      FROM cuota q
      JOIN conductor c ON c.id_conductor = q.id_conductor
      WHERE q.id_ronda = ?
      ORDER BY c.nombre ASC
    ''', [idRonda]);
  }

  /// Marca una ronda como entregada al conductor beneficiario.
  Future<void> entregarRondaPasanaco(String idRonda) async {
    final db = await _dh.database;
    final now = _nowIso();
    final fechaHoy = now.substring(0, 10);

    await db.transaction((txn) async {
      await txn.update(
        'ronda_pasanaco',
        {
          'estado': 'entregada',
          'fecha_entrega': fechaHoy,
          'updated_at': now,
          'sincronizado': 0,
        },
        where: 'id_ronda = ?',
        whereArgs: [idRonda],
      );

      final ronda = (await txn.query('ronda_pasanaco', where: 'id_ronda = ?', whereArgs: [idRonda])).first;
      final idPasanaco = ronda['id_pasanaco'];

      final pendientes = await txn.rawQuery('''
        SELECT COUNT(id_ronda) AS pendientes
        FROM ronda_pasanaco
        WHERE id_pasanaco = ? AND LOWER(estado) != 'entregada'
      ''', [idPasanaco]);

      final totalParticipantes = (await txn.rawQuery('''
        SELECT COUNT(id_participante) AS total
        FROM participante_pasanaco
        WHERE id_pasanaco = ?
      ''', [idPasanaco])).first['total'] as int;

      final totalRondas = (await txn.rawQuery('''
        SELECT COUNT(id_ronda) AS total
        FROM ronda_pasanaco
        WHERE id_pasanaco = ?
      ''', [idPasanaco])).first['total'] as int;

      final quedanPendientes = (pendientes.first['pendientes'] as int) > 0;
      if (!quedanPendientes && totalRondas >= totalParticipantes) {
        await txn.update(
          'pasanaco',
          {'estado': 'finalizado', 'updated_at': now},
          where: 'id_pasanaco = ?',
          whereArgs: [idPasanaco],
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 12. INFORME ECONÓMICO (VISTA E12)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> informeEconomico({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final db = await _dh.database;
    final condicionesPago = <String>[];
    final argsPago = <Object?>[];

    if (fechaDesde != null && fechaDesde.isNotEmpty) {
      condicionesPago.add('p.fecha >= ?');
      argsPago.add(fechaDesde);
    }
    if (fechaHasta != null && fechaHasta.isNotEmpty) {
      condicionesPago.add('p.fecha <= ?');
      argsPago.add(fechaHasta);
    }
    final wherePago = condicionesPago.isEmpty ? '' : 'WHERE ${condicionesPago.join(' AND ')}';

    // Recaudado por Tipo de Cuota
    final porTipo = await db.rawQuery('''
      SELECT 
        t.nombre AS tipo_nombre,
        COALESCE(SUM(p.monto), 0) AS total_recaudado,
        COUNT(p.id_pago) AS cantidad_pagos
      FROM tipo_cuota t
      LEFT JOIN cuota q ON q.id_tipo_cuota = t.id_tipo_cuota
      LEFT JOIN pago p ON p.id_cuota = q.id_cuota $wherePago
      GROUP BY t.id_tipo_cuota, t.nombre
      ORDER BY total_recaudado DESC
    ''');

    // Pendiente por Tipo de Cuota
    final pendientePorTipo = await db.rawQuery('''
      SELECT 
        t.nombre AS tipo_nombre,
        COALESCE(SUM(q.monto - COALESCE(q.monto_pagado, 0)), 0) AS total_pendiente
      FROM tipo_cuota t
      JOIN cuota q ON q.id_tipo_cuota = t.id_tipo_cuota
      WHERE LOWER(q.estado) IN ('pendiente', 'parcial')
        AND (q.monto - COALESCE(q.monto_pagado, 0)) > 0
      GROUP BY t.id_tipo_cuota, t.nombre
    ''');

    final mapaPendiente = <String, double>{};
    for (final r in pendientePorTipo) {
      mapaPendiente[r['tipo_nombre']?.toString() ?? ''] =
          (r['total_pendiente'] as num?)?.toDouble() ?? 0.0;
    }

    final listaComparativa = <Map<String, dynamic>>[];
    double granTotalRecaudado = 0.0;
    double granTotalPendiente = 0.0;

    for (final t in porTipo) {
      final tipo = t['tipo_nombre']?.toString() ?? '';
      final rec = (t['total_recaudado'] as num?)?.toDouble() ?? 0.0;
      final pend = mapaPendiente[tipo] ?? 0.0;
      granTotalRecaudado += rec;
      granTotalPendiente += pend;

      listaComparativa.add({
        'tipo_nombre': tipo,
        'recaudado': rec,
        'pendiente': pend,
        'total_comprometido': rec + pend,
      });
    }

    return {
      'fecha_desde': fechaDesde,
      'fecha_hasta': fechaHasta,
      'comparativa_tipos': listaComparativa,
      'gran_total_recaudado': granTotalRecaudado,
      'gran_total_pendiente': granTotalPendiente,
    };
  }
}
