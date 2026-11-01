import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/asistencia_repo.dart';
import '../../services/database_helper.dart';
import '../../services/sesion_service.dart';
import 'puntos_control_screen.dart';
import 'widgets/asistencia_item_card.dart';
import 'widgets/asistencia_manual_dialog.dart';
import 'widgets/asistencia_resumen_banner.dart';
import 'widgets/marcar_llegada_card.dart';

/// Pantalla Principal del Módulo de Asistencia.
/// Soporta marcado automatizado por GPS para conductores, registro manual por supervisores
/// y calibración de geocercas en mapa.
class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _asistencias = [];
  List<Map<String, dynamic>> _puntos = [];
  Map<String, int> _estadisticas = {'presentes': 0, 'tardanzas': 0, 'faltas': 0, 'total': 0};
  bool _isLoading = true;
  int _refreshTick = 0;
  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';
  String _filtroEstado = 'todos'; // 'todos' | 'presente' | 'tardanza' | 'falta'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(context, SesionService.instance.rol, Permisos.moduloAsistencia)) {
        return;
      }
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _fechaString => _selectedDate.toIso8601String().substring(0, 10);

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final esConductor = SesionService.instance.esConductor;
      final idConductor = esConductor ? SesionService.instance.idConductor : null;

      final asistencias = await DatabaseHelper.instance.asistenciasDetalle(
        idConductor: idConductor,
        fecha: _fechaString,
      );
      final puntos = await DatabaseHelper.instance.obtenerPuntosControl(soloActivos: false);
      final stats = await AsistenciaRepo.instance.obtenerEstadisticasHoy(_fechaString);

      if (mounted) {
        setState(() {
          _asistencias = asistencias;
          _puntos = puntos;
          _estadisticas = stats;
          _refreshTick++;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _cargarDatos();
    }
  }

  void _abrirPuntosControl() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PuntosControlScreen()),
    ).then((_) => _cargarDatos());
  }

  void _abrirRegistroManual() {
    showDialog(
      context: context,
      builder: (_) => AsistenciaManualDialog(onGuardado: _cargarDatos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esConductor = SesionService.instance.esConductor;
    final esSuperadmin = SesionService.instance.esSuperadmin;
    final esSupervisor = SesionService.instance.esSupervisor || SesionService.instance.esAdmin || esSuperadmin;
    final tituloPantalla = esConductor ? 'Mi Asistencia Matutina' : 'Control de Asistencia GPS';

    final asistenciasFiltradas = _asistencias.where((a) {
      final query = _filtroTexto.toLowerCase().trim();
      final nombre = (a['conductor_nombre'] ?? '').toString().toLowerCase();
      final punto = (a['punto_nombre'] ?? '').toString().toLowerCase();
      final matchTexto = query.isEmpty || nombre.contains(query) || punto.contains(query);

      final estado = (a['estado'] ?? '').toString().toLowerCase();
      final matchEstado = _filtroEstado == 'todos' || estado == _filtroEstado;

      return matchTexto && matchEstado;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tituloPantalla,
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Color(0xFF3B82F6)),
            tooltip: 'Elegir Punto y Radio GPS',
            onPressed: _abrirPuntosControl,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            tooltip: 'Actualizar',
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Fecha
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fecha: ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                        style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Banner de Estadísticas del Día (solo para Supervisores / Admin)
            if (!esConductor) ...[
              AsistenciaResumenBanner(
                presentes: _estadisticas['presentes'] ?? 0,
                tardanzas: _estadisticas['tardanzas'] ?? 0,
                faltas: _estadisticas['faltas'] ?? 0,
                total: _estadisticas['total'] ?? 0,
              ),
              const SizedBox(height: 14),
            ],

            // Resumen de Puntos de Parada A (Cruce) y B (Teleférico)
            if (_puntos.isNotEmpty) ...[
              _buildResumenParadas(),
              const SizedBox(height: 14),
            ],

            // Card con Mapa GPS en Vivo y Marcado si es conductor
            if (esConductor) ...[
              MarcarLlegadaCard(
                key: ValueKey(_refreshTick),
                onAsistenciaRegistrada: _cargarDatos,
              ),
              const SizedBox(height: 18),
            ],

            // Encabezado de Lista con botón para supervisor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  esConductor ? 'Mi Registro del Día' : 'Registros del Día',
                  style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (esSupervisor)
                  TextButton.icon(
                    onPressed: _abrirRegistroManual,
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF3B82F6)),
                    label: const Text('Registro Manual', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Buscador y chips de filtrado (solo para Supervisores / Admin)
            if (!esConductor) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filtroTexto = val),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                    hintText: 'Buscar conductor o punto...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFiltroChip('todos', 'Todos (${_asistencias.length})'),
                    const SizedBox(width: 6),
                    _buildFiltroChip('presente', 'A tiempo (${_estadisticas['presentes'] ?? 0})'),
                    const SizedBox(width: 6),
                    _buildFiltroChip('tardanza', 'Tardanzas (${_estadisticas['tardanzas'] ?? 0})'),
                    const SizedBox(width: 6),
                    _buildFiltroChip('falta', 'Faltas (${_estadisticas['faltas'] ?? 0})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Lista de Asistencias
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (asistenciasFiltradas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      esConductor
                          ? 'Aún no registraste tu asistencia en esta fecha.'
                          : 'No hay registros de asistencia para los filtros seleccionados.',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: asistenciasFiltradas.length,
                itemBuilder: (context, index) {
                  return AsistenciaItemCard(asistencia: asistenciasFiltradas[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenParadas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Puntos de Parada Oficiales (A y B)',
              style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: _abrirPuntosControl,
              child: const Text(
                'Elegir punto / radio →',
                style: TextStyle(color: Color(0xFF3B82F6), fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_puntos.take(2).length, (index) {
            final p = _puntos[index];
            final esA = index == 0 || (p['es_punto_asistencia'] as num?)?.toInt() == 1;
            final color = esA ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
            final letra = esA ? 'A' : 'B';
            final radio = p['radio_m'] ?? 100;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 0 ? 8.0 : 0),
                child: InkWell(
                  onTap: _abrirPuntosControl,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(
                            letra,
                            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['nombre']?.toString() ?? 'Parada $letra',
                                style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 11.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${esA ? "Asistencia" : "Retorno"} • Radio ${radio}m',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String estado, String label) {
    final sel = _filtroEstado == estado;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      selectedColor: const Color(0xFF3B82F6),
      labelStyle: TextStyle(
        color: sel ? Colors.white : const Color(0xFF64748B),
        fontSize: 11,
        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _filtroEstado = estado),
    );
  }
}
