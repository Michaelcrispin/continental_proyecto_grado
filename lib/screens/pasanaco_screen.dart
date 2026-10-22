import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';
import 'cobrar_screen.dart';

/// Vista E11: Pasanaco (Gestión de fondos rotativos, sorteo de turnos, rondas y entregas)
class PasanacoScreen extends StatefulWidget {
  const PasanacoScreen({super.key});

  @override
  State<PasanacoScreen> createState() => _PasanacoScreenState();
}

class _PasanacoScreenState extends State<PasanacoScreen> {
  List<Map<String, dynamic>> _pasanacos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPasanacos();
  }

  Future<void> _cargarPasanacos() async {
    setState(() => _isLoading = true);
    try {
      final lista = await EconomiaRepo.instance.listarPasanacos();
      if (mounted) {
        setState(() {
          _pasanacos = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _dialogoCrearPasanaco() async {
    final conductores = await DatabaseHelper.instance.listar(
      'conductor',
      where: "LOWER(estado) = 'activo'",
      orderBy: 'nombre ASC',
    );

    if (!mounted) return;

    if (conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay conductores activos para crear un pasanaco.')),
      );
      return;
    }

    final nombreCtrl = TextEditingController(text: 'Pasanaco General 2026');
    final montoCtrl = TextEditingController(text: '100.00');
    final fechaInicioCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    String periodicidad = 'semanal';
    final seleccionados = <String>{...conductores.map((c) => c['id_conductor'].toString())};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final totalPozo = (double.tryParse(montoCtrl.text.trim()) ?? 0.0) * seleccionados.length;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.savings_outlined, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text('Nuevo Pasanaco', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Pasanaco *',
                        hintText: 'Ej. Pasanaco Fin de Año',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: montoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Aporte por Ronda *',
                              prefixText: 'Bs. ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: periodicidad,
                            decoration: InputDecoration(
                              labelText: 'Periodicidad',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                              DropdownMenuItem(value: 'quincenal', child: Text('Quincenal')),
                              DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => periodicidad = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fechaInicioCtrl,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Inicio (AAAA-MM-DD) *',
                        prefixIcon: const Icon(Icons.calendar_today, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Resumen del pozo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Participantes: ${seleccionados.length} / ${conductores.length}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF3730A3)),
                          ),
                          Text(
                            'Pozo: Bs. ${totalPozo.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Seleccionar Participantes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              if (seleccionados.length == conductores.length) {
                                seleccionados.clear();
                              } else {
                                seleccionados.addAll(conductores.map((c) => c['id_conductor'].toString()));
                              }
                            });
                          },
                          child: Text(
                            seleccionados.length == conductores.length ? 'Desmarcar todos' : 'Todos',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: conductores.length,
                        itemBuilder: (ctx, i) {
                          final c = conductores[i];
                          final id = c['id_conductor'].toString();
                          final isChecked = seleccionados.contains(id);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(c['nombre']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                            subtitle: Text('CI: ${c['ci']}', style: const TextStyle(fontSize: 11)),
                            value: isChecked,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  seleccionados.add(id);
                                } else {
                                  seleccionados.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  final monto = double.tryParse(montoCtrl.text.trim()) ?? 0.0;
                  final fecha = fechaInicioCtrl.text.trim();

                  if (nombre.isEmpty || monto <= 0 || fecha.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor completa todos los campos correctamente.')),
                    );
                    return;
                  }
                  if (seleccionados.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Un pasanaco debe tener al menos 2 participantes.')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    await EconomiaRepo.instance.crearPasanaco(
                      nombre: nombre,
                      montoAporte: monto,
                      periodicidad: periodicidad,
                      fechaInicio: fecha,
                      idsConductores: seleccionados.toList(),
                    );
                    _cargarPasanacos();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pasanaco creado exitosamente con sus participantes.'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Crear Pasanaco', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Pasanacos Sindicato', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargarPasanacos,
          ),
        ],
      ),
      floatingActionButton: puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _dialogoCrearPasanaco,
              backgroundColor: const Color(0xFF4F46E5),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo Pasanaco', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pasanacos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings_outlined, size: 70, color: Colors.indigo.shade200),
                      const SizedBox(height: 14),
                      const Text(
                        'No hay pasanacos registrados.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Organiza fondos rotativos entre los choferes afiliados.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),
                      if (puedeEditar) ...[
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _dialogoCrearPasanaco,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Crear Primer Pasanaco', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: _pasanacos.length,
                  itemBuilder: (ctx, i) {
                    final p = _pasanacos[i];
                    return _buildCardPasanaco(p, puedeEditar);
                  },
                ),
    );
  }

  Widget _buildCardPasanaco(Map<String, dynamic> p, bool puedeEditar) {
    final idPasanaco = p['id_pasanaco'].toString();
    final nombre = p['nombre']?.toString() ?? 'Pasanaco';
    final aporte = (p['monto_aporte'] as num?)?.toDouble() ?? 0.0;
    final periodicidad = p['periodicidad']?.toString() ?? 'semanal';
    final estado = p['estado']?.toString().toLowerCase() ?? 'activo';
    final participantes = (p['cantidad_participantes'] as num?)?.toInt() ?? 0;
    final rondasEntregadas = (p['rondas_entregadas'] as num?)?.toInt() ?? 0;
    final pozoEstimado = aporte * participantes;

    final isActivo = estado == 'activo';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PasanacoDetalleScreen(
                idPasanaco: idPasanaco,
                puedeEditar: puedeEditar,
              ),
            ),
          );
          _cargarPasanacos();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActivo ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.savings,
                      color: isActivo ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActivo ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActivo ? const Color(0xFF15803D) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Inicio: ${p['fecha_inicio'] ?? ''}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bs. ${aporte.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4F46E5)),
                      ),
                      Text(
                        'por $periodicidad',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _itemResumen(
                    icono: Icons.people_outline,
                    titulo: 'Participantes',
                    valor: '$participantes personas',
                  ),
                  _itemResumen(
                    icono: Icons.payments_outlined,
                    titulo: 'Pozo por Ronda',
                    valor: 'Bs. ${pozoEstimado.toStringAsFixed(2)}',
                  ),
                  _itemResumen(
                    icono: Icons.sync,
                    titulo: 'Rondas Entregadas',
                    valor: '$rondasEntregadas / $participantes',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemResumen({required IconData icono, required String titulo, required String valor}) {
    return Row(
      children: [
        Icon(icono, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ],
        ),
      ],
    );
  }
}

/// Pantalla de Detalle de Pasanaco: Rondas, Turnos y Aportes
class PasanacoDetalleScreen extends StatefulWidget {
  final String idPasanaco;
  final bool puedeEditar;

  const PasanacoDetalleScreen({
    super.key,
    required this.idPasanaco,
    required this.puedeEditar,
  });

  @override
  State<PasanacoDetalleScreen> createState() => _PasanacoDetalleScreenState();
}

class _PasanacoDetalleScreenState extends State<PasanacoDetalleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _pasanaco;
  List<Map<String, dynamic>> _participantes = [];
  List<Map<String, dynamic>> _rondas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final pList = await db.query(
        'pasanaco',
        where: 'id_pasanaco = ?',
        whereArgs: [widget.idPasanaco],
        limit: 1,
      );
      if (pList.isNotEmpty) {
        _pasanaco = pList.first;
      }
      final parts = await EconomiaRepo.instance.participantesPasanaco(widget.idPasanaco);
      final ronds = await EconomiaRepo.instance.rondasDePasanaco(widget.idPasanaco);

      if (mounted) {
        setState(() {
          _participantes = parts;
          _rondas = ronds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _dialogoGenerarSiguienteRonda() {
    final fechaLimiteCtrl = TextEditingController(
      text: DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
    );

    final maxRonda = _rondas.length;
    final sigRonda = maxRonda + 1;
    if (sigRonda > _participantes.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya se han completado todas las rondas de este pasanaco.')),
      );
      return;
    }

    final beneficiario = _participantes[sigRonda - 1];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_task, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text('Generar Ronda #$sigRonda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  AvatarConductor(
                    nombre: beneficiario['conductor_nombre']?.toString() ?? '',
                    foto: beneficiario['conductor_foto']?.toString(),
                    radio: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Beneficiario de esta ronda:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text(
                          beneficiario['conductor_nombre']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        Text('Turno #${beneficiario['numero_turno']} • CI: ${beneficiario['conductor_ci']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Al generar la ronda, se creará automáticamente una deuda de Bs. ${(_pasanaco?['monto_aporte'] as num?)?.toStringAsFixed(2) ?? '0.00'} para cada uno de los ${_participantes.length} participantes.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: fechaLimiteCtrl,
              decoration: InputDecoration(
                labelText: 'Fecha Límite de Aporte (AAAA-MM-DD) *',
                prefixIcon: const Icon(Icons.calendar_today, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final fecha = fechaLimiteCtrl.text.trim();
              if (fecha.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await EconomiaRepo.instance.generarSiguienteRondaPasanaco(
                  idPasanaco: widget.idPasanaco,
                  fechaLimite: fecha,
                  idUsuario: SesionService.instance.idUsuario ?? 'sistema',
                );
                _cargarTodo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ronda #$sigRonda generada con éxito con las cuotas de aporte.'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Confirmar y Crear Cuotas', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _dialogoVerAportesRonda(Map<String, dynamic> ronda) async {
    final idRonda = ronda['id_ronda'].toString();
    final aportes = await EconomiaRepo.instance.aportesDeRonda(idRonda);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aportes Ronda #${ronda['numero_ronda']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'Beneficiario: ${ronda['beneficiario_nombre']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Text(
                    'Bs. ${(ronda['monto_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: aportes.isEmpty
                    ? const Center(child: Text('No hay registros de aportes.'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: aportes.length,
                        itemBuilder: (ctx, i) {
                          final a = aportes[i];
                          final estado = a['estado']?.toString().toLowerCase() ?? 'pendiente';
                          final pagado = (a['monto_pagado'] as num?)?.toDouble() ?? 0.0;
                          final saldo = (a['saldo'] as num?)?.toDouble() ?? 0.0;
                          final idCuota = a['id_cuota'].toString();

                          final isPagado = estado == 'pagado';
                          final isParcial = estado == 'parcial';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: AvatarConductor(
                              nombre: a['conductor_nombre']?.toString() ?? '',
                              foto: a['conductor_foto']?.toString(),
                              radio: 20,
                            ),
                            title: Text(
                              a['conductor_nombre']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              isPagado
                                  ? 'Aporte pagado completo'
                                  : isParcial
                                      ? 'Abonó: Bs. ${pagado.toStringAsFixed(2)} • Saldo: Bs. ${saldo.toStringAsFixed(2)}'
                                      : 'Debe Bs. ${saldo.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isPagado ? const Color(0xFF059669) : isParcial ? Colors.orange.shade700 : Colors.red.shade700,
                              ),
                            ),
                            trailing: !isPagado && widget.puedeEditar
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CobrarScreen(
                                            idConductorInicial: a['id_conductor']?.toString(),
                                            idCuotaInicial: idCuota,
                                          ),
                                        ),
                                      );
                                      _cargarTodo();
                                    },
                                    child: const Text('Cobrar', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPagado ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPagado ? 'PAGADO' : 'PENDIENTE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isPagado ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEntregarRonda(Map<String, dynamic> ronda) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Marcar Ronda como Entregada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          '¿Confirmas que el pozo total de Bs. ${(ronda['monto_total'] as num?)?.toStringAsFixed(2) ?? '0.00'} ya fue entregado a ${ronda['beneficiario_nombre']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await EconomiaRepo.instance.entregarRondaPasanaco(ronda['id_ronda'].toString());
                _cargarTodo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ronda marcada como entregada exitosamente.'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Confirmar Entrega', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarSorteoTurnos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.casino, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Sortear Turnos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Se sorteará aleatoriamente el orden de los turnos de entrega para todos los participantes. Esta acción reordenará los turnos futuros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await EconomiaRepo.instance.sortearTurnosPasanaco(widget.idPasanaco);
                _cargarTodo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Turnos sorteados exitosamente.'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al sortear: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Sortear Ahora', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _pasanaco?['nombre']?.toString() ?? 'Detalle del Pasanaco';
    final estado = _pasanaco?['estado']?.toString().toLowerCase() ?? 'activo';
    final aporte = (_pasanaco?['monto_aporte'] as num?)?.toDouble() ?? 0.0;
    final pozoTotal = aporte * _participantes.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Rondas (${_rondas.length}/${_participantes.length})'),
            Tab(text: 'Turnos (${_participantes.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Cabecera Resumen
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pozo por Ronda', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text(
                            'Bs. ${pozoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Aporte Individual', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text(
                            'Bs. ${aporte.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Estado', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: estado == 'activo' ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: estado == 'activo' ? const Color(0xFF15803D) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabRondas(),
                      _buildTabParticipantes(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabRondas() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.puedeEditar && _pasanaco?['estado'] == 'activo') ...[
          ElevatedButton.icon(
            onPressed: _dialogoGenerarSiguienteRonda,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: Text(
              'Generar Siguiente Ronda (#${_rondas.length + 1})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (_rondas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_repeat, size: 50, color: Colors.indigo.shade200),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay rondas generadas todavía.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Genera la primera ronda para asignar las cuotas de aporte.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._rondas.map((r) => _buildCardRonda(r)),
      ],
    );
  }

  Widget _buildCardRonda(Map<String, dynamic> r) {
    final nro = r['numero_ronda']?.toString() ?? '1';
    final estado = r['estado']?.toString().toLowerCase() ?? 'pendiente';
    final isEntregada = estado == 'entregada';
    final total = (r['monto_total'] as num?)?.toDouble() ?? 0.0;
    final recaudado = (r['total_recaudado'] as num?)?.toDouble() ?? 0.0;
    final pagados = (r['aportes_pagados'] as num?)?.toInt() ?? 0;
    final totalAportes = (r['total_aportes_esperados'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Ronda #$nro',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Límite: ${r['fecha_limite'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isEntregada ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEntregada ? 'ENTREGADA' : 'EN CURSO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isEntregada ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AvatarConductor(
                  nombre: r['beneficiario_nombre']?.toString() ?? '',
                  foto: r['beneficiario_foto']?.toString(),
                  radio: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Beneficiario:', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      Text(
                        r['beneficiario_nombre']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text('CI: ${r['beneficiario_ci']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Bs. ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4F46E5))),
                    Text('Recaudado: Bs. ${recaudado.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Color(0xFF059669))),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aportes: $pagados / $totalAportes pagados',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _dialogoVerAportesRonda(r),
                      icon: const Icon(Icons.checklist, size: 16),
                      label: const Text('Ver Aportes', style: TextStyle(fontSize: 11)),
                    ),
                    if (!isEntregada && widget.puedeEditar) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _confirmarEntregarRonda(r),
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Entregar', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabParticipantes() {
    return Column(
      children: [
        if (widget.puedeEditar && _pasanaco?['estado'] == 'activo')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Orden de Turnos para Entregas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                ),
                TextButton.icon(
                  onPressed: _confirmarSorteoTurnos,
                  icon: const Icon(Icons.casino, size: 16, color: Color(0xFF4F46E5)),
                  label: const Text('Sortear Orden', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _participantes.length,
            itemBuilder: (ctx, i) {
              final p = _participantes[i];
              final turno = p['numero_turno']?.toString() ?? '${i + 1}';
              final tieneRondaGenerada = i < _rondas.length;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEEF2FF),
                    foregroundColor: const Color(0xFF4F46E5),
                    child: Text('#$turno', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  title: Text(
                    p['conductor_nombre']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text('CI: ${p['conductor_ci']}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tieneRondaGenerada ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tieneRondaGenerada ? 'Ronda Iniciada' : 'Turno Pendiente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tieneRondaGenerada ? const Color(0xFF15803D) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
