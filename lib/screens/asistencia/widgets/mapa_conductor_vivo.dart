import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/puntos_oficiales.dart';
import '../../../domain/ruta_continental.dart';

/// Mapa en tiempo real para el modo Conductor.
/// Muestra simultáneamente la Parada A (Cruce Villadela), la Parada B (Teleférico Amarillo),
/// sus geocercas reales y la posición GPS en vivo del conductor ("TÚ").
class MapaConductorVivo extends StatefulWidget {
  final List<Map<String, dynamic>> puntos;
  final LatLng? posicionConductor;
  final bool dentroDeGeocerca;
  final double? distanciaMetros;

  const MapaConductorVivo({
    super.key,
    required this.puntos,
    required this.posicionConductor,
    required this.dentroDeGeocerca,
    this.distanciaMetros,
  });

  @override
  State<MapaConductorVivo> createState() => _MapaConductorVivoState();
}

class _MapaConductorVivoState extends State<MapaConductorVivo> {
  final MapController _mapController = MapController();
  bool _seguirConductor = true;
  bool _mapaListo = false;

  LatLng get _coordA {
    if (widget.puntos.isNotEmpty) {
      final lat = (widget.puntos[0]['latitud'] as num?)?.toDouble();
      final lon = (widget.puntos[0]['longitud'] as num?)?.toDouble();
      if (lat != null && lon != null) return LatLng(lat, lon);
    }
    return RutaContinental.paradaAVilladela;
  }

  LatLng get _coordB {
    if (widget.puntos.length > 1) {
      final lat = (widget.puntos[1]['latitud'] as num?)?.toDouble();
      final lon = (widget.puntos[1]['longitud'] as num?)?.toDouble();
      if (lat != null && lon != null) return LatLng(lat, lon);
    }
    return RutaContinental.paradaBTeleferico;
  }

  @override
  void didUpdateWidget(covariant MapaConductorVivo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapaListo &&
        _seguirConductor &&
        widget.posicionConductor != null &&
        widget.posicionConductor != oldWidget.posicionConductor) {
      final zoomActual = _mapController.camera.zoom;
      _mapController.move(widget.posicionConductor!, zoomActual < 17.5 ? 18.5 : zoomActual);
    }
  }

  void _enfocarPunto(LatLng destino, double zoom, {bool seguir = false}) {
    setState(() => _seguirConductor = seguir);
    if (_mapaListo) {
      _mapController.move(destino, zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final centroInicial = widget.posicionConductor ?? _coordA;
    final zoomInicial = 18.2;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.dentroDeGeocerca ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
          width: widget.dentroDeGeocerca ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.5),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centroInicial,
                initialZoom: zoomInicial,
                maxZoom: 20.0,
                onMapReady: () {
                  _mapaListo = true;
                  if (widget.posicionConductor != null) {
                    _mapController.move(widget.posicionConductor!, zoomInicial);
                  }
                },
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture && _seguirConductor) {
                    setState(() => _seguirConductor = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.continental',
                  maxZoom: 20,
                ),

                // Trazado vial oficial y línea de guía al Conductor
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: RutaContinental.puntosVuelta,
                      strokeWidth: 3.5,
                      color: const Color(0xFFD97706),
                      borderStrokeWidth: 1.2,
                      borderColor: Colors.white,
                    ),
                    Polyline(
                      points: RutaContinental.puntosIda,
                      strokeWidth: 4.0,
                      color: const Color(0xFF02634C),
                      borderStrokeWidth: 1.2,
                      borderColor: Colors.white,
                    ),
                    if (widget.posicionConductor != null)
                      Polyline(
                        points: [widget.posicionConductor!, _coordA],
                        color: widget.dentroDeGeocerca
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.75),
                        strokeWidth: 3.0,
                      ),
                  ],
                ),

                // Geocercas CIRCULARES de Parada A y Parada B (radio real de la BD)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: RutaContinental.anilloGeocerca(
                        _coordA,
                        ((widget.puntos.isNotEmpty
                                    ? (widget.puntos[0]['radio_m'] as num?)
                                        ?.toDouble()
                                    : null) ??
                                PuntosOficiales.radioAsistenciaM)
                            .clamp(5.0, 300.0),
                      ),
                      color: (widget.dentroDeGeocerca
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: 0.28),
                      borderColor: widget.dentroDeGeocerca
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                      borderStrokeWidth: 3.2,
                    ),
                    Polygon(
                      points: RutaContinental.anilloGeocerca(
                        _coordB,
                        ((widget.puntos.length > 1
                                    ? (widget.puntos[1]['radio_m'] as num?)
                                        ?.toDouble()
                                    : null) ??
                                PuntosOficiales.radioAsistenciaM)
                            .clamp(5.0, 300.0),
                      ),
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.26),
                      borderColor: const Color(0xFFF59E0B),
                      borderStrokeWidth: 3.0,
                    ),
                  ],
                ),

                // Marcadores de Parada A, Parada B y posición en vivo del Conductor ("TÚ")
                MarkerLayer(
                  markers: [
                    _buildParadaMarker(_coordA, 'A', const Color(0xFF10B981)),
                    _buildParadaMarker(_coordB, 'B', const Color(0xFFF59E0B)),
                    if (widget.posicionConductor != null)
                      Marker(
                        point: widget.posicionConductor!,
                        width: 58,
                        height: 52,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TÚ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black38, blurRadius: 6),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Etiqueta superior de estado en vivo sobre el mapa
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.dentroDeGeocerca
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0F265C).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.dentroDeGeocerca ? Icons.check_circle : Icons.radar,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.dentroDeGeocerca
                              ? 'DENTRO DE PARADA A'
                              : 'RADAR GPS EN VIVO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botones rápidos abajo del mapa para enfocar: Mi GPS, Parada A, Parada B
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildBotonMapa(
                        label: 'Parada A (Villadela)',
                        color: const Color(0xFF10B981),
                        onTap: () => _enfocarPunto(_coordA, 18.2),
                      ),
                      const SizedBox(width: 6),
                      _buildBotonMapa(
                        label: 'Parada B (Teleférico)',
                        color: const Color(0xFFF59E0B),
                        onTap: () => _enfocarPunto(_coordB, 18.2),
                      ),
                    ],
                  ),
                  _buildBotonMapa(
                    label: 'Mi GPS',
                    icon: Icons.my_location,
                    color: _seguirConductor ? const Color(0xFF2563EB) : const Color(0xFF475569),
                    onTap: () {
                      if (widget.posicionConductor != null) {
                        _enfocarPunto(widget.posicionConductor!, 18.8, seguir: true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildParadaMarker(LatLng point, String letra, Color color) {
    return Marker(
      point: point,
      width: 34,
      height: 34,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Text(
          letra,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBotonMapa({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ] else ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

