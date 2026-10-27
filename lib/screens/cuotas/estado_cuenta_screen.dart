import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/economia_repo.dart';
import '../../services/recibo_pdf_service.dart';
import '../../services/sesion_service.dart';
import '../../widgets/avatar_conductor.dart';
import 'cobrar_screen.dart';

/// Vista E4: Estado de Cuenta del Conductor
///
/// Muestra métricas: Total Debe, Total Pagado y Saldo Pendiente.
/// Pestañas:
/// 1. Deudas (pendientes, parciales, pagadas, anuladas) con opción de cobrar.
/// 2. Pagos realizados (historial con número de recibo e impresión de PDF).
class EstadoCuentaScreen extends StatefulWidget {
  final String? idConductor;

  const EstadoCuentaScreen({super.key, this.idConductor});

  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;
  String? _idConductorEfectivo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Si es conductor, solo ve su propio estado de cuenta
    if (SesionService.instance.esConductor) {
      _idConductorEfectivo = SesionService.instance.idConductor;
    } else {
      _idConductorEfectivo = widget.idConductor;
    }

    _cargarEstadoCuenta();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstadoCuenta() async {
    if (_idConductorEfectivo == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await EconomiaRepo.instance.estadoDeCuenta(_idConductorEfectivo!);
      if (mounted) {
        setState(() {
          _resumen = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estado de cuenta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeCobrar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Estado de Cuenta',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarEstadoCuenta,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resumen == null
              ? const Center(
                  child: Text(
                    'No se pudo encontrar la información del conductor.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : Column(
                  children: [
                    // CABECERA CON DATOS DEL CONDUCTOR Y TARJETAS FINANCIERAS
                    _buildCabeceraResumen(),

                    // TABS DE NAVEGACIÓN
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF2563EB),
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorColor: const Color(0xFF2563EB),
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.receipt_outlined, size: 20),
                            text: 'Deudas / Obligaciones',
                          ),
                          Tab(
                            icon: Icon(Icons.history, size: 20),
                            text: 'Pagos Realizados',
                          ),
                        ],
                      ),
                    ),

                    // CONTENIDO DE LAS PESTAÑAS
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabDeudas(puedeCobrar),
                          _buildTabPagos(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // CABECERA RESUMEN
  // ---------------------------------------------------------------------------
  Widget _buildCabeceraResumen() {
    final conductor = _resumen!['conductor'] as Map<String, dynamic>;
    final totalDebe = (_resumen!['total_debe'] as num).toDouble();
    final totalPagado = (_resumen!['total_pagado'] as num).toDouble();
    final saldoPendiente = (_resumen!['saldo_pendiente'] as num).toDouble();

    final nombre = conductor['nombre']?.toString() ?? 'Conductor';
    final ci = conductor['ci']?.toString() ?? 'S/CI';
    final foto = conductor['foto']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F265C), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarConductor(
                foto: foto,
                nombre: nombre,
                radio: 28,
                fontSize: 14,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CI: $ci • Ficha oficial',
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3 TARJETAS FINANCIERAS
          Row(
            children: [
              _buildTarjetaCabecera(
                titulo: 'TOTAL DEBE',
                monto: totalDebe,
                colorFondo: Colors.white.withValues(alpha: 0.12),
                colorTexto: Colors.white,
              ),
              const SizedBox(width: 8),
              _buildTarjetaCabecera(
                titulo: 'PAGADO',
                monto: totalPagado,
                colorFondo: const Color(0xFF10B981).withValues(alpha: 0.25),
                colorTexto: const Color(0xFFA7F3D0),
              ),
              const SizedBox(width: 8),
              _buildTarjetaCabecera(
                titulo: 'SALDO',
                monto: saldoPendiente,
                colorFondo: saldoPendiente > 0
                    ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                    : const Color(0xFF10B981).withValues(alpha: 0.25),
                colorTexto: saldoPendiente > 0
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFA7F3D0),
                esDestacado: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaCabecera({
    required String titulo,
    required double monto,
    required Color colorFondo,
    required Color colorTexto,
    bool esDestacado = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFCBD5E1),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bs. ${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorTexto,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DEUDAS
  // ---------------------------------------------------------------------------
  Widget _buildTabDeudas(bool puedeCobrar) {
    final cuotas = (_resumen!['cuotas'] as List).cast<Map<String, dynamic>>();

    if (cuotas.isEmpty) {
      return const Center(
        child: Text(
          'No hay deudas u obligaciones registradas.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: cuotas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final c = cuotas[index];
        final tipo = c['tipo_nombre']?.toString() ?? 'Cuota';
        final concepto = c['concepto']?.toString() ?? tipo;
        final monto = (c['monto'] as num).toDouble();
        final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
        final saldo = (c['saldo'] as num?)?.toDouble() ?? (monto - pagado);
        final estado = c['estado']?.toString().toLowerCase() ?? 'pendiente';
        final fecha = c['fecha']?.toString() ?? '';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tipo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
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
              const SizedBox(height: 4),
              Text(
                concepto,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fecha: $fecha',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text(
                    'Saldo: Bs. ${saldo.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: saldo > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              if (puedeCobrar && saldo > 0 && estado != 'anulado') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.monetization_on_outlined, size: 16),
                    label: const Text(
                      'Cobrar esta deuda',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CobrarScreen(
                            idConductorInicial: _idConductorEfectivo,
                            idCuotaInicial: c['id_cuota']?.toString(),
                          ),
                        ),
                      );
                      _cargarEstadoCuenta();
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: HISTORIAL DE PAGOS
  // ---------------------------------------------------------------------------
  Widget _buildTabPagos() {
    final pagos = (_resumen!['pagos'] as List).cast<Map<String, dynamic>>();

    if (pagos.isEmpty) {
      return const Center(
        child: Text(
          'Aún no se han registrado abonos o pagos.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: pagos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final p = pagos[index];
        final nroRecibo = p['nro_recibo']?.toString() ?? 'REC';
        final fecha = p['fecha']?.toString() ?? '';
        final monto = (p['monto'] as num).toDouble();
        final metodo = (p['metodo']?.toString() ?? 'efectivo').toUpperCase();
        final tipo = p['tipo_nombre']?.toString() ?? 'Cuota';
        final cobrador = p['cobrador_nombre']?.toString() ?? 'Hacienda';

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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nroRecibo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '$tipo • $metodo',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    ),
                    Text(
                      '$fecha • Cobrado por: $cobrador',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+ Bs. ${monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      final datosPago = {
                        'nro_recibo': nroRecibo,
                        'fecha': fecha,
                        'monto_pagado': monto,
                        'metodo': metodo,
                        'conductor_nombre': _resumen!['conductor']['nombre'],
                        'conductor_ci': _resumen!['conductor']['ci'],
                        'tipo_nombre': tipo,
                        'concepto': p['concepto'] ?? tipo,
                        'total_cuota': monto,
                        'saldo_restante': 0.0,
                        'cobrador_nombre': cobrador,
                        'observacion': p['observacion'],
                      };
                      ReciboPdfService.mostrarVistaPrevia(context, datosPago);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 12, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text(
                            'Recibo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
