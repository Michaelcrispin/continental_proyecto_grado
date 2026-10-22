import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';
import 'cobrar_screen.dart';
import 'nueva_deuda_screen.dart';

/// Vista E5: Lista de Cuotas con Filtros y Anulación
///
/// Permite al Secretario de Hacienda y Administradores auditar todas las deudas,
/// filtrar por tipo, estado (pendiente/parcial/pagado/anulado), fecha y conductor.
class CuotasListaScreen extends StatefulWidget {
  final String? idConductorFiltro;

  const CuotasListaScreen({super.key, this.idConductorFiltro});

  @override
  State<CuotasListaScreen> createState() => _CuotasListaScreenState();
}

class _CuotasListaScreenState extends State<CuotasListaScreen> {
  List<Map<String, dynamic>> _cuotas = [];
  List<Map<String, dynamic>> _tiposCuota = [];

  String _estadoFiltro = 'todos';
  String _tipoFiltro = 'todos';
  String _busqueda = '';
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;

  final List<String> _estados = const ['todos', 'pendiente', 'parcial', 'pagado', 'anulado'];

  @override
  void initState() {
    super.initState();
    _cargarTiposYCuotas();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTiposYCuotas() async {
    setState(() => _isLoading = true);
    try {
      final tipos = await DatabaseHelper.instance.listar('tipo_cuota');
      final cuotas = await DatabaseHelper.instance.cuotasDetalle(
        idConductor: widget.idConductorFiltro,
        estado: _estadoFiltro,
        idTipoCuota: _tipoFiltro,
        busqueda: _busqueda,
      );

      if (mounted) {
        setState(() {
          _tiposCuota = tipos;
          _cuotas = cuotas;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _anularCuotaDialog(Map<String, dynamic> c) {
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Anular Deuda'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de anular esta cuota de Bs. ${(c['monto'] as num).toStringAsFixed(2)} para ${c['conductor_nombre']}?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivo de la anulación *',
                hintText: 'Ej. Error en la asignación, socio exonerado...',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final motivo = motivoCtrl.text.trim();
              if (motivo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El motivo de anulación es obligatorio.')),
                );
                return;
              }

              Navigator.pop(ctx);
              final idUsuario = SesionService.instance.idUsuario ?? 'superadmin';

              try {
                await EconomiaRepo.instance.anularCuota(
                  idCuota: c['id_cuota'].toString(),
                  motivo: motivo,
                  idUsuario: idUsuario,
                );
                _cargarTiposYCuotas();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cuota anulada correctamente.'),
                      backgroundColor: Color(0xFF10B981),
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
            child: const Text('Confirmar Anulación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeGestionar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );
    final esSuperadmin = SesionService.instance.esSuperadmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Consulta de Cuotas (${_cuotas.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTiposYCuotas,
          ),
        ],
      ),
      body: Column(
        children: [
          // FILTROS SUPERIORES
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                // Buscador
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por conductor, CI o concepto...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _busqueda = '');
                              _cargarTiposYCuotas();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _busqueda = val);
                    _cargarTiposYCuotas();
                  },
                ),
                const SizedBox(height: 10),

                // Filtro horizontal por Estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _estados.map((est) {
                      final esActivo = _estadoFiltro == est;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            est.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: esActivo ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                          selected: esActivo,
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _estadoFiltro = est);
                              _cargarTiposYCuotas();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_tiposCuota.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              'TODOS LOS TIPOS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _tipoFiltro == 'todos' ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                            selected: _tipoFiltro == 'todos',
                            selectedColor: const Color(0xFF10B981),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _tipoFiltro = 'todos');
                                _cargarTiposYCuotas();
                              }
                            },
                          ),
                        ),
                        ..._tiposCuota.map((t) {
                          final idT = t['id_tipo_cuota'].toString();
                          final nom = t['nombre']?.toString() ?? '';
                          final esActivo = _tipoFiltro == idT;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                nom,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: esActivo ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                              selected: esActivo,
                              selectedColor: const Color(0xFF10B981),
                              backgroundColor: const Color(0xFFF1F5F9),
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _tipoFiltro = idT);
                                  _cargarTiposYCuotas();
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // LISTA DE CUOTAS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cuotas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('No se encontraron cuotas con los filtros actuales.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _cuotas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final c = _cuotas[i];
                          final nombre = c['conductor_nombre']?.toString() ?? 'Conductor';
                          final ci = c['conductor_ci']?.toString() ?? 'S/CI';
                          final foto = c['conductor_foto']?.toString();
                          final tipo = c['tipo_nombre']?.toString() ?? 'Cuota';
                          final concepto = c['concepto']?.toString() ?? tipo;
                          final monto = (c['monto'] as num).toDouble();
                          final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
                          final saldo = (c['saldo'] as num?)?.toDouble() ?? (monto - pagado);
                          final estado = c['estado']?.toString().toLowerCase() ?? 'pendiente';
                          final fecha = c['fecha']?.toString() ?? '';
                          final vence = c['fecha_vencimiento']?.toString();

                          Color badgeColor;
                          Color badgeBg;
                          String badgeTexto;

                          switch (estado) {
                            case 'pagado':
                              badgeColor = const Color(0xFF059669);
                              badgeBg = const Color(0xFFECFDF5);
                              badgeTexto = 'PAGADO';
                              break;
                            case 'parcial':
                              badgeColor = const Color(0xFFD97706);
                              badgeBg = const Color(0xFFFEF3C7);
                              badgeTexto = 'PARCIAL';
                              break;
                            case 'anulado':
                              badgeColor = const Color(0xFF64748B);
                              badgeBg = const Color(0xFFF1F5F9);
                              badgeTexto = 'ANULADO';
                              break;
                            case 'pendiente':
                            default:
                              badgeColor = const Color(0xFFDC2626);
                              badgeBg = const Color(0xFFFEF2F2);
                              badgeTexto = 'PENDIENTE';
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AvatarConductor(
                                      foto: foto,
                                      nombre: nombre,
                                      radio: 18,
                                      fontSize: 10,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                                          ),
                                          Text('CI: $ci • Tipo: $tipo', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        badgeTexto,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(concepto, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Emisión: $fecha${vence != null && vence.isNotEmpty ? ' • Vence: $vence' : ''}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Saldo: Bs. ${saldo.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: saldo > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                          ),
                                        ),
                                        Text('Total: Bs. ${monto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ],
                                ),
                                if (puedeGestionar && estado != 'anulado') ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (esSuperadmin && pagado == 0)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          icon: const Icon(Icons.cancel_outlined, size: 15),
                                          label: const Text('Anular', style: TextStyle(fontSize: 11)),
                                          onPressed: () => _anularCuotaDialog(c),
                                        ),
                                      if (saldo > 0) ...[
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                          icon: const Icon(Icons.monetization_on_outlined, size: 15),
                                          label: const Text('Cobrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CobrarScreen(
                                                  idConductorInicial: c['id_conductor']?.toString(),
                                                  idCuotaInicial: c['id_cuota']?.toString(),
                                                ),
                                              ),
                                            );
                                            _cargarTiposYCuotas();
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: puedeGestionar
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Deuda', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaDeudaScreen()),
                );
                if (ok == true) _cargarTiposYCuotas();
              },
            )
          : null,
    );
  }
}
