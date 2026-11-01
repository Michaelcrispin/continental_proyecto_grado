import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/reglas_asistencia.dart';
import '../../../services/asistencia_repo.dart';
import '../../../services/database_helper.dart';
import '../../../services/gps_service.dart';
import '../../../services/sesion_service.dart';
import 'mapa_conductor_vivo.dart';

/// Tarjeta interactiva con mapa en vivo para que el conductor visualice en tiempo real
/// las Paradas A y B, consulte su distancia exacta y marque su asistencia por GPS.
class MarcarLlegadaCard extends StatefulWidget {
  final VoidCallback onAsistenciaRegistrada;

  const MarcarLlegadaCard({
    super.key,
    required this.onAsistenciaRegistrada,
  });

  @override
  State<MarcarLlegadaCard> createState() => _MarcarLlegadaCardState();
}

class _MarcarLlegadaCardState extends State<MarcarLlegadaCard> {
  bool _cargando = true;
  bool _registrando = false;
  Map<String, dynamic>? _asistenciaHoy;
  Map<String, dynamic>? _puntoAsistencia;
  List<Map<String, dynamic>> _puntos = [];
  Position? _posicionActual;
  double? _distanciaMetros;
  bool _dentroDeGeocerca = false;
  String? _errorMensaje;
  StreamSubscription<Position>? _subPosicion;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _subPosicion?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    setState(() => _cargando = true);
    final idConductor = SesionService.instance.idConductor;
    if (idConductor == null) {
      setState(() => _cargando = false);
      return;
    }

    _asistenciaHoy = await AsistenciaRepo.instance.obtenerAsistenciaHoy(idConductor);
    _puntos = await DatabaseHelper.instance.obtenerPuntosControl(soloActivos: false);
    _puntoAsistencia = await DatabaseHelper.instance.obtenerPuntoAsistencia();

    if (_puntoAsistencia != null) {
      await _actualizarUbicacion();
      _suscribirStream();
    }

    if (mounted) setState(() => _cargando = false);
  }

  void _suscribirStream() {
    _subPosicion?.cancel();
    _subPosicion = GpsService.instance.obtenerStreamPosicion(distanceFilterM: 0).listen(
      (pos) {
        if (!mounted || _puntoAsistencia == null) return;
        final latP = (_puntoAsistencia!['latitud'] as num?)?.toDouble() ?? -16.53453;
        final lonP = (_puntoAsistencia!['longitud'] as num?)?.toDouble() ?? -68.19071;
        final radioP = (_puntoAsistencia!['radio_m'] as num?)?.toDouble() ?? 100.0;

        final dist = ReglasAsistencia.calcularDistanciaMetros(
          lat1: pos.latitude,
          lon1: pos.longitude,
          lat2: latP,
          lon2: lonP,
        );

        setState(() {
          _posicionActual = pos;
          _distanciaMetros = dist;
          _dentroDeGeocerca = dist <= radioP;
          _errorMensaje = null;
        });
      },
      onError: (e) {
        if (mounted) setState(() => _errorMensaje = 'Error GPS: $e');
      },
    );
  }

  Future<void> _actualizarUbicacion() async {
    try {
      _puntos = await DatabaseHelper.instance.obtenerPuntosControl(soloActivos: false);
      _puntoAsistencia = await DatabaseHelper.instance.obtenerPuntoAsistencia();
      final errorPermiso = await GpsService.instance.asegurarPermisos();
      if (errorPermiso != null) {
        if (mounted) setState(() => _errorMensaje = errorPermiso);
        return;
      }

      final pos = await GpsService.instance.obtenerPosicionActual();
      if (pos == null || _puntoAsistencia == null) return;

      final latP = (_puntoAsistencia!['latitud'] as num?)?.toDouble() ?? -16.53453;
      final lonP = (_puntoAsistencia!['longitud'] as num?)?.toDouble() ?? -68.19071;
      final radioP = (_puntoAsistencia!['radio_m'] as num?)?.toDouble() ?? 100.0;

      final dist = ReglasAsistencia.calcularDistanciaMetros(
        lat1: pos.latitude,
        lon1: pos.longitude,
        lat2: latP,
        lon2: lonP,
      );

      if (mounted) {
        setState(() {
          _posicionActual = pos;
          _distanciaMetros = dist;
          _dentroDeGeocerca = dist <= radioP;
          _errorMensaje = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = 'No se pudo obtener GPS: $e');
    }
  }

  Future<void> _marcarLlegada() async {
    final idConductor = SesionService.instance.idConductor;
    if (idConductor == null || _puntoAsistencia == null || _posicionActual == null) return;

    setState(() => _registrando = true);
    final idPunto = _puntoAsistencia!['id_punto']?.toString() ?? '';

    final res = await AsistenciaRepo.instance.registrarAsistenciaGps(
      idConductor: idConductor,
      idPunto: idPunto,
      latitud: _posicionActual!.latitude,
      longitud: _posicionActual!.longitude,
      precisionM: _posicionActual!.accuracy,
      distanciaM: _distanciaMetros ?? 0.0,
    );

    if (!mounted) return;
    setState(() => _registrando = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              res.exito ? (res.esTardanza ? Icons.alarm : Icons.check_circle) : Icons.error_outline,
              color: res.exito ? (res.esTardanza ? const Color(0xFFF59E0B) : const Color(0xFF10B981)) : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              res.exito ? (res.esTardanza ? 'Tardanza Registrada' : 'Asistencia Confirmada') : 'Aviso',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(res.mensaje),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _iniciar();
              widget.onAsistenciaRegistrada();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    final posLatLng = _posicionActual != null
        ? LatLng(_posicionActual!.latitude, _posicionActual!.longitude)
        : null;
    final nombrePunto = _puntoAsistencia?['nombre']?.toString() ?? 'Cruce Villadela';
    final radioP = (_puntoAsistencia?['radio_m'] as num?)?.toInt() ?? 100;
    final distTexto = GpsService.formatearDistancia(_distanciaMetros);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _dentroDeGeocerca ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: _dentroDeGeocerca ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _dentroDeGeocerca ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.gps_fixed,
                  color: _dentroDeGeocerca ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Radar GPS de Paradas en Tiempo Real',
                      style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Punto oficial: $nombrePunto (Radio $radioP m)',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
                tooltip: 'Actualizar GPS',
                onPressed: _actualizarUbicacion,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // MAPA EN VIVO DEL CONDUCTOR (Parada A, Parada B y posición "TÚ")
          MapaConductorVivo(
            puntos: _puntos,
            posicionConductor: posLatLng,
            dentroDeGeocerca: _dentroDeGeocerca,
            distanciaMetros: _distanciaMetros,
          ),
          const SizedBox(height: 12),

          // Indicador de Distancia Exacta y Geocerca
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _dentroDeGeocerca ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _dentroDeGeocerca ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _dentroDeGeocerca ? Icons.check_circle : Icons.explore_off,
                  size: 19,
                  color: _dentroDeGeocerca ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _dentroDeGeocerca
                        ? 'DENTRO DE PARADA A • Distancia: $distTexto (de $radioP m)'
                        : 'FUERA DEL RADIO • Distancia actual: $distTexto (Radio $radioP m)',
                    style: TextStyle(
                      color: _dentroDeGeocerca ? const Color(0xFF166534) : const Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMensaje != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMensaje!,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ],

          const SizedBox(height: 12),

          // Si ya marcó hoy, mostrar confirmación; si no, botón de marcado GPS
          if (_asistenciaHoy != null)
            _buildBannerYaRegistrado()
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_dentroDeGeocerca && !_registrando) ? _marcarLlegada : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _registrando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.touch_app, color: Colors.white),
                label: Text(
                  _registrando ? 'Verificando y registrando...' : 'Marcar Asistencia GPS',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerYaRegistrado() {
    final estado = (_asistenciaHoy!['estado']?.toString() ?? 'presente').toLowerCase();
    final hora = _asistenciaHoy!['hora_llegada']?.toString() ?? '--:--';
    final esTardanza = estado == 'tardanza';
    final color = esTardanza ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(esTardanza ? Icons.alarm : Icons.verified, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esTardanza ? 'Llegada Registrada con Tardanza' : '¡Asistencia de Hoy Registrada!',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                Text(
                  'Hora: $hora • Estado: ${estado.toUpperCase()}',
                  style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (esTardanza)
                  const Text(
                    'Sanción: 2 vueltas adicionales en horario nocturno (21:00).',
                    style: TextStyle(color: Color(0xFFB45309), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
