/// Utilidad pura para el cálculo del cronograma de fechas de cobro
/// de cuotas periódicas (Canastón, Pasanaco o Cuotas Recurrentes).
class CronogramaCuotas {
  /// Calcula la lista de fechas de cobro entre [fechaInicio] y [fechaLimite]
  /// según la frecuencia ('semanal' o 'mensual').
  static List<DateTime> generarFechas({
    required DateTime fechaInicio,
    required DateTime fechaLimite,
    required String frecuencia, // 'semanal' | 'mensual'
    int? diaSemana, // 1 = Lunes, 2 = Martes, ..., 7 = Domingo
    int? diaMes, // 1 a 28, o null si es fin de mes
    bool esFinDeMes = false,
  }) {
    // Normalizar fechas a medianoche para evitar desfases de horas
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final limite = DateTime(fechaLimite.year, fechaLimite.month, fechaLimite.day);

    if (limite.isBefore(inicio)) {
      return [];
    }

    final fechas = <DateTime>[];

    if (frecuencia.toLowerCase() == 'semanal') {
      final diaObjetivo = diaSemana ?? 2; // Por defecto Martes (2)
      // Encontrar la primera fecha >= inicio con el día de la semana objetivo
      var cursor = inicio;
      while (cursor.weekday != diaObjetivo) {
        cursor = cursor.add(const Duration(days: 1));
      }

      while (!cursor.isAfter(limite)) {
        fechas.add(cursor);
        cursor = cursor.add(const Duration(days: 7));
        if (fechas.length >= 150) break; // Protección contra bucles infinitos
      }
    } else {
      // FRECUENCIA MENSUAL
      var anio = inicio.year;
      var mes = inicio.month;

      while (true) {
        final ultimoDiaDelMes = DateTime(anio, mes + 1, 0).day;
        int diaEfectivo;

        if (esFinDeMes) {
          diaEfectivo = ultimoDiaDelMes;
        } else {
          final diaDeseado = diaMes ?? 11;
          diaEfectivo = diaDeseado > ultimoDiaDelMes ? ultimoDiaDelMes : diaDeseado;
        }

        final fechaCuota = DateTime(anio, mes, diaEfectivo);

        if (!fechaCuota.isBefore(inicio) && !fechaCuota.isAfter(limite)) {
          fechas.add(fechaCuota);
        }

        if (DateTime(anio, mes, 1).isAfter(limite)) {
          break;
        }

        mes++;
        if (mes > 12) {
          mes = 1;
          anio++;
        }

        if (fechas.length >= 120) break; // Protección contra bucles infinitos
      }
    }

    return fechas;
  }

  /// Retorna el nombre en español del día de la semana (1 = Lunes .. 7 = Domingo).
  static String nombreDiaSemana(int dia) {
    switch (dia) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Martes';
    }
  }
}
