import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/economia_repo.dart';

/// Servicio y Modal para generar, configurar y enviar el Informe Económico
/// directamente a WhatsApp con el mensaje pre-cargado tipo Chatbot.
/// Diferencia automáticamente entre Apoyo Económico (pago único) y Canastón (control semanal por fechas).
class DialogoInformeWhatsapp {
  static const MethodChannel _channel = MethodChannel('continental/whatsapp');

  // Claves de configuración persistente en SharedPreferences
  static const String _kSaludo = 'wa_config_saludo';
  static const String _kPieMensaje = 'wa_config_pie';
  static const String _kTelefono = 'wa_config_telefono';
  static const String _kNombreGrupo = 'wa_config_nombre_grupo';
  static const String _kMostrarMontoDeudor = 'wa_config_mostrar_monto_deudor';
  static const String _kMostrarPagados = 'wa_config_mostrar_pagados';
  static const String _kEnvioDirecto = 'wa_config_envio_directo';

  /// Carga la configuración actual desde SharedPreferences.
  static Future<Map<String, dynamic>> cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'saludo':
          prefs.getString(_kSaludo) ??
          'BUENOS DÍAS COMPAÑEROS DEL GRUPO CONTINENTAL',
      'pie':
          prefs.getString(_kPieMensaje) ??
          'Se solicita a los compañeros pendientes pasar por Secretaría de Hacienda a regularizar su cuota.',
      'telefono': prefs.getString(_kTelefono) ?? '',
      'nombre_grupo': prefs.getString(_kNombreGrupo) ?? 'Grupo Continental',
      'mostrar_monto_deudor': prefs.getBool(_kMostrarMontoDeudor) ?? false,
      'mostrar_pagados': prefs.getBool(_kMostrarPagados) ?? false,
      'envio_directo': prefs.getBool(_kEnvioDirecto) ?? false,
    };
  }

  /// Guarda la configuración personalizada en SharedPreferences.
  static Future<void> guardarConfiguracion({
    required String saludo,
    required String pie,
    required String telefono,
    required String nombreGrupo,
    required bool mostrarMontoDeudor,
    required bool mostrarPagados,
    required bool envioDirecto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSaludo, saludo.trim());
    await prefs.setString(_kPieMensaje, pie.trim());
    await prefs.setString(_kTelefono, telefono.trim());
    await prefs.setString(_kNombreGrupo, nombreGrupo.trim());
    await prefs.setBool(_kMostrarMontoDeudor, mostrarMontoDeudor);
    await prefs.setBool(_kMostrarPagados, mostrarPagados);
    await prefs.setBool(_kEnvioDirecto, envioDirecto);
  }

  static String _fmtMonto(double v) {
    if ((v - v.roundToDouble()).abs() < 0.005) {
      return v.round().toString();
    }
    return v.toStringAsFixed(2);
  }

  static String _formatearDiaMesTexto(String fechaIso) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    try {
      final d = DateTime.parse(fechaIso.trim());
      final dia = d.day.toString().padLeft(2, '0');
      return '$dia de ${meses[d.month - 1]}';
    } catch (_) {
      return fechaIso;
    }
  }

  static String _nombreMesDeFecha(String fechaIso) {
    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    try {
      final d = DateTime.parse(fechaIso.trim());
      return '${meses[d.month - 1]} ${d.year}';
    } catch (_) {
      return '';
    }
  }

  /// Determina automáticamente cuál es la fecha de "Esta Semana" dentro de las fechas del cronograma,
  /// ignorando las fechas futuras posteriores a esta semana.
  static String determinarFechaSemanaActual(List<String> fechasOrdenadas) {
    if (fechasOrdenadas.isEmpty) return '';
    final ahora = DateTime.now();
    // Consideramos como "esta semana" la fecha programada más reciente que ya pasó
    // o que ocurre dentro de los próximos 6 días.
    final limiteSemana = ahora
        .add(const Duration(days: 6))
        .toIso8601String()
        .substring(0, 10);

    String candidata = fechasOrdenadas.first;
    for (final f in fechasOrdenadas) {
      if (f.compareTo(limiteSemana) <= 0) {
        candidata = f;
      } else {
        break;
      }
    }
    return candidata;
  }

  /// Construye automáticamente el texto del informe para WhatsApp según el tipo de cuota:
  /// - Si es CANASTÓN (con cronograma de fechas): genera el informe específico de ESTA SEMANA
  ///   y de las FECHAS PASADAS que deben (sin incluir nunca fechas del futuro).
  /// - Si es MULTA: genera el informe exclusivo de multas por inasistencia a reunión.
  /// - Si es APOYO ECONÓMICO: genera el informe de ayuda económica al compañero.
  static String construirMensaje({
    required Map<String, dynamic> cuota,
    required List<Map<String, dynamic>> conductores,
    required Map<String, dynamic> config,
    List<Map<String, dynamic>>? matrizCronograma,
    String? fechaSemanaSeleccionada,
  }) {
    final categoria = cuota['categoria']?.toString().toLowerCase() ?? 'ayuda';
    final nombreCuota = cuota['nombre']?.toString().trim() ?? '';
    final listaMatriz = matrizCronograma ?? const [];

    // Extraer fechas únicas ordenadas si existen
    final fechasSet = <String>{};
    for (final r in listaMatriz) {
      final f = r['fecha_programada']?.toString().trim() ?? '';
      if (f.isNotEmpty) fechasSet.add(f);
    }
    final fechasOrdenadas = fechasSet.toList()..sort();

    if ((categoria == 'canaston' || fechasOrdenadas.length > 1) &&
        fechasOrdenadas.isNotEmpty) {
      return _construirMensajeCanastonSemanal(
        cuota: cuota,
        conductores: conductores,
        config: config,
        matrizCronograma: listaMatriz,
        fechasOrdenadas: fechasOrdenadas,
        fechaSemana:
            fechaSemanaSeleccionada ??
            determinarFechaSemanaActual(fechasOrdenadas),
      );
    }

    if (categoria.contains('multa') ||
        nombreCuota.toLowerCase().startsWith('multa')) {
      return _construirMensajeMultas(
        cuota: cuota,
        conductores: conductores,
        config: config,
      );
    }

    return _construirMensajeApoyoEconomico(
      cuota: cuota,
      conductores: conductores,
      config: config,
    );
  }

  /// Genera el informe exclusivo de MULTAS POR INASISTENCIA A REUNIÓN.
  /// Muestra el tema de la reunión, el monto de la multa y únicamente los nombres
  /// de los compañeros (sin repetir el monto al lado de cada nombre).
  static String _construirMensajeMultas({
    required Map<String, dynamic> cuota,
    required List<Map<String, dynamic>> conductores,
    required Map<String, dynamic> config,
  }) {
    final nombreCuota = cuota['nombre']?.toString().trim() ?? 'Multa';
    final descripcion = cuota['descripcion']?.toString().trim() ?? '';
    final montoMulta = (cuota['monto_sugerido'] as num?)?.toDouble() ?? 50.0;

    // Extraer el nombre/tema de la reunión (ej. "Multa: michael" -> "michael")
    String temaReunion = nombreCuota;
    if (nombreCuota.contains(':')) {
      temaReunion = nombreCuota.split(':').sublist(1).join(':').trim();
    }
    if (temaReunion.isEmpty) {
      temaReunion = nombreCuota;
    }

    // Extraer fecha de la reunión si está en la descripción (ej. "(2026-10-31)")
    String fechaReunionTexto = '';
    final matchFecha = RegExp(r'\((\d{4}-\d{2}-\d{2})\)').firstMatch(descripcion);
    if (matchFecha != null) {
      fechaReunionTexto = _formatearDiaMesTexto(matchFecha.group(1)!);
    }

    final List<String> debenMulta = [];
    final List<String> pagaronMulta = [];

    for (final c in conductores) {
      final nombre = c['conductor_nombre']?.toString().trim() ?? 'Conductor';
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      if (falta <= 0.001) {
        pagaronMulta.add('- $nombre');
      } else {
        // Solo el nombre, sin monto al lado
        debenMulta.add('- $nombre');
      }
    }

    final saludo =
        (config['saludo']?.toString() ??
                'BUENOS DÍAS COMPAÑEROS DEL GRUPO CONTINENTAL')
            .trim();

    final sb = StringBuffer();

    if (saludo.isNotEmpty) {
      sb.writeln('*${saludo.toUpperCase()}* 🚍');
      sb.writeln();
    }

    sb.writeln('📋 *INFORME DE MULTAS POR INASISTENCIA A REUNIÓN*');
    if (fechaReunionTexto.isNotEmpty) {
      sb.writeln(
        '📌 *REUNIÓN:* ${temaReunion.toUpperCase()} ($fechaReunionTexto)',
      );
    } else {
      sb.writeln('📌 *REUNIÓN:* ${temaReunion.toUpperCase()}');
    }
    sb.writeln();

    if (debenMulta.isEmpty) {
      sb.writeln(
        '✅ *¡TODOS LOS COMPAÑEROS QUE NO ASISTIERON A LA REUNIÓN "${temaReunion.toUpperCase()}" YA PAGARON SU MULTA DE Bs. ${_fmtMonto(montoMulta)}!*',
      );
    } else {
      sb.writeln(
        '⚠️ *LOS COMPAÑEROS QUE NO ASISTIERON A LA REUNIÓN "${temaReunion.toUpperCase()}" DEBEN PAGAR SU MULTA DE Bs. ${_fmtMonto(montoMulta)}:*',
      );
      for (final linea in debenMulta) {
        sb.writeln(linea);
      }
    }

    if (pagaronMulta.isNotEmpty) {
      sb.writeln();
      sb.writeln('✅ *COMPAÑEROS QUE YA PAGARON SU MULTA:*');
      for (final linea in pagaronMulta) {
        sb.writeln(linea);
      }
    }

    sb.writeln();
    sb.writeln(
      '_Se solicita a los compañeros pendientes pasar por Secretaría de Hacienda a cancelar su multa._',
    );

    return sb.toString().trim();
  }

  /// Genera el informe semanal específico de CANASTÓN:
  /// 1. Compañeros que PAGARON esta semana.
  /// 2. Compañeros que FALTAN PAGAR esta semana.
  /// 3. Compañeros que DEBEN DE FECHAS PASADAS (detallando qué fechas pasadas no pagaron y cuánto deben).
  /// (No incluye fechas futuras).
  static String _construirMensajeCanastonSemanal({
    required Map<String, dynamic> cuota,
    required List<Map<String, dynamic>> conductores,
    required Map<String, dynamic> config,
    required List<Map<String, dynamic>> matrizCronograma,
    required List<String> fechasOrdenadas,
    required String fechaSemana,
  }) {
    final nombreCuota = cuota['nombre']?.toString() ?? 'Canastón';
    final montoSugerido =
        (cuota['monto_sugerido'] as num?)?.toDouble() ?? 20.0;
    final saludo =
        (config['saludo']?.toString() ??
                'BUENOS DÍAS COMPAÑEROS DEL GRUPO CONTINENTAL')
            .trim();
    final pie = (config['pie']?.toString() ?? '').trim();

    // Organizar por conductor -> fecha -> {monto, pagado}
    final Map<String, Map<String, Map<String, double>>> datosPorConductor = {};
    for (final row in matrizCronograma) {
      final idCond = row['id_conductor']?.toString() ?? '';
      final f = row['fecha_programada']?.toString().trim() ?? '';
      if (idCond.isEmpty || f.isEmpty) continue;
      final monto = (row['monto'] as num?)?.toDouble() ?? montoSugerido;
      final pagado = (row['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      datosPorConductor.putIfAbsent(idCond, () => {});
      datosPorConductor[idCond]![f] = {
        'monto': monto,
        'pagado': pagado,
        'falta': (monto - pagado) > 0 ? (monto - pagado) : 0.0,
      };
    }

    // Fechas pasadas (estrictamente anteriores a la fecha de esta semana)
    final fechasPasadas = fechasOrdenadas
        .where((f) => f.compareTo(fechaSemana) < 0)
        .toList();

    final textoFechaSemana = _formatearDiaMesTexto(fechaSemana);
    final mesTexto = _nombreMesDeFecha(fechaSemana);

    // Listas para clasificar a los conductores
    final List<String> pagaronEstaSemana = [];
    final List<String> faltanEstaSemana = [];
    final List<String> debenFechasPasadas = [];

    for (final c in conductores) {
      final idCond = c['id_conductor']?.toString() ?? '';
      final nombre =
          (c['conductor_nombre']?.toString() ?? 'Conductor').toUpperCase();
      final mapaFechas = datosPorConductor[idCond] ?? {};

      // 1. Revisar ESTA SEMANA (fechaSemana)
      final regSemana = mapaFechas[fechaSemana];
      final montoSem = regSemana?['monto'] ?? montoSugerido;
      final pagadoSem = regSemana?['pagado'] ?? 0.0;
      final faltaSem = (montoSem - pagadoSem) > 0 ? (montoSem - pagadoSem) : 0.0;

      if (faltaSem <= 0.001 && regSemana != null) {
        final nro = pagaronEstaSemana.length + 1;
        pagaronEstaSemana.add('$nro. *$nombre*');
      } else {
        final nro = faltanEstaSemana.length + 1;
        faltanEstaSemana.add(
          '$nro. *$nombre*\n   - No pagó el $textoFechaSemana, debe Bs. ${_fmtMonto(faltaSem)}',
        );
      }

      // 2. Revisar FECHAS PASADAS (anteriores a esta semana)
      if (fechasPasadas.isNotEmpty) {
        final List<String> lineasFechasPasadas = [];
        double sumaDeudaPasada = 0.0;

        for (final fAnt in fechasPasadas) {
          final regAnt = mapaFechas[fAnt];
          final montoAnt = regAnt?['monto'] ?? montoSugerido;
          final pagadoAnt = regAnt?['pagado'] ?? 0.0;
          final faltaAnt =
              (montoAnt - pagadoAnt) > 0 ? (montoAnt - pagadoAnt) : 0.0;
          if (faltaAnt > 0.001) {
            final fTexto = _formatearDiaMesTexto(fAnt);
            lineasFechasPasadas.add(
              '   - No pagó el $fTexto, debe Bs. ${_fmtMonto(faltaAnt)}',
            );
            sumaDeudaPasada += faltaAnt;
          }
        }

        if (lineasFechasPasadas.isNotEmpty) {
          final nro = debenFechasPasadas.length + 1;
          final totalStr = lineasFechasPasadas.length > 1
              ? '\n   - Total deuda pasada: Bs. ${_fmtMonto(sumaDeudaPasada)}'
              : '';
          debenFechasPasadas.add(
            '$nro. *$nombre*\n${lineasFechasPasadas.join('\n')}$totalStr',
          );
        }
      }
    }

    final sb = StringBuffer();

    if (saludo.isNotEmpty) {
      sb.writeln('*${saludo.toUpperCase()}* 🚍');
      sb.writeln();
    }

    sb.writeln(
      '📋 *INFORME SEMANAL DE ${nombreCuota.toUpperCase()}*',
    );
    if (mesTexto.isNotEmpty) {
      sb.writeln(
        '🗓️ *MES DE $mesTexto — Fecha de esta semana: $textoFechaSemana (Bs. ${_fmtMonto(montoSugerido)})*',
      );
    } else {
      sb.writeln(
        '🗓️ *Fecha de esta semana: $textoFechaSemana (Bs. ${_fmtMonto(montoSugerido)})*',
      );
    }
    sb.writeln();

    // SECCIÓN 1: PAGARON ESTA SEMANA
    sb.writeln(
      '✅ *LOS COMPAÑEROS QUE PAGARON ESTA SEMANA ($textoFechaSemana):*',
    );
    if (pagaronEstaSemana.isEmpty) {
      sb.writeln('_Ningún compañero registró su pago de esta semana todavía._');
    } else {
      for (final linea in pagaronEstaSemana) {
        sb.writeln(linea);
      }
    }
    sb.writeln();

    // SECCIÓN 2: FALTAN PAGAR ESTA SEMANA
    sb.writeln(
      '⏳ *LOS COMPAÑEROS QUE FALTAN PAGAR ESTA SEMANA ($textoFechaSemana):*',
    );
    if (faltanEstaSemana.isEmpty) {
      sb.writeln(
        '🎉 *¡Todos los compañeros están al día con la cuota de esta semana!*',
      );
    } else {
      for (final linea in faltanEstaSemana) {
        sb.writeln(linea);
      }
    }

    // SECCIÓN 3: DEBEN DE FECHAS PASADAS (solo si existen fechas anteriores)
    if (fechasPasadas.isNotEmpty) {
      sb.writeln();
      sb.writeln('⚠️ *LOS COMPAÑEROS QUE DEBEN DE FECHAS PASADAS:*');
      if (debenFechasPasadas.isEmpty) {
        sb.writeln('✅ _Ningún compañero tiene deudas de semanas pasadas._');
      } else {
        for (final linea in debenFechasPasadas) {
          sb.writeln(linea);
        }
      }
    }

    if (pie.isNotEmpty) {
      sb.writeln();
      sb.writeln('_${pie}_');
    }

    return sb.toString().trim();
  }

  /// Genera el informe de APOYO ECONÓMICO / CUOTA ÚNICA.
  static String _construirMensajeApoyoEconomico({
    required Map<String, dynamic> cuota,
    required List<Map<String, dynamic>> conductores,
    required Map<String, dynamic> config,
  }) {
    final nombreCuota = cuota['nombre']?.toString() ?? 'Cuota Sindical';
    final descripcion = cuota['descripcion']?.toString() ?? '';
    final montoSugerido =
        (cuota['monto_sugerido'] as num?)?.toDouble() ?? 0.0;

    String? beneficiario;
    String modalidad = 'OBLIGATORIA';
    if (descripcion.contains('|')) {
      for (final part in descripcion.split('|')) {
        final p = part.trim();
        if (p.startsWith('Beneficiario:')) {
          beneficiario = p.replaceFirst('Beneficiario:', '').trim();
        } else if (p.startsWith('Modalidad:')) {
          modalidad = p.replaceFirst('Modalidad:', '').trim().toUpperCase();
        }
      }
    } else if (nombreCuota.contains(':')) {
      beneficiario = nombreCuota.split(':').last.trim();
    }

    double totalRecaudado = 0;
    final List<Map<String, dynamic>> noPagaron = [];
    final List<Map<String, dynamic>> siPagaron = [];

    for (final c in conductores) {
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      totalRecaudado += pagado;
      if (falta <= 0.001) {
        siPagaron.add(c);
      } else {
        noPagaron.add(c);
      }
    }

    final saludo =
        (config['saludo']?.toString() ??
                'BUENOS DÍAS COMPAÑEROS DEL GRUPO CONTINENTAL')
            .trim();
    final pie = (config['pie']?.toString() ?? '').trim();
    final mostrarMontoDeudor = config['mostrar_monto_deudor'] == true;
    final mostrarPagados = config['mostrar_pagados'] == true;

    final sb = StringBuffer();

    if (saludo.isNotEmpty) {
      sb.writeln('*${saludo.toUpperCase()}* 🚍');
      sb.writeln();
    }

    sb.writeln(
      '📋 *INFORME ECONÓMICO DE APOYO ECONÓMICO DE FORMA $modalidad.*',
    );
    if (beneficiario != null && beneficiario.isNotEmpty) {
      sb.writeln(
        '🤝 *SE AYUDÓ AL COMPAÑERO ${beneficiario.toUpperCase()} CON EL MONTO DE:* Bs. ${_fmtMonto(totalRecaudado)} (Aporte de Bs. ${_fmtMonto(montoSugerido)} c/u)',
      );
    } else {
      sb.writeln('📌 *CUOTA:* $nombreCuota');
      sb.writeln(
        '🤝 *SE RECAUDÓ EL MONTO DE:* Bs. ${_fmtMonto(totalRecaudado)} (Aporte de Bs. ${_fmtMonto(montoSugerido)} c/u)',
      );
    }

    sb.writeln();

    if (noPagaron.isEmpty) {
      sb.writeln(
        '✅ *¡TODOS LOS COMPAÑEROS CUMPLIERON CON EL PAGO ACORDADO DE Bs. ${_fmtMonto(montoSugerido)}!*',
      );
    } else {
      sb.writeln(
        '⚠️ *LOS COMPAÑEROS QUE NO PAGARON EL MONTO $modalidad ACORDADO (Bs. ${_fmtMonto(montoSugerido)}):*',
      );
      for (final c in noPagaron) {
        final nombre = c['conductor_nombre']?.toString() ?? 'Conductor';
        final falta = (c['monto_falta'] as num?)?.toDouble() ?? montoSugerido;
        if (mostrarMontoDeudor) {
          sb.writeln('- $nombre (Debe Bs. ${_fmtMonto(falta)})');
        } else {
          sb.writeln('- $nombre');
        }
      }
    }

    if (mostrarPagados && siPagaron.isNotEmpty) {
      sb.writeln();
      sb.writeln(
        '✅ *COMPAÑEROS QUE YA CUMPLIERON CON SU APORTE (${siPagaron.length}):*',
      );
      for (final c in siPagaron) {
        final nombre = c['conductor_nombre']?.toString() ?? 'Conductor';
        sb.writeln('- $nombre');
      }
    }

    sb.writeln();
    sb.writeln(
      '📊 *Resumen:* ${siPagaron.length} pagaron | ${noPagaron.length} pendientes (Total: ${conductores.length} compañeros)',
    );

    if (pie.isNotEmpty) {
      sb.writeln();
      sb.writeln('_${pie}_');
    }

    return sb.toString().trim();
  }

  /// Abre WhatsApp directamente con el texto pre-cargado listo para presionar Enviar.
  static Future<void> lanzarWhatsappDirecto(
    BuildContext context, {
    required String texto,
    String? telefono,
  }) async {
    await Clipboard.setData(ClipboardData(text: texto));

    final telLimpio = (telefono ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final telConCodigo = telLimpio.isNotEmpty
        ? (telLimpio.startsWith('591') ? telLimpio : '591$telLimpio')
        : '';

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('enviarWhatsApp', {
          'texto': texto,
          'telefono': telConCodigo,
        });
        return;
      } catch (_) {
        await SharePlus.instance.share(ShareParams(text: texto));
        return;
      }
    } else if (Platform.isWindows) {
      final encoded = Uri.encodeComponent(texto);
      final url = telConCodigo.isNotEmpty
          ? 'whatsapp://send?phone=$telConCodigo&text=$encoded'
          : 'whatsapp://send?text=$encoded';
      try {
        await Process.run('cmd', ['/c', 'start', '', url]);
        return;
      } catch (_) {
        await SharePlus.instance.share(ShareParams(text: texto));
        return;
      }
    } else {
      await SharePlus.instance.share(ShareParams(text: texto));
    }
  }

  /// Punto de entrada principal al presionar "WhatsApp".
  static Future<void> abrirInforme(
    BuildContext context, {
    required Map<String, dynamic> cuota,
    required List<Map<String, dynamic>> conductores,
    bool forzarVistaPrevia = false,
  }) async {
    final config = await cargarConfiguracion();
    final idTipoCuota = cuota['id_tipo_cuota']?.toString() ?? '';

    List<Map<String, dynamic>> matrizCronograma = [];
    if (idTipoCuota.isNotEmpty) {
      try {
        matrizCronograma = await EconomiaRepo.instance
            .obtenerMatrizCronogramaPorCuota(idTipoCuota);
      } catch (_) {
        matrizCronograma = [];
      }
    }

    final fechasSet = <String>{};
    for (final r in matrizCronograma) {
      final f = r['fecha_programada']?.toString().trim() ?? '';
      if (f.isNotEmpty) fechasSet.add(f);
    }
    final fechasOrdenadas = fechasSet.toList()..sort();
    final fechaSemanaInicial = determinarFechaSemanaActual(fechasOrdenadas);

    final mensaje = construirMensaje(
      cuota: cuota,
      conductores: conductores,
      config: config,
      matrizCronograma: matrizCronograma,
      fechaSemanaSeleccionada: fechaSemanaInicial,
    );

    if (!context.mounted) return;

    if (config['envio_directo'] == true && !forzarVistaPrevia) {
      await lanzarWhatsappDirecto(
        context,
        texto: mensaje,
        telefono: config['telefono']?.toString(),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _ModalVistaPreviaWhatsapp(
        cuota: cuota,
        conductores: conductores,
        configInicial: config,
        mensajeInicial: mensaje,
        matrizCronograma: matrizCronograma,
        fechasOrdenadas: fechasOrdenadas,
        fechaSemanaInicial: fechaSemanaInicial,
      ),
    );
  }

  /// Abre directamente el modal de configuración del mensaje/bot de WhatsApp.
  static Future<void> mostrarConfiguracion(
    BuildContext context, {
    Map<String, dynamic>? cuota,
    List<Map<String, dynamic>>? conductores,
  }) async {
    final config = await cargarConfiguracion();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _ModalConfiguracionWhatsapp(
        configInicial: config,
        onGuardado: () {
          if (cuota != null && conductores != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Configuración de Informe WhatsApp guardada correctamente.',
                ),
                backgroundColor: Color(0xFF059669),
              ),
            );
          }
        },
      ),
    );
  }
}

class _ModalVistaPreviaWhatsapp extends StatefulWidget {
  final Map<String, dynamic> cuota;
  final List<Map<String, dynamic>> conductores;
  final Map<String, dynamic> configInicial;
  final String mensajeInicial;
  final List<Map<String, dynamic>> matrizCronograma;
  final List<String> fechasOrdenadas;
  final String fechaSemanaInicial;

  const _ModalVistaPreviaWhatsapp({
    required this.cuota,
    required this.conductores,
    required this.configInicial,
    required this.mensajeInicial,
    required this.matrizCronograma,
    required this.fechasOrdenadas,
    required this.fechaSemanaInicial,
  });

  @override
  State<_ModalVistaPreviaWhatsapp> createState() =>
      _ModalVistaPreviaWhatsappState();
}

class _ModalVistaPreviaWhatsappState extends State<_ModalVistaPreviaWhatsapp> {
  late TextEditingController _msgCtrl;
  late Map<String, dynamic> _config;
  late String _fechaSemanaSeleccionada;

  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.configInicial);
    _fechaSemanaSeleccionada = widget.fechaSemanaInicial;
    _msgCtrl = TextEditingController(text: widget.mensajeInicial);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _regenerarMensaje() {
    setState(() {
      _msgCtrl.text = DialogoInformeWhatsapp.construirMensaje(
        cuota: widget.cuota,
        conductores: widget.conductores,
        config: _config,
        matrizCronograma: widget.matrizCronograma,
        fechaSemanaSeleccionada: _fechaSemanaSeleccionada,
      );
    });
  }

  Future<void> _abrirConfig() async {
    await showDialog(
      context: context,
      builder: (ctx) => _ModalConfiguracionWhatsapp(
        configInicial: _config,
        onGuardado: () async {
          final nuevaConfig =
              await DialogoInformeWhatsapp.cargarConfiguracion();
          if (mounted) {
            _config = nuevaConfig;
            _regenerarMensaje();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telefono = _config['telefono']?.toString().trim() ?? '';
    final nombreGrupo =
        _config['nombre_grupo']?.toString().trim() ?? 'Grupo Continental';
    final categoria =
        widget.cuota['categoria']?.toString().toLowerCase() ?? 'ayuda';
    final esCanaston =
        (categoria == 'canaston' || widget.fechasOrdenadas.length > 1) &&
        widget.fechasOrdenadas.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260F2B5B),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        color: Color(0xFF15803D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            esCanaston
                                ? 'Informe Semanal WhatsApp'
                                : 'Informe para WhatsApp',
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2B5B),
                            ),
                          ),
                          Text(
                            telefono.isNotEmpty
                                ? 'Destino directo: +591 $telefono'
                                : 'Destino: $nombreGrupo (WhatsApp)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _abrirConfig,
                      tooltip: 'Configurar plantilla y envío',
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Selector de Semana/Fecha de corte (EXCLUSIVO PARA CANASTÓN)
                if (esCanaston) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Semana a evaluar\n(sin fechas futuras):',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                              height: 1.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: widget.fechasOrdenadas.contains(
                                    _fechaSemanaSeleccionada,
                                  )
                                  ? _fechaSemanaSeleccionada
                                  : widget.fechasOrdenadas.first,
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2B5B),
                              ),
                              items: widget.fechasOrdenadas.map((f) {
                                return DropdownMenuItem<String>(
                                  value: f,
                                  child: Text(
                                    DialogoInformeWhatsapp._formatearDiaMesTexto(
                                      f,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (nuevaFecha) {
                                if (nuevaFecha != null) {
                                  _fechaSemanaSeleccionada = nuevaFecha;
                                  _regenerarMensaje();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Color(0xFF15803D),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mensaje generado automáticamente. Al pulsar Enviar se abrirá WhatsApp con este texto ya escrito.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Caja de texto estilo burbuja de WhatsApp (editable)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF86EFAC),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 13,
                    minLines: 9,
                    style: const TextStyle(
                      fontSize: 12.8,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Botones de acción
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _abrirConfig,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text(
                        'Configurar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final texto = _msgCtrl.text.trim();
                          Navigator.pop(context);
                          await DialogoInformeWhatsapp.lanzarWhatsappDirecto(
                            context,
                            texto: texto,
                            telefono: _config['telefono']?.toString(),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Enviar a WhatsApp',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalConfiguracionWhatsapp extends StatefulWidget {
  final Map<String, dynamic> configInicial;
  final VoidCallback onGuardado;

  const _ModalConfiguracionWhatsapp({
    required this.configInicial,
    required this.onGuardado,
  });

  @override
  State<_ModalConfiguracionWhatsapp> createState() =>
      _ModalConfiguracionWhatsappState();
}

class _ModalConfiguracionWhatsappState
    extends State<_ModalConfiguracionWhatsapp> {
  late TextEditingController _saludoCtrl;
  late TextEditingController _pieCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _grupoCtrl;
  late bool _mostrarMontoDeudor;
  late bool _mostrarPagados;
  late bool _envioDirecto;

  @override
  void initState() {
    super.initState();
    _saludoCtrl = TextEditingController(
      text: widget.configInicial['saludo']?.toString() ?? '',
    );
    _pieCtrl = TextEditingController(
      text: widget.configInicial['pie']?.toString() ?? '',
    );
    _telefonoCtrl = TextEditingController(
      text: widget.configInicial['telefono']?.toString() ?? '',
    );
    _grupoCtrl = TextEditingController(
      text:
          widget.configInicial['nombre_grupo']?.toString() ??
          'Grupo Continental',
    );
    _mostrarMontoDeudor =
        widget.configInicial['mostrar_monto_deudor'] == true;
    _mostrarPagados = widget.configInicial['mostrar_pagados'] == true;
    _envioDirecto = widget.configInicial['envio_directo'] == true;
  }

  @override
  void dispose() {
    _saludoCtrl.dispose();
    _pieCtrl.dispose();
    _telefonoCtrl.dispose();
    _grupoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    await DialogoInformeWhatsapp.guardarConfiguracion(
      saludo: _saludoCtrl.text,
      pie: _pieCtrl.text,
      telefono: _telefonoCtrl.text,
      nombreGrupo: _grupoCtrl.text,
      mostrarMontoDeudor: _mostrarMontoDeudor,
      mostrarPagados: _mostrarPagados,
      envioDirecto: _envioDirecto,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onGuardado();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260F2B5B),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF15803D),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Configurar Mensaje WhatsApp',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F2B5B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Switch de Envío Automático Directo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: const Color(0xFF16A34A),
                    title: const Text(
                      'Abrir WhatsApp directo (1 clic)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2B5B),
                      ),
                    ),
                    subtitle: const Text(
                      'Al pulsar el botón de WhatsApp se abrirá directo la app con el mensaje escrito sin pasar por la vista previa.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    ),
                    value: _envioDirecto,
                    onChanged: (v) => setState(() => _envioDirecto = v),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Nombre del Grupo (Referencia)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2B5B),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _grupoCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej. Grupo Continental Trufi',
                    prefixIcon: const Icon(Icons.groups_rounded, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'Número de WhatsApp directo (Opcional)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2B5B),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Déjalo vacío para elegir el Grupo Continental al abrirse WhatsApp, o escribe un celular para abrir ese chat directo.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Ej. 71234567 (Opcional)',
                    prefixText: '+591 ',
                    prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'Saludo Inicial del Informe',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2B5B),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _saludoCtrl,
                  decoration: InputDecoration(
                    hintText: 'BUENOS DÍAS COMPAÑEROS DEL GRUPO CONTINENTAL',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'Nota Final / Pie del Mensaje',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2B5B),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _pieCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Se solicita regularizar su cuota...',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF16A34A),
                  title: const Text(
                    'Mostrar monto adeudado en Apoyo Económico',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                  ),
                  value: _mostrarMontoDeudor,
                  onChanged: (v) =>
                      setState(() => _mostrarMontoDeudor = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF16A34A),
                  title: const Text(
                    'Incluir lista de los que sí pagaron en Apoyo Económico',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                  ),
                  value: _mostrarPagados,
                  onChanged: (v) =>
                      setState(() => _mostrarPagados = v ?? false),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2B5B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _guardar,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text(
                      'Guardar Configuración',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
