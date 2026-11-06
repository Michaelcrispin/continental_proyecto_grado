// lib/widgets/vuelta_castigo_sheet.dart
//
// Hoja inferior de auditoría de VUELTAS DE CASTIGO (sanción por tardanza):
//  - La tardanza se registra en Asistencia (> 08:00 AM) y genera automáticamente 2 vueltas.
//  - Las vueltas de castigo se cumplen de noche, desde las 21:00 (hora configurable).
//  - Muestra sobre el mapa la ruta oficial (Villadela → Teleférico → Villadela) y el
//    recorrido GPS de la vuelta elegida: cumplida (trazo completo), en curso (trazo parcial
//    con el móvil) o pendiente (solo ruta, sin recorrido).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/ruta_continental.dart';
import '../screens/gps/gps_en_vivo_screen.dart';
import '../screens/gps/ruta_oficial_screen.dart';
import 'avatar_conductor.dart';

const _kVerde = Color(0xFF02634C);
const _kVerdeClaro = Color(0xFFE6F4F0);
const _kAzul = Color(0xFF1D4ED8);
const _kAzulClaro = Color(0xFFEFF6FF);
const _kAmbar = Color(0xFFD97706);
const _kAmbarClaro = Color(0xFFFEF3C7);
const _kRojo = Color(0xFFDC2626);
const _kRojoClaro = Color(0xFFFEE2E2);
const _kTexto = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);

/// Minutos que tarda una vuelta completa de 14.69 km a velocidad urbana promedio.
const int _kDuracionVueltaMin = 35;

enum _EstadoVuelta { cumplida, enCurso, pendiente }

class _VueltaInfo {
  final int numero;
  final _EstadoVuelta estado;
  final int? salida;
  final int? pasoB;
  final int? llegada;
  final bool estimada;
  final bool fueraHorario;
  final double progreso;

  const _VueltaInfo({
    required this.numero,
    required this.estado,
    this.salida,
    this.pasoB,
    this.llegada,
    this.estimada = false,
    this.fueraHorario = false,
    this.progreso = 0,
  });
}

class VueltaCastigoSheet extends StatefulWidget {
  /// Mapa con: id_conductor, conductor, unidad, placa, foto, vueltas_hechas, vueltas_meta,
  /// fecha_sancion, hora_llegada, minutos_retraso, hora_inicio_castigo, horas_cierre (List).
  final Map<String, dynamic> datos;

  const VueltaCastigoSheet({super.key, required this.datos});

  static Future<void> mostrar(
    BuildContext context,
    Map<String, dynamic> datos,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VueltaCastigoSheet(datos: datos),
    );
  }

  @override
  State<VueltaCastigoSheet> createState() => _VueltaCastigoSheetState();
}

class _VueltaCastigoSheetState extends State<VueltaCastigoSheet> {
  late final List<_VueltaInfo> _vueltas;
  late int _seleccion;
  bool _satelite = false;

  int get _hechas => widget.datos['vueltas_hechas'] as int;
  int get _meta => widget.datos['vueltas_meta'] as int;
  String get _horaInicio =>
      widget.datos['hora_inicio_castigo']?.toString() ?? '21:00';

  @override
  void initState() {
    super.initState();
    _vueltas = _calcularVueltas();
    final idxEnCurso = _vueltas.indexWhere(
      (v) => v.estado == _EstadoVuelta.enCurso,
    );
    if (idxEnCurso >= 0) {
      _seleccion = idxEnCurso;
    } else if (_hechas >= _meta) {
      _seleccion = _meta - 1;
    } else {
      _seleccion = _hechas.clamp(0, _meta - 1);
    }
  }

  // ---------------------------------------------------------------------------
  // Cálculo de vueltas
  // ---------------------------------------------------------------------------
  static int? _parseMin(String? s) {
    if (s == null) return null;
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?').firstMatch(s);
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final mi = int.parse(m.group(2)!);
    final ap = m.group(3)?.toUpperCase();
    if (ap == 'PM' && h < 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return h * 60 + mi;
  }

  static String _fmt(int m) {
    final x = ((m % 1440) + 1440) % 1440;
    return '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';
  }

  /// Válido: desde las 21:00 hasta el amanecer (06:00).
  static bool _enHorarioCastigo(int minutos, int inicio) {
    final m = ((minutos % 1440) + 1440) % 1440;
    return m >= inicio || m < 6 * 60;
  }

  List<_VueltaInfo> _calcularVueltas() {
    final inicio = _parseMin(_horaInicio) ?? 21 * 60;
    final cierres = ((widget.datos['horas_cierre'] as List?) ?? const [])
        .map((e) => _parseMin(e?.toString()))
        .whereType<int>()
        .toList();

    final ahora = DateTime.now();
    final ahoraMin = ahora.hour * 60 + ahora.minute;
    final lista = <_VueltaInfo>[];
    var cursor = inicio;

    for (int i = 1; i <= _meta; i++) {
      if (i <= _hechas) {
        final registrada = cierres.length >= i;
        final llegada = registrada
            ? cierres[i - 1]
            : cursor + _kDuracionVueltaMin;
        final salida = llegada - _kDuracionVueltaMin;
        lista.add(
          _VueltaInfo(
            numero: i,
            estado: _EstadoVuelta.cumplida,
            salida: salida,
            pasoB: salida + 17,
            llegada: llegada,
            estimada: true,
            fueraHorario: registrada && !_enHorarioCastigo(llegada, inicio),
            progreso: 1,
          ),
        );
        cursor = llegada + 5;
      } else if (i == _hechas + 1 && _hechas > 0) {
        var transcurrido = ahoraMin - cursor;
        if (transcurrido < 0) transcurrido += 1440;
        final frac = transcurrido > 240
            ? 0.45
            : transcurrido / _kDuracionVueltaMin;
        lista.add(
          _VueltaInfo(
            numero: i,
            estado: _EstadoVuelta.enCurso,
            salida: cursor,
            pasoB: cursor + 17,
            estimada: true,
            progreso: frac.clamp(0.12, 0.92),
          ),
        );
      } else {
        lista.add(_VueltaInfo(numero: i, estado: _EstadoVuelta.pendiente));
      }
    }
    return lista;
  }

  // ---------------------------------------------------------------------------
  // Colores / textos por estado
  // ---------------------------------------------------------------------------
  Color _color(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => _kVerde,
    _EstadoVuelta.enCurso => _kAzul,
    _EstadoVuelta.pendiente => _kRojo,
  };

  Color _fondo(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => _kVerdeClaro,
    _EstadoVuelta.enCurso => _kAzulClaro,
    _EstadoVuelta.pendiente => _kRojoClaro,
  };

  String _texto(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => 'Cumplida',
    _EstadoVuelta.enCurso => 'En curso',
    _EstadoVuelta.pendiente => 'Pendiente',
  };

  IconData _icono(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => Icons.check_circle_rounded,
    _EstadoVuelta.enCurso => Icons.directions_car_filled_rounded,
    _EstadoVuelta.pendiente => Icons.schedule_rounded,
  };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final v = widget.datos;
    final nombre = v['conductor']?.toString() ?? 'Conductor';
    final total = _hechas >= _meta
        ? _EstadoVuelta.cumplida
        : (_hechas > 0 ? _EstadoVuelta.enCurso : _EstadoVuelta.pendiente);
    final sel = _vueltas[_seleccion];
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                AvatarConductor(
                  foto: v['foto'] as String?,
                  nombre: nombre,
                  radio: 24,
                  fontSize: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kTexto,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Móvil #${v['unidad']} • Placa: ${v['placa']}',
                        style: const TextStyle(color: _kMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _fondo(total),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_hechas/$_meta vueltas',
                        style: TextStyle(
                          color: _color(total),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _texto(total),
                        style: TextStyle(
                          color: _color(total),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tarjetaSancion(),
                  const SizedBox(height: 16),
                  const Text(
                    'Recorrido GPS de la vuelta',
                    style: TextStyle(
                      color: _kTexto,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _selectorVueltas(),
                  const SizedBox(height: 10),
                  _mapa(sel),
                  const SizedBox(height: 8),
                  _leyenda(sel),
                  const SizedBox(height: 12),
                  _estadisticas(sel),
                  const SizedBox(height: 12),
                  _lineaTiempo(sel),
                  const SizedBox(height: 8),
                  const Text(
                    'Las horas de paso por Parada B se calculan a partir del cierre registrado. '
                    'El recorrido es de demostración hasta que los celulares de los choferes '
                    'sincronicen su GPS.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              bottom > 0 ? bottom + 8 : 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) =>
                            GpsEnVivoScreen(conductorMonitoreado: widget.datos),
                      ),
                    );
                  },
                  icon: const Icon(Icons.satellite_alt_rounded, size: 20),
                  label: const Text(
                    'Ver ubicación en GPS en vivo',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kVerde,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => const RutaOficialScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.map_outlined,
                    color: _kVerde,
                    size: 20,
                  ),
                  label: const Text(
                    'Ver circuito oficial (14.69 km)',
                    style: TextStyle(
                      color: _kVerde,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: _kVerde, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de contexto de la sanción
  // ---------------------------------------------------------------------------
  Widget _tarjetaSancion() {
    final v = widget.datos;
    final fecha = v['fecha_sancion']?.toString() ?? '';
    final partes = fecha.split('-');
    final fechaTxt = partes.length == 3
        ? '${partes[2]}/${partes[1]}/${partes[0]}'
        : fecha;
    final llegada = v['hora_llegada']?.toString();
    final retraso = (v['minutos_retraso'] as num?)?.toInt() ?? 0;
    final progreso = _meta == 0 ? 0.0 : (_hechas / _meta).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kAmbarClaro,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: _kAmbar,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sanción por tardanza',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Text(
                fechaTxt,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            llegada != null && llegada.isNotEmpty
                ? 'Marcó asistencia a las $llegada${retraso > 0 ? ' (+$retraso min de retraso)' : ''}. '
                      'Debe cumplir $_meta vueltas de castigo desde las $_horaInicio.'
                : 'Debe cumplir $_meta vueltas de castigo desde las $_horaInicio.',
            style: const TextStyle(
              color: Color(0xFF78350F),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 7,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(_kVerde),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selector de vuelta
  // ---------------------------------------------------------------------------
  Widget _selectorVueltas() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < _vueltas.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _chipVuelta(i),
          ],
        ],
      ),
    );
  }

  Widget _chipVuelta(int i) {
    final info = _vueltas[i];
    final activo = _seleccion == i;
    final color = _color(info.estado);
    return GestureDetector(
      onTap: () => setState(() => _seleccion = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? color : const Color(0xFFE2E8F0),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icono(info.estado),
              size: 15,
              color: activo ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              'Vuelta ${info.numero}',
              style: TextStyle(
                color: activo ? Colors.white : _kTexto,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _texto(info.estado),
              style: TextStyle(
                color: activo ? Colors.white.withValues(alpha: 0.9) : color,
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mapa con ruta oficial + recorrido GPS de la vuelta
  // ---------------------------------------------------------------------------
  Widget _mapa(_VueltaInfo vuelta) {
    final circuito = RutaContinental.circuitoCompleto;
    final n = circuito.length;
    var traza = <LatLng>[];
    if (vuelta.estado == _EstadoVuelta.cumplida) {
      traza = circuito;
    } else if (vuelta.estado == _EstadoVuelta.enCurso && n > 2) {
      final idx = (vuelta.progreso * (n - 1)).round().clamp(1, n - 1);
      traza = circuito.sublist(0, idx + 1);
    }
    final color = _color(vuelta.estado);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 270,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints([...circuito]),
                  padding: const EdgeInsets.all(34),
                ),
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _satelite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.continental',
                  maxNativeZoom: 19,
                  maxZoom: 21,
                ),
                // Ruta oficial completa (tramo todavía sin recorrer)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: circuito,
                      strokeWidth: 4,
                      color: _satelite
                          ? Colors.white70
                          : const Color(0xFF94A3B8),
                      pattern: StrokePattern.dashed(segments: const [9, 7]),
                    ),
                    if (traza.length >= 2)
                      Polyline(
                        points: traza,
                        strokeWidth: 6,
                        color: color,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                  ],
                ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: RutaContinental.rectanguloParadaA,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                      borderColor: const Color(0xFF2563EB),
                      borderStrokeWidth: 3.0,
                    ),
                    Polygon(
                      points: RutaContinental.rectanguloParadaB,
                      color: _kAmbar.withValues(alpha: 0.26),
                      borderColor: _kAmbar,
                      borderStrokeWidth: 3.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    _marcadorParada(
                      RutaContinental.paradaAVilladela,
                      'A',
                      _kVerde,
                    ),
                    _marcadorParada(
                      RutaContinental.paradaBTeleferico,
                      'B',
                      _kAmbar,
                    ),
                    if (vuelta.estado == _EstadoVuelta.enCurso &&
                        traza.isNotEmpty)
                      Marker(
                        point: traza.last,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kAzul, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            color: _kAzul,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Estado de la vuelta sobre el mapa
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icono(vuelta.estado), size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      'Vuelta ${vuelta.numero} • ${_texto(vuelta.estado)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Cambio de capa mapa / satélite
            Positioned(
              right: 10,
              top: 10,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _satelite = !_satelite),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(
                      _satelite
                          ? Icons.map_outlined
                          : Icons.satellite_alt_rounded,
                      size: 18,
                      color: _kVerde,
                    ),
                  ),
                ),
              ),
            ),
            if (vuelta.estado == _EstadoVuelta.pendiente)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sin recorrido GPS. Debe iniciar en Parada A (Cruce Villadela) desde las $_horaInicio.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kRojo,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _marcadorParada(LatLng punto, String etiqueta, Color color) {
    return Marker(
      point: punto,
      width: 34,
      height: 34,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          etiqueta,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _leyenda(_VueltaInfo vuelta) {
    final color = _color(vuelta.estado);
    return Row(
      children: [
        Container(
          width: 22,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Recorrido GPS',
          style: TextStyle(
            color: _kMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 14),
        Row(
          children: List.generate(
            3,
            (_) => Container(
              width: 6,
              height: 3,
              margin: const EdgeInsets.only(right: 3),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 3),
        const Text(
          'Ruta oficial sin recorrer',
          style: TextStyle(
            color: _kMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Estadísticas
  // ---------------------------------------------------------------------------
  Widget _estadisticas(_VueltaInfo vuelta) {
    final km = RutaContinental.distanciaCircuitoKm * vuelta.progreso;
    final dur = switch (vuelta.estado) {
      _EstadoVuelta.cumplida => '$_kDuracionVueltaMin min',
      _EstadoVuelta.enCurso =>
        '${(vuelta.progreso * _kDuracionVueltaMin).round()} min',
      _EstadoVuelta.pendiente => '--',
    };
    final geocercas = switch (vuelta.estado) {
      _EstadoVuelta.cumplida => '3 / 3',
      _EstadoVuelta.enCurso => vuelta.progreso >= 0.49 ? '2 / 3' : '1 / 3',
      _EstadoVuelta.pendiente => '0 / 3',
    };
    return Row(
      children: [
        _stat('Distancia GPS', '${km.toStringAsFixed(1)} km', 'de 14.69 km'),
        const SizedBox(width: 8),
        _stat('Duración', dur, 'vuelta ${vuelta.numero}'),
        const SizedBox(width: 8),
        _stat('Geocercas', geocercas, 'A · B · A'),
      ],
    );
  }

  Widget _stat(String label, String valor, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: const TextStyle(
                color: _kVerde,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Línea de tiempo de la vuelta elegida
  // ---------------------------------------------------------------------------
  Widget _lineaTiempo(_VueltaInfo vuelta) {
    final color = _color(vuelta.estado);
    final pasoBHecho =
        vuelta.estado == _EstadoVuelta.cumplida ||
        (vuelta.estado == _EstadoVuelta.enCurso && vuelta.progreso >= 0.49);

    final pasos = <Widget>[];
    switch (vuelta.estado) {
      case _EstadoVuelta.cumplida:
        pasos.addAll([
          _paso(
            'Salida Parada A (Cruce Villadela)',
            'Entró y salió de la geocerca',
            _fmt(vuelta.salida!),
            true,
            _kVerde,
          ),
          _paso(
            'Retorno en Parada B (Teleférico)',
            'Geocerca de retorno cruzada',
            _fmt(vuelta.pasoB!),
            true,
            _kAzul,
          ),
          _paso(
            'Llegada Parada A • cierre de vuelta',
            'Circuito de 14.69 km completado',
            _fmt(vuelta.llegada!),
            true,
            _kVerde,
            ultimo: true,
          ),
        ]);
      case _EstadoVuelta.enCurso:
        pasos.addAll([
          _paso(
            'Salida Parada A (Cruce Villadela)',
            'Geocerca cruzada',
            _fmt(vuelta.salida!),
            true,
            _kVerde,
          ),
          _paso(
            pasoBHecho
                ? 'Retorno en Parada B (Teleférico)'
                : 'En trayecto hacia Teleférico',
            pasoBHecho ? 'Geocerca de retorno cruzada' : 'Telemetría activa',
            pasoBHecho ? _fmt(vuelta.pasoB!) : 'En curso',
            pasoBHecho,
            _kAzul,
          ),
          _paso(
            pasoBHecho
                ? 'En trayecto de regreso a Villadela'
                : 'Llegada Parada A',
            'Falta cruzar la geocerca de cierre',
            '--:--',
            false,
            const Color(0xFF94A3B8),
            ultimo: true,
          ),
        ]);
      case _EstadoVuelta.pendiente:
        pasos.add(
          _paso(
            'Aún no inició esta vuelta',
            'Sin cruce de geocerca en Parada A',
            'Desde $_horaInicio',
            false,
            _kRojo,
            ultimo: true,
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vuelta ${vuelta.numero} • ${_texto(vuelta.estado)}',
                style: const TextStyle(
                  color: _kTexto,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (vuelta.fueraHorario)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kAmbarClaro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Fuera del horario de castigo',
                    style: TextStyle(
                      color: _kAmbar,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...pasos,
        ],
      ),
    );
  }

  Widget _paso(
    String titulo,
    String subtitulo,
    String hora,
    bool hecho,
    Color color, {
    bool ultimo = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Icon(
                  hecho
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: color,
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: const TextStyle(color: _kMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    hora,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
