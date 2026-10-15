import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _asistencias = [];
  List<Map<String, dynamic>> _puntos = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';

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

  String get _fechaString => _selectedDate.toIso8601String().substring(0, 10);

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final idConductor = SesionService.instance.esConductor
          ? SesionService.instance.idConductor
          : null;

      final asistencias = await DatabaseHelper.instance.asistenciasDetalle(
        idConductor: idConductor,
        fecha: _fechaString,
      );
      final puntos = await DatabaseHelper.instance.listar('punto_de_control');

      if (mounted) {
        setState(() {
          _asistencias = asistencias;
          _puntos = puntos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return const Color(0xFF10B981);
      case 'tardanza':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  void _mostrarDialogoRegistrarAsistencia() async {
    final esConductor = SesionService.instance.esConductor;
    final miIdConductor = SesionService.instance.idConductor;
    final miNombre = SesionService.instance.nombre ?? 'Conductor';
    final miCi = SesionService.instance.ci ?? '';

    final conductores = await DatabaseHelper.instance.listar('conductor');
    final puntos = await DatabaseHelper.instance.listar('punto_de_control');

    if (!mounted) return;

    if (!esConductor && conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes registrar conductores en el módulo Conductores.')),
      );
      return;
    }

    String? conductorSeleccionado = esConductor ? miIdConductor : (conductores.isNotEmpty ? conductores.first['id_conductor']?.toString() : null);
    String? puntoSeleccionado = puntos.isNotEmpty ? puntos.first['id_punto']?.toString() : null;
    String estadoSeleccionado = 'presente';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            esConductor ? 'Marcar Mi Asistencia' : 'Registrar Asistencia',
            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conductor:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (esConductor) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '$miNombre ${miCi.isNotEmpty ? '(CI: $miCi)' : ''}',
                      style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  DropdownButton<String>(
                    isExpanded: true,
                    value: conductorSeleccionado,
                    items: conductores.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['id_conductor']?.toString(),
                        child: Text('${c['nombre']} (CI: ${c['ci']})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => conductorSeleccionado = val),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Punto de control:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (puntos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No hay puntos de control registrados.', style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                else
                  DropdownButton<String>(
                    isExpanded: true,
                    value: puntoSeleccionado,
                    items: puntos.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id_punto']?.toString(),
                        child: Text(p['nombre']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => puntoSeleccionado = val),
                  ),
                const SizedBox(height: 12),
                const Text('Estado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: estadoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'presente', child: Text('Presente')),
                    DropdownMenuItem(value: 'tardanza', child: Text('Tardanza')),
                    DropdownMenuItem(value: 'falta', child: Text('Falta')),
                  ],
                  onChanged: (val) => setDialogState(() => estadoSeleccionado = val ?? 'presente'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                if (conductorSeleccionado == null) return;

                // Si no hay punto de control en BD, insertamos uno base
                String idPunto = puntoSeleccionado ?? '';
                if (idPunto.isEmpty) {
                  idPunto = await DatabaseHelper.instance.insertar('punto_de_control', {
                    'nombre': 'Parada Central',
                  });
                }

                final now = DateTime.now();
                final hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

                await DatabaseHelper.instance.insertar('asistencia', {
                  'id_conductor': conductorSeleccionado,
                  'id_punto': idPunto,
                  'fecha': _fechaString,
                  'hora_llegada': hora,
                  'estado': estadoSeleccionado,
                });

                if (ctx.mounted) Navigator.pop(ctx);
                _cargarDatos();
              },
              child: const Text('Registrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esConductor = SesionService.instance.esConductor;
    final tituloPantalla = esConductor ? 'Mi Asistencia' : 'Control de Asistencia';
    final asistenciasFiltradas = _asistencias.where((a) {
      final query = _filtroTexto.toLowerCase().trim();
      if (query.isEmpty) return true;
      final nombre = (a['conductor_nombre'] ?? '').toString().toLowerCase();
      final punto = (a['punto_nombre'] ?? '').toString().toLowerCase();
      return nombre.contains(query) || punto.contains(query);
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
        title: Text(tituloPantalla, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _cargarDatos,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Fecha Dinámico
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fecha: ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}', 
                        style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600)
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Puntos de control desde SQLite
            const Text('Puntos de control', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_puntos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No hay puntos de control en la base de datos.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              )
            else
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _puntos.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final p = _puntos[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            p['nombre']?.toString() ?? 'Punto',
                            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            
            // Buscador
            const Text('Registros de Asistencia', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filtroTexto = val),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                  hintText: 'Filtrar por conductor o punto...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista Real de Asistencias
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
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
                    Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay asistencias registradas para esta fecha.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
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
                  final a = asistenciasFiltradas[index];
                  final conductorNombre = a['conductor_nombre'] ?? 'Desconocido';
                  final puntoNombre = a['punto_nombre'] ?? 'Sin punto';
                  final hora = a['hora_llegada'] ?? '--:--';
                  final estado = a['estado']?.toString() ?? 'presente';
                  final color = _obtenerColorEstado(estado);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFEFF6FF),
                          child: Icon(Icons.person, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conductorNombre, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Punto: $puntoNombre • Hora: $hora', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estado.toUpperCase(), 
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _mostrarDialogoRegistrarAsistencia,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              icon: const Icon(Icons.how_to_reg, color: Colors.white),
              label: const Text('Registrar asistencia', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
