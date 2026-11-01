import 'package:uuid/uuid.dart';
import '../domain/reglas_asistencia.dart';
import 'database_helper.dart';

/// Resultado del proceso de registro de asistencia.
class ResultadoRegistroAsistencia {
  final bool exito;
  final String mensaje;
  final Map<String, dynamic>? asistencia;
  final Map<String, dynamic>? sancion;
  final bool esTardanza;
  final int vueltasCastigo;

  const ResultadoRegistroAsistencia({
    required this.exito,
    required this.mensaje,
    this.asistencia,
    this.sancion,
    this.esTardanza = false,
    this.vueltasCastigo = 0,
  });
}

/// Repositorio de Asistencia del sindicato Continental.
/// Gestiona registro por GPS, manual por supervisor, simulación y calibración de geocercas.
class AsistenciaRepo {
  AsistenciaRepo._internal();
  static final AsistenciaRepo instance = AsistenciaRepo._internal();

  static const _uuid = Uuid();

  String _hoyString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _horaActualString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// Verifica si el conductor ya cuenta con asistencia registrada en la fecha dada.
  Future<Map<String, dynamic>?> obtenerAsistenciaHoy(String idConductor, [String? fecha]) async {
    final db = await DatabaseHelper.instance.database;
    final f = fecha ?? _hoyString();
    final res = await db.query(
      'asistencia',
      where: 'id_conductor = ? AND fecha = ?',
      whereArgs: [idConductor, f],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  /// Registro automatizado de asistencia mediante geocerca GPS.
  Future<ResultadoRegistroAsistencia> registrarAsistenciaGps({
    required String idConductor,
    required String idPunto,
    required double latitud,
    required double longitud,
    required double precisionM,
    required double distanciaM,
    String? horaManual,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final hoy = _hoyString();
    final hora = horaManual ?? _horaActualString();

    // 1. Validar si ya marcó hoy
    final yaExiste = await obtenerAsistenciaHoy(idConductor, hoy);
    if (yaExiste != null) {
      return ResultadoRegistroAsistencia(
        exito: false,
        mensaje: 'Ya registraste asistencia hoy (${yaExiste['hora_llegada']} - ${yaExiste['estado']?.toString().toUpperCase()}).',
        asistencia: yaExiste,
      );
    }

    // 2. Obtener horario y configuración de sanciones
    final horario = await DatabaseHelper.instance.obtenerHorarioActivo();
    final horaEntrada = horario?['hora_entrada']?.toString() ?? '07:00';
    final toleranciaMin = (horario?['tolerancia_min'] as num?)?.toInt() ?? 60;
    final idHorario = horario?['id_horario']?.toString() ?? 'horario_manana';

    final vueltasConfig = await DatabaseHelper.instance.getConfig('vueltas_por_tardanza', '2');
    final vueltasCastigo = int.tryParse(vueltasConfig ?? '2') ?? 2;

    // 3. Evaluar con ReglasAsistencia de dominio
    final eval = ReglasAsistencia.evaluarLlegada(
      horaLlegada: hora,
      horaEntrada: horaEntrada,
      toleranciaMin: toleranciaMin,
      vueltasPorTardanza: vueltasCastigo,
    );

    final idAsistencia = _uuid.v4();
    final idSancion = eval.generaSancion ? _uuid.v4() : null;
    final nowIso = DateTime.now().toIso8601String();

    Map<String, dynamic>? asistenciaData;
    Map<String, dynamic>? sancionData;

    // 4. Ejecución atómica en SQLite
    await db.transaction((txn) async {
      asistenciaData = {
        'id_asistencia': idAsistencia,
        'id_conductor': idConductor,
        'id_punto': idPunto,
        'id_horario': idHorario,
        'fecha': hoy,
        'hora_llegada': hora,
        'estado': eval.estado,
        'latitud': latitud,
        'longitud': longitud,
        'precision_m': precisionM,
        'distancia_m': distanciaM,
        'minutos_retraso': eval.minutosRetraso,
        'metodo': 'gps',
        'registrado_por': null,
        'justificacion': null,
        'es_simulada': 0,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sincronizado': 0,
      };
      await txn.insert('asistencia', asistenciaData!);

      if (eval.generaSancion) {
        sancionData = {
          'id_sancion': idSancion,
          'id_conductor': idConductor,
          'id_asistencia': idAsistencia,
          'motivo': eval.motivoSancion ?? 'Tardanza en asistencia',
          'vueltas_asignadas': eval.vueltasSancion,
          'vueltas_cumplidas': 0,
          'estado': 'pendiente',
          'origen': 'tardanza_auto',
          'tipo': 'tardanza',
          'es_simulada': 0,
          'fecha': hoy,
          'hora': hora,
          'created_at': nowIso,
          'updated_at': nowIso,
          'sincronizado': 0,
        };
        await txn.insert('sancion', sancionData!);
      }
    });

    // 5. Bitácora de auditoría
    await DatabaseHelper.instance.registrarBitacora(
      accion: 'marcar_asistencia_gps',
      tabla: 'asistencia',
      idRegistro: idAsistencia,
      idUsuario: idConductor,
      detalles: 'Estado: ${eval.estado}, hora: $hora, dist: ${distanciaM.toStringAsFixed(1)}m, castigo: ${eval.vueltasSancion} vueltas',
    );

    final mensaje = eval.esPresente
        ? '¡Asistencia registrada a tiempo ($hora)! Buen viaje.'
        : 'Llegada registrada ($hora). Tardanza de ${eval.minutosRetraso} min. Se asignaron ${eval.vueltasSancion} vueltas de castigo para la noche (desde 21:00).';

    return ResultadoRegistroAsistencia(
      exito: true,
      mensaje: mensaje,
      asistencia: asistenciaData,
      sancion: sancionData,
      esTardanza: eval.esTardanza,
      vueltasCastigo: eval.vueltasSancion,
    );
  }

  /// Registro manual realizado por un supervisor con justificación obligatoria.
  Future<ResultadoRegistroAsistencia> registrarAsistenciaManual({
    required String idConductor,
    required String idPunto,
    required String idSupervisor,
    required String estado, // 'presente' | 'tardanza' | 'falta'
    required String justificacion,
    String? fecha,
    String? horaManual,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final f = fecha ?? _hoyString();
    final hora = horaManual ?? _horaActualString();

    final yaExiste = await obtenerAsistenciaHoy(idConductor, f);
    if (yaExiste != null) {
      return ResultadoRegistroAsistencia(
        exito: false,
        mensaje: 'El conductor ya tiene asistencia registrada para la fecha $f.',
        asistencia: yaExiste,
      );
    }

    final idAsistencia = _uuid.v4();
    final nowIso = DateTime.now().toIso8601String();
    final horario = await DatabaseHelper.instance.obtenerHorarioActivo();
    final idHorario = horario?['id_horario']?.toString() ?? 'horario_manana';

    final vueltasConfig = await DatabaseHelper.instance.getConfig('vueltas_por_tardanza', '2');
    final vueltasCastigo = int.tryParse(vueltasConfig ?? '2') ?? 2;
    final esTardanza = estado.toLowerCase() == 'tardanza';

    Map<String, dynamic>? asistenciaData;
    Map<String, dynamic>? sancionData;

    await db.transaction((txn) async {
      asistenciaData = {
        'id_asistencia': idAsistencia,
        'id_conductor': idConductor,
        'id_punto': idPunto,
        'id_horario': idHorario,
        'fecha': f,
        'hora_llegada': hora,
        'estado': estado.toLowerCase(),
        'latitud': null,
        'longitud': null,
        'precision_m': null,
        'distancia_m': null,
        'minutos_retraso': esTardanza ? 15 : 0,
        'metodo': 'manual',
        'registrado_por': idSupervisor,
        'justificacion': justificacion,
        'es_simulada': 0,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sincronizado': 0,
      };
      await txn.insert('asistencia', asistenciaData!);

      if (esTardanza) {
        sancionData = {
          'id_sancion': _uuid.v4(),
          'id_conductor': idConductor,
          'id_asistencia': idAsistencia,
          'motivo': 'Tardanza registrada por supervisor: $justificacion',
          'vueltas_asignadas': vueltasCastigo,
          'vueltas_cumplidas': 0,
          'estado': 'pendiente',
          'origen': 'manual',
          'tipo': 'tardanza',
          'es_simulada': 0,
          'fecha': f,
          'hora': hora,
          'created_at': nowIso,
          'updated_at': nowIso,
          'sincronizado': 0,
        };
        await txn.insert('sancion', sancionData!);
      }
    });

    await DatabaseHelper.instance.registrarBitacora(
      accion: 'marcar_asistencia_manual',
      tabla: 'asistencia',
      idRegistro: idAsistencia,
      idUsuario: idSupervisor,
      detalles: 'Conductor: $idConductor, estado: $estado, motivo: $justificacion',
    );

    return ResultadoRegistroAsistencia(
      exito: true,
      mensaje: 'Asistencia manual registrada exitosamente ($estado).',
      asistencia: asistenciaData,
      sancion: sancionData,
      esTardanza: esTardanza,
      vueltasCastigo: esTardanza ? vueltasCastigo : 0,
    );
  }

  /// Registro de simulación (Superadmin para demostración de defensa de grado).
  Future<ResultadoRegistroAsistencia> simularLlegada({
    required String idConductor,
    required String idPunto,
    required String horaSimulada,
    required double latitud,
    required double longitud,
    required double distanciaM,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final hoy = _hoyString();

    final horario = await DatabaseHelper.instance.obtenerHorarioActivo();
    final horaEntrada = horario?['hora_entrada']?.toString() ?? '07:00';
    final toleranciaMin = (horario?['tolerancia_min'] as num?)?.toInt() ?? 60;
    final idHorario = horario?['id_horario']?.toString() ?? 'horario_manana';

    final vueltasConfig = await DatabaseHelper.instance.getConfig('vueltas_por_tardanza', '2');
    final vueltasCastigo = int.tryParse(vueltasConfig ?? '2') ?? 2;

    final eval = ReglasAsistencia.evaluarLlegada(
      horaLlegada: horaSimulada,
      horaEntrada: horaEntrada,
      toleranciaMin: toleranciaMin,
      vueltasPorTardanza: vueltasCastigo,
    );

    final idAsistencia = _uuid.v4();
    final idSancion = eval.generaSancion ? _uuid.v4() : null;
    final nowIso = DateTime.now().toIso8601String();

    Map<String, dynamic>? asistenciaData;
    Map<String, dynamic>? sancionData;

    await db.transaction((txn) async {
      asistenciaData = {
        'id_asistencia': idAsistencia,
        'id_conductor': idConductor,
        'id_punto': idPunto,
        'id_horario': idHorario,
        'fecha': hoy,
        'hora_llegada': horaSimulada,
        'estado': eval.estado,
        'latitud': latitud,
        'longitud': longitud,
        'precision_m': 8.5,
        'distancia_m': distanciaM,
        'minutos_retraso': eval.minutosRetraso,
        'metodo': 'simulado',
        'registrado_por': 'superadmin',
        'justificacion': 'Simulación de defensa de grado',
        'es_simulada': 1,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sincronizado': 0,
      };
      await txn.insert('asistencia', asistenciaData!);

      if (eval.generaSancion) {
        sancionData = {
          'id_sancion': idSancion,
          'id_conductor': idConductor,
          'id_asistencia': idAsistencia,
          'motivo': '[SIMULADA] ${eval.motivoSancion}',
          'vueltas_asignadas': eval.vueltasSancion,
          'vueltas_cumplidas': 0,
          'estado': 'pendiente',
          'origen': 'simulado',
          'tipo': 'tardanza',
          'es_simulada': 1,
          'fecha': hoy,
          'hora': horaSimulada,
          'created_at': nowIso,
          'updated_at': nowIso,
          'sincronizado': 0,
        };
        await txn.insert('sancion', sancionData!);
      }
    });

    return ResultadoRegistroAsistencia(
      exito: true,
      mensaje: '[DEMO] Simulación aplicada: ${eval.estado.toUpperCase()} a las $horaSimulada (${eval.minutosRetraso} min retraso, ${eval.vueltasSancion} vueltas castigo).',
      asistencia: asistenciaData,
      sancion: sancionData,
      esTardanza: eval.esTardanza,
      vueltasCastigo: eval.vueltasSancion,
    );
  }

  /// Elimina los registros generados en modo simulación.
  Future<int> purgarAsistenciasSimuladas() async {
    final db = await DatabaseHelper.instance.database;
    var eliminadas = 0;
    await db.transaction((txn) async {
      await txn.delete('sancion', where: 'es_simulada = 1');
      eliminadas = await txn.delete('asistencia', where: 'es_simulada = 1');
    });
    return eliminadas;
  }

  /// Actualiza las coordenadas y radio de geocerca de un punto de control.
  Future<void> actualizarPuntoControl({
    required String idPunto,
    double? latitud,
    double? longitud,
    int? radioM,
    String? nombre,
    bool? esPuntoAsistencia,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (latitud != null) updates['latitud'] = latitud;
    if (longitud != null) updates['longitud'] = longitud;
    if (radioM != null) updates['radio_m'] = radioM;
    if (nombre != null) updates['nombre'] = nombre;
    if (esPuntoAsistencia != null) updates['es_punto_asistencia'] = esPuntoAsistencia ? 1 : 0;
    if (latitud != null && longitud != null) updates['coord_verificada'] = 1;

    await db.update('punto_de_control', updates, where: 'id_punto = ?', whereArgs: [idPunto]);
  }

  /// Resumen estadístico del día de asistencia.
  Future<Map<String, int>> obtenerEstadisticasHoy([String? fecha]) async {
    final db = await DatabaseHelper.instance.database;
    final f = fecha ?? _hoyString();
    final res = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN LOWER(estado) = 'presente' THEN 1 ELSE 0 END) AS presentes,
        SUM(CASE WHEN LOWER(estado) = 'tardanza' THEN 1 ELSE 0 END) AS tardanzas,
        SUM(CASE WHEN LOWER(estado) = 'falta' THEN 1 ELSE 0 END) AS faltas,
        COUNT(*) AS total
      FROM asistencia
      WHERE fecha = ?
    ''', [f]);

    if (res.isEmpty) return {'presentes': 0, 'tardanzas': 0, 'faltas': 0, 'total': 0};
    final row = res.first;
    return {
      'presentes': (row['presentes'] as num?)?.toInt() ?? 0,
      'tardanzas': (row['tardanzas'] as num?)?.toInt() ?? 0,
      'faltas': (row['faltas'] as num?)?.toInt() ?? 0,
      'total': (row['total'] as num?)?.toInt() ?? 0,
    };
  }
}
