import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';

class VueltasScreen extends StatefulWidget {
  const VueltasScreen({super.key});

  @override
  State<VueltasScreen> createState() => _VueltasScreenState();
}

class _VueltasScreenState extends State<VueltasScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _vueltas = [];
  bool _isLoading = true;

  String get _fechaString => _selectedDate.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(context, SesionService.instance.rol, Permisos.moduloVueltas)) {
        return;
      }
    });
    _cargarVueltas();
  }

  Future<void> _cargarVueltas() async {
    setState(() => _isLoading = true);
    try {
      final idConductor = SesionService.instance.esConductor
          ? SesionService.instance.idConductor
          : null;

      final lista = await DatabaseHelper.instance.vueltasDetalle(
        idConductor: idConductor,
        fecha: _fechaString,
      );
      if (mounted) {
        setState(() {
          _vueltas = lista;
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
      _cargarVueltas();
    }
  }

  void _mostrarDialogoRegistrarVuelta() async {
    final conductores = await DatabaseHelper.instance.listar('conductor');
    if (!mounted) return;

    if (conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero registra conductores para poder despachar vueltas.')),
      );
      return;
    }

    String? conductorSeleccionado = conductores.first['id_conductor']?.toString();
    String tipoSeleccionado = 'Completa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Registrar Vuelta / Turno', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conductor:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                const SizedBox(height: 12),
                const Text('Tipo de vuelta:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: tipoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'Completa', child: Text('Vuelta Completa')),
                    DropdownMenuItem(value: 'Media Vuelta', child: Text('Media Vuelta')),
                    DropdownMenuItem(value: 'Turno Mañana', child: Text('Turno Mañana')),
                    DropdownMenuItem(value: 'Turno Tarde', child: Text('Turno Tarde')),
                  ],
                  onChanged: (val) => setDialogState(() => tipoSeleccionado = val ?? 'Completa'),
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
                final now = DateTime.now();
                final hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

                await DatabaseHelper.instance.insertar('vueltas', {
                  'id_conductor': conductorSeleccionado,
                  'fecha': _fechaString,
                  'hora': hora,
                  'tipo': tipoSeleccionado,
                });

                if (ctx.mounted) Navigator.pop(ctx);
                _cargarVueltas();
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
    final puedeEditar = Permisos.puedeEditar(SesionService.instance.rol, Permisos.moduloVueltas);

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
          esConductor ? 'Mis Vueltas' : 'Control de Vueltas',
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _cargarVueltas,
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
            // Selector de Fecha
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
            const SizedBox(height: 20),
            
            Text(
              'Vueltas registradas (${_vueltas.length})', 
              style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_vueltas.isEmpty)
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
                    Icon(Icons.route_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay vueltas registradas para esta fecha en la base de datos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _vueltas.length,
                itemBuilder: (context, index) {
                  final v = _vueltas[index];
                  final conductor = v['conductor_nombre'] ?? 'Conductor';
                  final hora = v['hora'] ?? '--:--';
                  final tipo = v['tipo'] ?? 'Vuelta';

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
                          child: Icon(Icons.route, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conductor, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Tipo: $tipo • Hora: $hora', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'COMPLETADA', 
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)
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
      bottomNavigationBar: puedeEditar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _mostrarDialogoRegistrarVuelta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Registrar vuelta', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
