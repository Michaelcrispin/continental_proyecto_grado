import 'dart:math' as math;

/// Resultado del análisis de la llegada de un conductor.
class ResultadoEvaluacionAsistencia {
  final String estado; // 'presente' | 'tardanza'
  final int minutosRetraso;
  final int vueltasSancion;
  final String? motivoSancion;
  final bool generaSancion;

  const ResultadoEvaluacionAsistencia({
    required this.estado,
    required this.minutosRetraso,
    required this.vueltasSancion,
    this.motivoSancion,
    required this.generaSancion,
  });

  bool get esPresente => estado == 'presente';
  bool get esTardanza => estado == 'tardanza';
}

/// Confirmación por lecturas consecutivas e histéresis para evitar que una sola lectura
/// con rebote de señal cambie falsamente el estado de "Dentro" a "Fuera".
class EstadoGeocerca {
  bool dentro = false;
  int _seguidas = 0;

  int get lecturasSeguidas => _seguidas;

  /// Devuelve el estado confirmado tras exigir 3 lecturas consecutivas.
  /// Incluye margen de precisión (accuracy hasta 40 m) e histéresis (radio * 1.3 para salir).
  bool actualizar({
    required double distancia,
    required double accuracy,
    required double radio,
  }) {
    final margen = accuracy.clamp(0.0, 40.0);
    final limite = dentro ? radio * 1.3 : radio; // histéresis
    final lecturaDentro = (distancia - margen) <= limite;

    if (lecturaDentro != dentro) {
      _seguidas++;
      if (_seguidas >= 3) {
        dentro = lecturaDentro;
        _seguidas = 0;
      }
    } else {
      _seguidas = 0;
    }
    return dentro;
  }

  /// Fuerza inmediatamente el estado al capturar o cambiar manualmente de punto.
  void forzarEstado({
    required double distancia,
    required double accuracy,
    required double radio,
  }) {
    final margen = accuracy.clamp(0.0, 40.0);
    dentro = (distancia - margen) <= radio;
    _seguidas = 0;
  }
}

/// Reglas de negocio del Sindicato Continental:
/// - Control de asistencia en Cruce Villadela y Teleférico Amarillo.
/// - Horario matutino unificado: entrada 07:30 AM con tolerancia de 30 min (límite 08:00 AM).
/// - Si llega hasta las 08:00 -> 'presente' (0 vueltas de sanción).
/// - Si llega después de las 08:00 -> 'tardanza' + 2 vueltas de castigo.
class ReglasAsistencia {
  const ReglasAsistencia._();

  /// Convierte una cadena "HH:mm" a minutos transcurridos desde las 00:00.
  static int minutosDesdeMedianoche(String hora) {
    final limpia = hora.replaceAll('AM', '').replaceAll('PM', '').trim();
    final partes = limpia.split(':');
    if (partes.length < 2) return 0;
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    return (h * 60) + m;
  }

  /// Formatea minutos desde medianoche a "HH:mm".
  static String minutosAHora(int minutos) {
    final h = (minutos ~/ 60) % 24;
    final m = minutos % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Evalúa si la llegada califica como `presente` o `tardanza`.
  ///
  /// [horaLlegada]: formato "HH:mm" (ej. "07:45" o "08:12").
  /// [horaEntrada]: formato "HH:mm" (por defecto "07:30").
  /// [toleranciaMin]: minutos de gracia desde horaEntrada (unificado a 30 min -> 08:00).
  /// [vueltasPorTardanza]: cantidad de vueltas de castigo impuestas (por defecto 2).
  static ResultadoEvaluacionAsistencia evaluarLlegada({
    required String horaLlegada,
    String horaEntrada = '07:30',
    int toleranciaMin = 30,
    int vueltasPorTardanza = 2,
  }) {
    final minLlegada = minutosDesdeMedianoche(horaLlegada);
    final minEntrada = minutosDesdeMedianoche(horaEntrada);
    final minLimitePresente = minEntrada + toleranciaMin;

    if (minLlegada <= minLimitePresente) {
      return const ResultadoEvaluacionAsistencia(
        estado: 'presente',
        minutosRetraso: 0,
        vueltasSancion: 0,
        motivoSancion: null,
        generaSancion: false,
      );
    } else {
      final retraso = minLlegada - minLimitePresente;
      final horaLimiteStr = minutosAHora(minLimitePresente);
      return ResultadoEvaluacionAsistencia(
        estado: 'tardanza',
        minutosRetraso: retraso,
        vueltasSancion: vueltasPorTardanza,
        motivoSancion:
            'Tardanza (llegó $horaLlegada, límite $horaLimiteStr, $retraso min de retraso)',
        generaSancion: vueltasPorTardanza > 0,
      );
    }
  }

  /// Determina si una hora dada corresponde al horario nocturno de castigo.
  static bool esHoraCastigo({
    required String horaActual,
    String horaInicioCastigo = '21:00',
  }) {
    final actual = minutosDesdeMedianoche(horaActual);
    final inicio = minutosDesdeMedianoche(horaInicioCastigo);
    return actual >= inicio;
  }

  /// Calcula la distancia en metros entre dos coordenadas geográficas usando la fórmula Haversine.
  static double calcularDistanciaMetros({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const radioTierra = 6371000.0; // Radio medio de la Tierra en metros
    final dLat = _gradosARadianes(lat2 - lat1);
    final dLon = _gradosARadianes(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_gradosARadianes(lat1)) *
            math.cos(_gradosARadianes(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radioTierra * c;
  }

  /// Verifica si una ubicación está dentro del radio de geocerca del punto de control
  /// considerando opcionalmente el margen de precisión (accuracy).
  static bool estaDentroDeGeocerca({
    required double latUsuario,
    required double lonUsuario,
    required double latPunto,
    required double lonPunto,
    required double radioMetros,
    double accuracyMetros = 0.0,
  }) {
    final distancia = calcularDistanciaMetros(
      lat1: latUsuario,
      lon1: lonUsuario,
      lat2: latPunto,
      lon2: lonPunto,
    );
    final margen = accuracyMetros.clamp(0.0, 40.0);
    return (distancia - margen) <= radioMetros;
  }

  static double _gradosARadianes(double grados) => grados * (math.pi / 180.0);
}
