import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';

class SancionesScreen extends StatefulWidget {
  const SancionesScreen({super.key});

  @override
  State<SancionesScreen> createState() => _SancionesScreenState();
}

class _SancionesScreenState extends State<SancionesScreen> {
  int _selectedTab = 0; // 0: Todas, 1: Pendientes, 2: Cumplidas
  List<Map<String, dynamic>> _sanciones = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(context, SesionService.instance.rol, Permisos.moduloSanciones)) {
        return;
      }
    });
    _cargarSanciones();
  }

  Future<void> _cargarSanciones() async {
    setState(() => _isLoading = true);
    try {
      String? estado;
      if (_selectedTab == 1) estado = 'pendiente';
      if (_selectedTab == 2) estado = 'cumplida';

      final idConductor = SesionService.instance.esConductor
          ? SesionService.instance.idConductor
          : null;

      final lista = await DatabaseHelper.instance.sancionesDetalle(
        idConductor: idConductor,
        estado: estado,
      );
      if (mounted) {
        setState(() {
          _sanciones = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoRegistrarSancion() async {
    final conductores = await DatabaseHelper.instance.listar('conductor');
    if (!mounted) return;

    if (conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero registra conductores para poder aplicar sanciones.')),
      );
      return;
    }

    String? conductorSeleccionado = conductores.first['id_conductor']?.toString();
    final motivoCtrl = TextEditingController();
    final vueltasCtrl = TextEditingController(text: '1');
    final multaCtrl = TextEditingController(text: '30.00');
    bool generarMultaEconomica = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Registrar Sanción', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
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
                TextField(
                  controller: motivoCtrl,
                  decoration: const InputDecoration(labelText: 'Motivo de la sanción', hintText: 'Ej. Tardanza o desvío de ruta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vueltasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Vueltas de sanción asignadas', hintText: 'Ej. 2'),
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Generar multa económica en Hacienda',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E3A8A)),
                  ),
                  subtitle: const Text(
                    'Crea una deuda pendiente en el estado de cuenta del chofer',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  value: generarMultaEconomica,
                  onChanged: (val) => setDialogState(() => generarMultaEconomica = val ?? true),
                ),
                if (generarMultaEconomica) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: multaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto de la Multa (Bs.)',
                      prefixText: 'Bs. ',
                    ),
                  ),
                ],
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
                final motivo = motivoCtrl.text.trim();
                final vueltas = int.tryParse(vueltasCtrl.text.trim()) ?? 1;
                final montoMulta = double.tryParse(multaCtrl.text.trim()) ?? 0.0;
                if (motivo.isEmpty || conductorSeleccionado == null) return;

                final now = DateTime.now();
                final fecha = now.toIso8601String().substring(0, 10);
                final hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

                await DatabaseHelper.instance.insertar('sancion', {
                  'id_conductor': conductorSeleccionado,
                  'motivo': motivo,
                  'vueltas_asignadas': vueltas,
                  'vueltas_cumplidas': 0,
                  'estado': 'pendiente',
                  'fecha': fecha,
                  'hora': hora,
                });

                // Si se activa la multa económica, generar automáticamente la cuota de deuda
                if (generarMultaEconomica && montoMulta > 0) {
                  final db = await DatabaseHelper.instance.database;
                  final tipoMulta = await db.query(
                    'tipo_cuota',
                    where: "nombre = 'Multa / Sanción'",
                    limit: 1,
                  );
                  if (tipoMulta.isNotEmpty) {
                    final idTipo = tipoMulta.first['id_tipo_cuota'].toString();
                    await EconomiaRepo.instance.crearCuota(
                      idConductor: conductorSeleccionado!,
                      idTipoCuota: idTipo,
                      monto: montoMulta,
                      concepto: 'Sanción operativa: $motivo',
                      registradoPor: SesionService.instance.idUsuario ?? 'sistema',
                    );
                  }
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _cargarSanciones();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        generarMultaEconomica && montoMulta > 0
                            ? 'Sanción registrada y deuda de Bs. ${montoMulta.toStringAsFixed(2)} creada en Hacienda.'
                            : 'Sanción registrada exitosamente.',
                      ),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esConductor = SesionService.instance.esConductor;
    final puedeEditar = Permisos.puedeEditar(SesionService.instance.rol, Permisos.moduloSanciones);

    final sancionesFiltradas = _sanciones.where((s) {
      final q = _filtroTexto.toLowerCase().trim();
      if (q.isEmpty) return true;
      final nombre = (s['conductor_nombre'] ?? '').toString().toLowerCase();
      final motivo = (s['motivo'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || motivo.contains(q);
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
          esConductor ? 'Mis Sanciones' : 'Control de Sanciones',
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _cargarSanciones,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
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
                  hintText: 'Buscar conductor o motivo...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab('Todas', 0),
                _buildTab('Pendientes', 1),
                _buildTab('Cumplidas', 2),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sancionesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No hay sanciones registradas en la base de datos.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarSanciones,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: sancionesFiltradas.length,
                          itemBuilder: (context, index) {
                            final s = sancionesFiltradas[index];
                            final conductor = s['conductor_nombre'] ?? 'Conductor';
                            final motivo = s['motivo'] ?? 'Sin motivo';
                            final fecha = s['fecha'] ?? '';
                            final hora = s['hora'] ?? '';
                            final vueltas = s['vueltas_asignadas'] ?? 0;
                            final estado = s['estado']?.toString() ?? 'pendiente';
                            final isPending = estado.toLowerCase() == 'pendiente';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFEFF6FF),
                                    child: Icon(Icons.person, color: Color(0xFF3B82F6)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(conductor, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 6),
                                        Text('Motivo: $motivo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                        Text('Hora: $hora', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                        Text('Vueltas asignadas: $vueltas', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPending ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isPending ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                                              color: isPending ? const Color(0xFFEF4444) : const Color(0xFF10B981), 
                                              size: 12
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              estado.toUpperCase(), 
                                              style: TextStyle(
                                                color: isPending ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                fontSize: 10, 
                                                fontWeight: FontWeight.bold
                                              )
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(fecha, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: puedeEditar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _mostrarDialogoRegistrarSancion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Registrar sanción', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        _cargarSanciones();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
