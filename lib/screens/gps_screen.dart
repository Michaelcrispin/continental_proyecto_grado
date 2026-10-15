import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_helper.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _puntos = [];
  Map<String, dynamic>? _conductorSeleccionado;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final conductores = await DatabaseHelper.instance.conductoresConAuto();
      final puntos = await DatabaseHelper.instance.listar('punto_de_control');

      if (mounted) {
        setState(() {
          _conductores = conductores;
          _puntos = puntos;
          if (conductores.isNotEmpty) {
            _conductorSeleccionado = conductores.first;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conductorTexto = _conductorSeleccionado != null
        ? '${_conductorSeleccionado!['placa'] ?? 'S/Placa'} • ${_conductorSeleccionado!['nombre']}'
        : 'Sin conductores registrados';
    final estadoTexto = _conductorSeleccionado != null
        ? 'Estado: ${_conductorSeleccionado!['estado']?.toString().toUpperCase() ?? 'ACTIVO'}'
        : 'Base de datos sin registros';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('GPS - Monitoreo de Rutas', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _cargarDatos,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo.png', height: 24, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-16.5050, -68.1600),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.continental',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: const [
                      LatLng(-16.5100, -68.1550),
                      LatLng(-16.5050, -68.1600),
                      LatLng(-16.4950, -68.1400),
                    ],
                    color: const Color(0xFF3B82F6),
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(-16.5050, -68.1600),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                      ),
                      child: const Icon(Icons.directions_bus, color: Color(0xFF3B82F6), size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Header Overlay
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Info Pill con datos reales de la BD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.person, color: Color(0xFF3B82F6), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(conductorTexto, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                            Text(estadoTexto, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                          ],
                        ),
                      ),
                      if (_conductores.length > 1)
                        PopupMenuButton<Map<String, dynamic>>(
                          icon: const Icon(Icons.swap_horiz, color: Color(0xFF3B82F6)),
                          tooltip: 'Cambiar conductor',
                          onSelected: (c) => setState(() => _conductorSeleccionado = c),
                          itemBuilder: (ctx) => _conductores.map((c) => PopupMenuItem(
                            value: c,
                            child: Text('${c['nombre']} (${c['placa'] ?? 'S/Placa'})'),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Map controls
          Positioned(
            right: 20,
            bottom: 180,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF1E3A8A)),
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                      ),
                      Container(height: 1, width: 30, color: const Color(0xFFF1F5F9)),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Color(0xFF1E3A8A)),
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  onPressed: () {
                    _mapController.move(const LatLng(-16.5050, -68.1600), 14.0);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
          
          // Bottom Sheet: Puntos de control registrados en SQLite
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Puntos de control', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  if (_puntos.isEmpty)
                    const Text('No hay puntos de control en la base de datos.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                  else
                    Column(
                      children: _puntos.take(3).map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p['nombre']?.toString() ?? '',
                                  style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
