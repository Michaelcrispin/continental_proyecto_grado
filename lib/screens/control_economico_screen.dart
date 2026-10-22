import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/economia_repo.dart';
import '../services/recibo_pdf_service.dart';
import '../services/sesion_service.dart';
import '../widgets/app_background.dart';
import '../widgets/avatar_conductor.dart';

/// Pantalla Principal de Control de Cuotas:
/// Simple, limpia y directa:
/// 1. Sin cuotas precargadas: inicia limpia.
/// 2. Creas una cuota con "+ Nueva" (ej: "Comprar luminaria", Bs. 200).
/// 3. Aparece la lista de choferes: verde lo pagado, rojo lo que falta.
/// 4. Botón directo de "Cobrar" para registrar abonos o pagos completos.
class ControlEconomicoScreen extends StatefulWidget {
  const ControlEconomicoScreen({super.key});

  @override
  State<ControlEconomicoScreen> createState() => _ControlEconomicoScreenState();
}

class _ControlEconomicoScreenState extends State<ControlEconomicoScreen> {
  List<Map<String, dynamic>> _tiposCuota = [];
  String? _idTipoSeleccionado;
  Map<String, dynamic>? _tipoSeleccionado;

  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _conductoresFiltrados = [];
  bool _isLoading = true;
  String _busqueda = '';
  String _filtroEstado = 'todos'; // 'todos' | 'pagados' | 'deben'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.puedeVer(
          SesionService.instance.rol, Permisos.moduloControlEconomico)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes acceso al módulo de Cuotas.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    });
    _cargarTiposYConductores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarTiposYConductores({String? idTipoASeleccionar}) async {
    setState(() => _isLoading = true);
    try {
      final tipos = await EconomiaRepo.instance.listarTiposCuota();
      if (tipos.isEmpty) {
        if (mounted) {
          setState(() {
            _tiposCuota = [];
            _idTipoSeleccionado = null;
            _tipoSeleccionado = null;
            _conductores = [];
            _conductoresFiltrados = [];
            _isLoading = false;
          });
        }
        return;
      }

      final idSeleccionado = idTipoASeleccionar ?? _idTipoSeleccionado ?? tipos.first['id_tipo_cuota'].toString();
      final tipoActual = tipos.firstWhere(
        (t) => t['id_tipo_cuota'].toString() == idSeleccionado,
        orElse: () => tipos.first,
      );

      final lista = await EconomiaRepo.instance.estadoConductoresPorCuota(idSeleccionado);

      if (mounted) {
        setState(() {
          _tiposCuota = tipos;
          _idTipoSeleccionado = idSeleccionado;
          _tipoSeleccionado = tipoActual;
          _conductores = lista;
          _filtrar(_busqueda);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar(String query) {
    _busqueda = query;
    final q = query.toLowerCase().trim();
    setState(() {
      _conductoresFiltrados = _conductores.where((c) {
        final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
        final alDia = falta <= 0.001;

        // Filtro por estado informativo seleccionado
        if (_filtroEstado == 'pagados' && !alDia) return false;
        if (_filtroEstado == 'deben' && alDia) return false;

        // Filtro por texto de búsqueda
        if (q.isNotEmpty) {
          final nombre = (c['conductor_nombre'] ?? '').toString().toLowerCase();
          final ci = (c['conductor_ci'] ?? '').toString().toLowerCase();
          if (!nombre.contains(q) && !ci.contains(q)) return false;
        }

        return true;
      }).toList();
    });
  }

  void _cambiarFiltroEstado(String nuevoFiltro) {
    setState(() {
      _filtroEstado = nuevoFiltro;
    });
    _filtrar(_busqueda);
  }

  // ---------------------------------------------------------------------------
  // DIÁLOGO: CREAR NUEVA CUOTA (EJ: APOYO ECONÓMICO - BS. 200)
  // ---------------------------------------------------------------------------
  void _dialogoNuevaCuota() {
    final nombreCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    final montoCtrl = TextEditingController(text: '200.00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_card_outlined, color: Color(0xFF1E3A8A)),
            SizedBox(width: 10),
            Text(
              'Crear Nueva Cuota',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E3A8A)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Al crearla, se generará la lista para todos los conductores activos.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Título de la Cuota *',
                  hintText: 'Ej. Apoyo económico, Canastón, etc.',
                  prefixIcon: const Icon(Icons.bookmark_border, color: Color(0xFF1E3A8A), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: motivoCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo de la Cuota',
                  hintText: 'Ej. Apoyo para gastos médicos del chofer...',
                  prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF1E3A8A), size: 20),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto que debe dar cada chofer (Bs.) *',
                  prefixText: 'Bs. ',
                  prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
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
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              final motivo = motivoCtrl.text.trim();
              final monto = double.tryParse(montoCtrl.text.trim()) ?? 0.0;

              if (nombre.isEmpty || monto <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa el título de la cuota y un monto válido.')),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                final nuevoId = await EconomiaRepo.instance.crearNuevoConceptoCuota(
                  nombre: nombre,
                  descripcion: motivo.isNotEmpty ? motivo : null,
                  monto: monto,
                  idUsuario: SesionService.instance.idUsuario ?? 'sistema',
                );
                await _cargarTiposYConductores(idTipoASeleccionar: nuevoId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cuota "$nombre" creada para todos los conductores.'),
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
            child: const Text('Guardar y Asignar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIÁLOGO: EDITAR CUOTA EXISTENTE (TÍTULO, MOTIVO, MONTO)
  // ---------------------------------------------------------------------------
  void _dialogoEditarCuota() {
    if (_tipoSeleccionado == null || _idTipoSeleccionado == null) return;
    final nombreCtrl = TextEditingController(text: _tipoSeleccionado!['nombre']?.toString() ?? '');
    final motivoCtrl = TextEditingController(text: _tipoSeleccionado!['descripcion']?.toString() ?? '');
    final montoCtrl = TextEditingController(
      text: ((_tipoSeleccionado!['monto_sugerido'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A)),
            SizedBox(width: 10),
            Text(
              'Editar Cuota',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E3A8A)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Título de la Cuota *',
                  hintText: 'Ej. Apoyo económico, Canastón, etc.',
                  prefixIcon: const Icon(Icons.bookmark_border, color: Color(0xFF1E3A8A), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: motivoCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo de la Cuota',
                  hintText: 'Ej. Apoyo para gastos médicos del chofer...',
                  prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF1E3A8A), size: 20),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto que debe dar cada chofer (Bs.) *',
                  prefixText: 'Bs. ',
                  prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
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
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              final motivo = motivoCtrl.text.trim();
              final monto = double.tryParse(montoCtrl.text.trim()) ?? 0.0;

              if (nombre.isEmpty || monto <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa el título de la cuota y un monto válido.')),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await EconomiaRepo.instance.actualizarTipoCuota(
                  idTipoCuota: _idTipoSeleccionado!,
                  nombre: nombre,
                  descripcion: motivo.isNotEmpty ? motivo : null,
                  monto: monto,
                );
                await _cargarTiposYConductores(idTipoASeleccionar: _idTipoSeleccionado);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cuota actualizada correctamente.'),
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
            child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ELIMINAR CUOTA SELECCIONADA
  // ---------------------------------------------------------------------------
  void _confirmarEliminarCuotaActual() {
    if (_tipoSeleccionado == null) return;
    final nombre = _tipoSeleccionado!['nombre'] ?? 'esta cuota';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Cuota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('¿Deseas eliminar la cuota "$nombre" y todos sus registros?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await EconomiaRepo.instance.eliminarTipoCuota(_idTipoSeleccionado!);
              _idTipoSeleccionado = null;
              await _cargarTiposYConductores();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cuota eliminada correctamente.')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VACIAR TODAS LAS CUOTAS
  // ---------------------------------------------------------------------------
  void _confirmarVaciarTodo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Borrar Todas las Cuotas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text('¿Estás seguro de borrar todas las cuotas de la lista? Quedará limpio desde cero.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await EconomiaRepo.instance.vaciarTodasLasCuotas();
              _idTipoSeleccionado = null;
              await _cargarTiposYConductores();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Se borraron todas las cuotas.')),
                );
              }
            },
            child: const Text('Borrar Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIÁLOGO RÁPIDO: COBRAR AL CONDUCTOR
  // ---------------------------------------------------------------------------
  void _dialogoCobrar(Map<String, dynamic> c) {
    final nombre = c['conductor_nombre']?.toString() ?? 'Conductor';
    final ci = c['conductor_ci']?.toString() ?? '';
    final falta = (c['monto_falta'] as num).toDouble();
    final pagado = (c['monto_pagado'] as num).toDouble();
    final total = (c['monto_total'] as num).toDouble();
    final cuotaNombre = _tipoSeleccionado?['nombre']?.toString() ?? 'Cuota';

    final montoCobrarCtrl = TextEditingController(text: falta.toStringAsFixed(2));
    String metodo = 'efectivo';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Registrar Cobro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E3A8A))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      AvatarConductor(
                        foto: c['conductor_foto']?.toString(),
                        nombre: nombre,
                        radio: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('CI: $ci', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text('Cuota: $cuotaNombre (Total: Bs. ${total.toStringAsFixed(2)})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Ya pagó: Bs. ${pagado.toStringAsFixed(2)}  •  ', style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    Text('Le falta: Bs. ${falta.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),

                TextField(
                  controller: montoCobrarCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto a Cobrar (Bs.) *',
                    prefixText: 'Bs. ',
                    helperText: 'Puedes cobrar el total o una parte (pago parcial)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: metodo,
                  decoration: InputDecoration(
                    labelText: 'Método de Pago',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'qr', child: Text('Pago con QR')),
                    DropdownMenuItem(value: 'transferencia', child: Text('Transferencia Bancaria')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => metodo = val);
                  },
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
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                final monto = double.tryParse(montoCobrarCtrl.text.trim()) ?? 0.0;
                if (monto <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un monto válido mayor a 0.')),
                  );
                  return;
                }
                if (monto > (falta + 0.01)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('El monto no puede superar lo que falta (Bs. ${falta.toStringAsFixed(2)}).')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  await EconomiaRepo.instance.cobrarAConductor(
                    idConductor: c['id_conductor'].toString(),
                    idTipoCuota: _idTipoSeleccionado!,
                    montoACobrar: monto,
                    metodo: metodo,
                    idUsuario: SesionService.instance.idUsuario ?? 'sistema',
                  );

                  await _cargarTiposYConductores(idTipoASeleccionar: _idTipoSeleccionado);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cobro de Bs. ${monto.toStringAsFixed(2)} guardado exitosamente.'),
                        backgroundColor: const Color(0xFF059669),
                        duration: const Duration(seconds: 2),
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
              child: const Text('Confirmar Cobro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirInformePdf() {
    if (_tiposCuota.isEmpty || _conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cuotas o conductores para generar el informe.')),
      );
      return;
    }

    final nombreCuota = _tipoSeleccionado?['nombre']?.toString() ?? 'Cuota General';
    final montoSugerido = (_tipoSeleccionado?['monto_sugerido'] as num?)?.toDouble() ?? 0.0;

    int cantPagados = 0;
    int cantDeben = 0;
    double totalRecaudado = 0;
    double totalFalta = 0;
    for (final c in _conductores) {
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      totalRecaudado += pagado;
      totalFalta += falta;
      if (falta <= 0.001) {
        cantPagados++;
      } else {
        cantDeben++;
      }
    }

    ReciboPdfService.mostrarVistaPreviaInformeCuotas(
      context,
      tituloCuota: nombreCuota,
      motivoCuota: _tipoSeleccionado?['descripcion']?.toString(),
      montoSugerido: montoSugerido,
      conductores: _conductores,
      totalRecaudado: totalRecaudado,
      totalFalta: totalFalta,
      totalConductores: _conductores.length,
      cantPagados: cantPagados,
      cantDeben: cantDeben,
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    int cantPagados = 0;
    int cantDeben = 0;
    double totalRecaudado = 0;
    double totalFalta = 0;
    for (final c in _conductores) {
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      totalRecaudado += pagado;
      totalFalta += falta;
      if (falta <= 0.001) {
        cantPagados++;
      } else {
        cantDeben++;
      }
    }
    final totalConductores = _conductores.length;
    final totalMeta = totalRecaudado + totalFalta;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Control de Cuotas',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (_tiposCuota.isNotEmpty && _conductores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _abrirInformePdf,
                icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                label: const Text('Informe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            tooltip: 'Recargar',
            onPressed: () => _cargarTiposYConductores(idTipoASeleccionar: _idTipoSeleccionado),
          ),
          if (puedeEditar && _tiposCuota.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1E3A8A)),
              onSelected: (val) {
                if (val == 'informe_pdf') {
                  _abrirInformePdf();
                } else if (val == 'eliminar_actual') {
                  _confirmarEliminarCuotaActual();
                } else if (val == 'borrar_todo') {
                  _confirmarVaciarTodo();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'informe_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Color(0xFF1E3A8A), size: 20),
                      SizedBox(width: 8),
                      Text('Generar Informe (PDF)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar_actual',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Eliminar esta cuota'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'borrar_todo',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Borrar todas las cuotas', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tiposCuota.isEmpty
                  ? _buildEmptyState(puedeEditar)
                  : Column(
                      children: [
                        // 1. INFORMACIÓN DETALLADA DE LA CUOTA ACTIVA
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fila: Título de la Cuota + Botones Editar y Nueva
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.bookmark_rounded, color: Color(0xFF1E3A8A), size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Título de la Cuota',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF64748B),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          if (_tiposCuota.length > 1)
                                            DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                isExpanded: true,
                                                value: _idTipoSeleccionado,
                                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A)),
                                                items: _tiposCuota.map((t) {
                                                  return DropdownMenuItem<String>(
                                                    value: t['id_tipo_cuota'].toString(),
                                                    child: Text(
                                                      t['nombre']?.toString() ?? '',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Color(0xFF1E3A8A),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    _cargarTiposYConductores(idTipoASeleccionar: val);
                                                  }
                                                },
                                              ),
                                            )
                                          else
                                            Text(
                                              _tipoSeleccionado?['nombre']?.toString() ?? 'Cuota General',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (puedeEditar) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          padding: const EdgeInsets.all(7),
                                          minimumSize: const Size(34, 34),
                                        ),
                                        icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF1E3A8A)),
                                        tooltip: 'Editar Cuota',
                                        onPressed: _dialogoEditarCuota,
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: _dialogoNuevaCuota,
                                        icon: const Icon(Icons.add, color: Colors.white, size: 15),
                                        label: const Text(
                                          'Nueva',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                ),

                                // Motivo de la Cuota:
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                                          children: [
                                            const TextSpan(
                                              text: 'Motivo de la Cuota: ',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                            ),
                                            TextSpan(
                                              text: (_tipoSeleccionado?['descripcion'] != null &&
                                                      _tipoSeleccionado!['descripcion'].toString().trim().isNotEmpty)
                                                  ? _tipoSeleccionado!['descripcion'].toString()
                                                  : 'Sin motivo especificado',
                                              style: TextStyle(
                                                color: (_tipoSeleccionado?['descripcion'] != null &&
                                                        _tipoSeleccionado!['descripcion'].toString().trim().isNotEmpty)
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFF94A3B8),
                                                fontStyle: (_tipoSeleccionado?['descripcion'] != null &&
                                                        _tipoSeleccionado!['descripcion'].toString().trim().isNotEmpty)
                                                    ? FontStyle.normal
                                                    : FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Monto que debe dar cada chofer (Bs.)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF059669)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Monto que debe dar cada chofer (Bs.): ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                      Text(
                                        'Bs. ${((_tipoSeleccionado?['monto_sugerido'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. TRES CUADRADOS INFORMATIVOS (YA PAGARON / NO PAGARON / TOTAL CUOTA)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // 1. YA PAGARON (VERDE)
                              Expanded(
                                child: _buildTarjetaInformativa(
                                  titulo: 'Ya Pagaron',
                                  icono: Icons.check_circle_outline,
                                  colorTema: const Color(0xFF059669),
                                  bgTema: const Color(0xFFECFDF5),
                                  borderTema: const Color(0xFFA7F3D0),
                                  filtroKey: 'pagados',
                                  conteoTexto: '$cantPagados de $totalConductores',
                                  subtituloConteo: 'pagaron',
                                  montoPrincipal: 'Bs. ${totalRecaudado.toStringAsFixed(2)}',
                                  etiquetaMonto: 'Total pagado',
                                  esActivo: _filtroEstado == 'pagados',
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 2. NO PAGARON (ROJO)
                              Expanded(
                                child: _buildTarjetaInformativa(
                                  titulo: 'No Pagaron',
                                  icono: Icons.warning_amber_rounded,
                                  colorTema: const Color(0xFFDC2626),
                                  bgTema: const Color(0xFFFEF2F2),
                                  borderTema: const Color(0xFFFECACA),
                                  filtroKey: 'deben',
                                  conteoTexto: '$cantDeben de $totalConductores',
                                  subtituloConteo: 'con deuda',
                                  montoPrincipal: 'Bs. ${totalFalta.toStringAsFixed(2)}',
                                  etiquetaMonto: 'Total que falta',
                                  esActivo: _filtroEstado == 'deben',
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 3. TOTAL GENERAL / CUOTA (AZUL CONTINENTAL)
                              Expanded(
                                child: _buildTarjetaInformativa(
                                  titulo: 'Total Cuota',
                                  icono: Icons.savings_outlined,
                                  colorTema: const Color(0xFF1E3A8A),
                                  bgTema: const Color(0xFFEFF6FF),
                                  borderTema: const Color(0xFFBFDBFE),
                                  filtroKey: 'todos',
                                  conteoTexto: '$totalConductores',
                                  subtituloConteo: 'conductores',
                                  montoPrincipal: 'Bs. ${totalMeta.toStringAsFixed(2)}',
                                  etiquetaMonto: 'Total de todo',
                                  subDetalle: 'Hay: ${totalRecaudado.toStringAsFixed(0)} | Falta: ${totalFalta.toStringAsFixed(0)}',
                                  esActivo: _filtroEstado == 'todos',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 3. BUSCADOR DE CONDUCTOR
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar conductor por nombre o CI...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                              suffixIcon: _busqueda.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filtrar('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onChanged: _filtrar,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 3.1. BARRA DE ESTADO DEL FILTRO SELECCIONADO
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                _filtroEstado == 'pagados'
                                    ? Icons.check_circle_rounded
                                    : _filtroEstado == 'deben'
                                        ? Icons.warning_amber_rounded
                                        : Icons.people_outline,
                                size: 15,
                                color: _filtroEstado == 'pagados'
                                    ? const Color(0xFF059669)
                                    : _filtroEstado == 'deben'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _filtroEstado == 'pagados'
                                      ? 'Mostrando solo los que pagaron (${_conductoresFiltrados.length} de $cantPagados)'
                                      : _filtroEstado == 'deben'
                                          ? 'Mostrando solo los que no pagaron (${_conductoresFiltrados.length} de $cantDeben)'
                                          : 'Mostrando todos los conductores (${_conductoresFiltrados.length} de $totalConductores)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _filtroEstado == 'pagados'
                                        ? const Color(0xFF059669)
                                        : _filtroEstado == 'deben'
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              if (_filtroEstado != 'todos' || _busqueda.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    _searchController.clear();
                                    _busqueda = '';
                                    _cambiarFiltroEstado('todos');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Text(
                                      'Ver todos',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 4. LISTA DE CONDUCTORES
                        Expanded(
                          child: _conductoresFiltrados.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _filtroEstado == 'pagados'
                                              ? Icons.info_outline
                                              : _filtroEstado == 'deben'
                                                  ? Icons.check_circle_outline
                                                  : Icons.people_outline,
                                          size: 54,
                                          color: _filtroEstado == 'deben' ? const Color(0xFF10B981) : Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _busqueda.isNotEmpty
                                              ? 'No se encontraron conductores con "$_busqueda".'
                                              : _filtroEstado == 'pagados'
                                                  ? 'Aún ningún conductor ha pagado esta cuota.'
                                                  : _filtroEstado == 'deben'
                                                      ? '¡Excelente! Todos los conductores están al día.'
                                                      : 'No hay conductores activos encontrados.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        ),
                                        if (_filtroEstado != 'todos' || _busqueda.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          TextButton.icon(
                                            onPressed: () {
                                              _searchController.clear();
                                              _busqueda = '';
                                              _cambiarFiltroEstado('todos');
                                            },
                                            icon: const Icon(Icons.refresh, size: 16),
                                            label: const Text('Ver todos los conductores'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                  itemCount: _conductoresFiltrados.length,
                                  itemBuilder: (ctx, i) {
                                    final c = _conductoresFiltrados[i];
                                    return _buildCardConductorCuota(c, puedeEditar);
                                  },
                                ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool puedeEditar) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.savings_outlined, size: 64, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay cuotas creadas aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea una cuota para ver a los conductores y cobrarles (por ejemplo: Apoyo económico por Bs. 200).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (puedeEditar) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _dialogoNuevaCuota,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Crear Primera Cuota',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardConductorCuota(Map<String, dynamic> c, bool puedeEditar) {
    final nombre = c['conductor_nombre']?.toString() ?? 'Conductor';
    final ci = c['conductor_ci']?.toString() ?? '';
    final pagado = (c['monto_pagado'] as num).toDouble();
    final falta = (c['monto_falta'] as num).toDouble();
    final total = (c['monto_total'] as num).toDouble();
    final bool alDia = falta <= 0.001;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: alDia ? const Color(0xFFA7F3D0) : const Color(0xFFF1F5F9),
          width: alDia ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarConductor(
                foto: c['conductor_foto']?.toString(),
                nombre: nombre,
                radio: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CI: $ci  •  Total Cuota: Bs. ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (alDia)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'AL DÍA',
                    style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              else if (puedeEditar)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _dialogoCobrar(c),
                  icon: const Icon(Icons.payments_outlined, size: 16, color: Colors.white),
                  label: const Text('Cobrar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // BARRA DE PAGADO (VERDE) Y FALTA (ROJO)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      'Pagó: Bs. ${pagado.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: alDia ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      alDia ? 'Completado' : 'Falta: Bs. ${falta.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: alDia ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaInformativa({
    required String titulo,
    required IconData icono,
    required Color colorTema,
    required Color bgTema,
    required Color borderTema,
    required String filtroKey,
    required String conteoTexto,
    required String subtituloConteo,
    required String montoPrincipal,
    required String etiquetaMonto,
    String? subDetalle,
    required bool esActivo,
  }) {
    return InkWell(
      onTap: () => _cambiarFiltroEstado(filtroKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bgTema,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esActivo ? colorTema : borderTema,
            width: esActivo ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (esActivo)
              BoxShadow(
                color: colorTema.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. TÍTULO + ÍCONO + INDICADOR ACTIVO
            Row(
              children: [
                Icon(icono, color: colorTema, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: colorTema,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (esActivo)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorTema,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 8, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // 2. CONTEO DE USUARIOS (ej: 60 de 100)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                conteoTexto,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colorTema,
                ),
              ),
            ),
            Text(
              subtituloConteo,
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w500,
                color: colorTema.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 6),

            // 3. MONTO TOTAL (ej: Bs. 1200.00)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                montoPrincipal,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: colorTema,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subDetalle ?? etiquetaMonto,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: colorTema.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

