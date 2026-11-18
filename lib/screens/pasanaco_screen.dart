import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/cronograma_cuotas.dart';
import '../core/formato_moneda.dart';
import '../core/permisos.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';
import 'cuotas/widgets/dialogo_recibo_modal.dart';
import 'cuotas/widgets/selector_conductores_sheet.dart';
import 'cuotas/widgets/selector_dia_mes_dialog.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kVerdeMedio = Color(0xFF047857);
const _kVerdeClaro = Color(0xFF34D399);
const _kTeal = Color(0xFF0D9488);
const _kMintBg = Color(0xFFE8F5EF);
const _kFondo = Color(0xFFF8FAFC);
const _kSlateDark = Color(0xFF0F172A);
const _kSlateMuted = Color(0xFF64748B);

String _formatearFechaCorta(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final limpia = iso.trim().length >= 10
      ? iso.trim().substring(0, 10)
      : iso.trim();
  final partes = limpia.split('-');
  if (partes.length != 3) return limpia;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

String _formatearFechaConDia(DateTime d) {
  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  const meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final diaSem = dias[(d.weekday - 1).clamp(0, 6)];
  final mes = meses[(d.month - 1).clamp(0, 11)];
  return '$diaSem ${d.day.toString().padLeft(2, '0')} $mes ${d.year}';
}

String _formatearIsoConDia(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final limpia = iso.trim().length >= 10
      ? iso.trim().substring(0, 10)
      : iso.trim();
  final dt = DateTime.tryParse(limpia);
  if (dt == null) return _formatearFechaCorta(iso);
  return _formatearFechaConDia(dt);
}

String _fmtIso(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Vista E11: Pasanaku (Gestión de fondos rotativos, sorteo transparente de turnos,
/// doble calendario de pago vs. entrega de pozo, cobros y actas de entrega).
class PasanacoScreen extends StatefulWidget {
  const PasanacoScreen({super.key});

  @override
  State<PasanacoScreen> createState() => _PasanacoScreenState();
}

class _PasanacoScreenState extends State<PasanacoScreen> {
  List<Map<String, dynamic>> _pasanacos = [];
  bool _isLoading = true;
  bool _huboCambios = false;

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

  Future<void> _abrirCrearPasanaco() async {
    final idCreado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CrearPasanacoScreen()),
    );
    if (idCreado != null && idCreado.isNotEmpty && mounted) {
      _huboCambios = true;
      await _cargarPasanacos();
      if (!mounted) return;
      final puedeEditar = Permisos.puedeEditar(
        SesionService.instance.rol,
        Permisos.moduloControlEconomico,
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasanacoDetalleScreen(
            idPasanaco: idCreado,
            puedeEditar: puedeEditar,
          ),
        ),
      );
      _cargarPasanacos();
    }
  }

  Future<void> _confirmarEliminarPasanaco(Map<String, dynamic> p) async {
    final nombre = p['nombre']?.toString() ?? 'Pasanaku';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Eliminar Pasanaku',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar "$nombre" y todas sus rondas y cuotas asociadas? Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _kSlateMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await EconomiaRepo.instance.eliminarPasanaco(
          p['id_pasanaco'].toString(),
        );
        _huboCambios = true;
        await _cargarPasanacos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pasanaku eliminado correctamente.'),
              backgroundColor: _kVerdeOscuro,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _huboCambios);
      },
      child: Scaffold(
        backgroundColor: _kFondo,
        floatingActionButton: puedeEditar
            ? FloatingActionButton.extended(
                onPressed: _abrirCrearPasanaco,
                backgroundColor: _kVerdeOscuro,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Nuevo Pasanaku',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              )
            : null,
        body: Column(
          children: [
            // Cabecera curva verde corporativa
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kVerdeOscuro,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Volver',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context, _huboCambios),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            tooltip: 'Recargar',
                            onPressed: _cargarPasanacos,
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: _kVerdeOscuro,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pasanaku Sindicato',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sorteo transparente de turnos, fechas de pago y entrega de pozo.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kVerdeOscuro),
                    )
                  : _pasanacos.isEmpty
                  ? _buildEmptyState(puedeEditar)
                  : RefreshIndicator(
                      color: _kVerdeOscuro,
                      onRefresh: _cargarPasanacos,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 95),
                        itemCount: _pasanacos.length,
                        itemBuilder: (ctx, i) =>
                            _buildCardPasanaco(_pasanacos[i], puedeEditar),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool puedeEditar) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: _kMintBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.savings_rounded,
                size: 44,
                color: _kVerdeOscuro,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay pasanakus registrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kSlateDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Organiza un fondo rotativo eligiendo a los conductores participantes, separando el día de pago del día de recojo del pozo y sorteando los turnos en vivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: _kSlateMuted,
                height: 1.4,
              ),
            ),
            if (puedeEditar) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _abrirCrearPasanaco,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Crear Primer Pasanaku',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardPasanaco(Map<String, dynamic> p, bool puedeEditar) {
    final idPasanaco = p['id_pasanaco'].toString();
    final nombre = p['nombre']?.toString() ?? 'Pasanaku';
    final aporte = (p['monto_aporte'] as num?)?.toDouble() ?? 0.0;
    final periodicidad = p['periodicidad']?.toString() ?? 'semanal';
    final estado = p['estado']?.toString().toLowerCase() ?? 'activo';
    final sorteoConfirmado =
        ((p['sorteo_confirmado'] as num?)?.toInt() ?? 0) == 1;
    final totalRondas = (p['total_rondas'] as num?)?.toInt() ?? 0;
    final participantes = (p['cantidad_participantes'] as num?)?.toInt() ?? 0;
    final rondasEntregadas = (p['rondas_entregadas'] as num?)?.toInt() ?? 0;
    final diasMargen = (p['dias_margen_entrega'] as num?)?.toInt() ?? 2;
    final pozoEstimado = aporte * participantes;

    final bool sorteoListo = sorteoConfirmado || totalRondas > 0;
    final bool isFinalizado = estado == 'finalizado';

    String badgeTexto;
    Color badgeBg;
    Color badgeColor;
    if (isFinalizado) {
      badgeTexto = 'FINALIZADO';
      badgeBg = const Color(0xFFE2E8F0);
      badgeColor = const Color(0xFF475569);
    } else if (!sorteoListo) {
      badgeTexto = 'FALTA SORTEAR TURNOS';
      badgeBg = const Color(0xFFFEF3C7);
      badgeColor = const Color(0xFFB45309);
    } else {
      badgeTexto = 'ACTIVO · EN CURSO';
      badgeBg = _kMintBg;
      badgeColor = _kVerdeOscuro;
    }

    final double progreso = participantes > 0
        ? (rondasEntregadas / participantes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
            _huboCambios = true;
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isFinalizado
                            ? const Color(0xFFF1F5F9)
                            : _kMintBg,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.savings_rounded,
                        color: isFinalizado ? _kSlateMuted : _kVerdeOscuro,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _kSlateDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badgeTexto,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              Text(
                                '1er pago: ${_formatearFechaCorta(p['fecha_inicio']?.toString())} · Recojo +$diasMargen d',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _kSlateMuted,
                                ),
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
                          formatearBs(aporte),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _kVerdeOscuro,
                          ),
                        ),
                        Text(
                          'por $periodicidad',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kSlateMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _itemResumen(
                        icono: Icons.people_alt_rounded,
                        titulo: 'Participantes',
                        valor: '$participantes choferes',
                      ),
                      _itemResumen(
                        icono: Icons.account_balance_wallet_rounded,
                        titulo: 'Pozo por Turno',
                        valor: formatearBs(pozoEstimado),
                      ),
                      _itemResumen(
                        icono: Icons.published_with_changes_rounded,
                        titulo: 'Entregas',
                        valor: '$rondasEntregadas / $participantes',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _kVerdeOscuro,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      !sorteoListo
                          ? 'Ir al sorteo en vivo'
                          : 'Ver rondas y turnos',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _kVerdeOscuro,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _kVerdeOscuro,
                    ),
                    if (puedeEditar) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _confirmarEliminarPasanaco(p),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemResumen({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        Icon(icono, size: 16, color: _kVerdeOscuro),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 10, color: _kSlateMuted),
            ),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _kSlateDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// PANTALLA DE CREACIÓN DE PASANAKU (CON SEPARACIÓN DE FECHAS Y PREVIEW)
// =============================================================================
class CrearPasanacoScreen extends StatefulWidget {
  const CrearPasanacoScreen({super.key});

  @override
  State<CrearPasanacoScreen> createState() => _CrearPasanacoScreenState();
}

class _CrearPasanacoScreenState extends State<CrearPasanacoScreen> {
  final _nombreCtrl = TextEditingController(
    text: 'Pasanaku Continental ${DateTime.now().year}',
  );
  final _montoCtrl = TextEditingController(text: '200');

  String _periodicidad = 'semanal'; // 'semanal' | 'mensual'
  int _diaSemana = 2; // 1 = Lunes .. 7 = Domingo (Martes por defecto)
  int _diaMes = 15; // Día del mes (1..31)
  bool _esFinDeMes = false;
  late DateTime _fechaPrimerPago;
  static const int _diasMargenEntrega = 1; // Plazo 1 día: entrega al día siguiente

  List<Map<String, dynamic>> _conductoresActivos = [];
  Set<String> _seleccionados = {};
  bool _cargandoConductores = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _fechaPrimerPago = _calcularPrimeraFechaPorRegla();
    _cargarConductores();
  }

  /// Calcula la próxima fecha válida (>= hoy) según la regla elegida:
  /// - Semanal: próximo día de la semana [_diaSemana].
  /// - Mensual: próximo [_diaMes] o fin de mes [_esFinDeMes].
  DateTime _calcularPrimeraFechaPorRegla({DateTime? desde}) {
    final now = DateTime.now();
    final ref = desde ?? DateTime(now.year, now.month, now.day);

    if (_periodicidad == 'semanal') {
      var cursor = ref;
      while (cursor.weekday != _diaSemana) {
        cursor = cursor.add(const Duration(days: 1));
      }
      return cursor;
    }

    var anio = ref.year;
    var mes = ref.month;
    while (true) {
      final ultimoDia = DateTime(anio, mes + 1, 0).day;
      final diaEfectivo = _esFinDeMes
          ? ultimoDia
          : (_diaMes > ultimoDia ? ultimoDia : _diaMes);
      final candidata = DateTime(anio, mes, diaEfectivo);
      if (!candidata.isBefore(ref)) {
        return candidata;
      }
      mes++;
      if (mes > 12) {
        mes = 1;
        anio++;
      }
    }
  }

  Future<void> _abrirSelectorDiaMes() async {
    final res = await SelectorDiaMesDialog.mostrar(
      context,
      diaActual: _diaMes,
      esFinDeMes: _esFinDeMes,
    );
    if (res != null && mounted) {
      setState(() {
        _diaMes = res.dia;
        _esFinDeMes = res.esFinDeMes;
        _fechaPrimerPago = _calcularPrimeraFechaPorRegla();
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    try {
      final lista = await EconomiaRepo.instance.listarConductoresActivos();
      if (mounted) {
        setState(() {
          _conductoresActivos = lista;
          _seleccionados = lista
              .map((c) => c['id_conductor']?.toString())
              .whereType<String>()
              .toSet();
          _cargandoConductores = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoConductores = false);
    }
  }

  DateTime get _fechaPrimeraEntrega =>
      _fechaPrimerPago.add(const Duration(days: _diasMargenEntrega));

  Future<void> _abrirSelectorConductores() async {
    final res = await SelectorConductoresSheet.mostrar(
      context,
      todosConductores: _conductoresActivos,
      idsSeleccionados: _seleccionados,
    );
    if (res != null && mounted) {
      setState(() => _seleccionados = res);
    }
  }

  Future<void> _guardarYContinuarAlSorteo() async {
    final nombre = _nombreCtrl.text.trim();
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre para el Pasanaku.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (monto < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El aporte por participante debe ser mayor a Bs. 0.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_seleccionados.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona al menos 2 conductores que deseen participar en el Pasanaku.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final idPasanaco = await EconomiaRepo.instance.crearPasanaco(
        nombre: nombre,
        montoAporte: monto,
        periodicidad: _periodicidad,
        fechaInicio: _fmtIso(_fechaPrimerPago),
        diasMargenEntrega: _diasMargenEntrega,
        diaMesCobro: _periodicidad == 'mensual' ? _diaMes : null,
        esFinDeMes: _periodicidad == 'mensual' ? _esFinDeMes : false,
        idsConductores: _seleccionados.toList(),
      );
      if (mounted) {
        Navigator.pop(context, idPasanaco);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear Pasanaku: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
    final cant = _seleccionados.length;
    final pozoTotal = monto * cant;

    final int diaSemanaEntrega = (_diaSemana % 7) + 1;
    final String reglaEntrega;
    if (_periodicidad == 'semanal') {
      reglaEntrega = 'Todos los ${CronogramaCuotas.nombreDiaSemana(diaSemanaEntrega)}';
    } else if (_esFinDeMes) {
      reglaEntrega = 'Día 1 del mes siguiente';
    } else if (_diaMes <= 27) {
      reglaEntrega = 'Día ${_diaMes + 1} de cada mes';
    } else {
      reglaEntrega = 'Al día siguiente del cobro';
    }

    return Scaffold(
      backgroundColor: _kFondo,
      body: Column(
        children: [
          // Cabecera verde corporativa
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _kVerdeOscuro,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Configurar Nuevo Pasanaku',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paso 1: Participantes y fechas · Paso 2: Sorteo de turnos en vivo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              children: [
                // 1. DATOS DEL PASANAKU
                _buildSeccionCard(
                  icono: Icons.savings_rounded,
                  titulo: '1. Datos y Monto del Pasanaku',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nombreCtrl,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: _kSlateDark,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nombre del Pasanaku',
                          labelStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: 'Ej. Pasanaku Grupo Continental 2026',
                          prefixIcon: const Icon(
                            Icons.label_important_outline_rounded,
                            color: _kVerdeOscuro,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: _kSlateDark,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Aporte por Participante (en cada ronda)',
                          labelStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixText: 'Bs. ',
                          prefixStyle: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: _kVerdeOscuro,
                          ),
                          prefixIcon: const Icon(
                            Icons.payments_outlined,
                            color: _kVerdeOscuro,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. FRECUENCIA Y DÍA DE PAGO
                _buildSeccionCard(
                  icono: Icons.calendar_today_rounded,
                  titulo: '2. Frecuencia y Día de Pago',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Frecuencia de cada ronda:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _kSlateDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChipPeriodicidad(
                            'semanal',
                            'Semanal',
                            'Cada semana',
                          ),
                          const SizedBox(width: 10),
                          _buildChipPeriodicidad(
                            'mensual',
                            'Mensual',
                            'Una vez al mes',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _periodicidad == 'semanal'
                            ? 'Día de pago semanal:'
                            : 'Día de pago mensual:',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _kSlateDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_periodicidad == 'semanal')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _diaSemana,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _kSlateMuted,
                                size: 22,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kSlateDark,
                              ),
                              items: List.generate(7, (i) {
                                final dia = i + 1;
                                return DropdownMenuItem<int>(
                                  value: dia,
                                  child: Text(
                                    'Todos los ${CronogramaCuotas.nombreDiaSemana(dia)}',
                                  ),
                                );
                              }),
                              onChanged: (nuevo) {
                                if (nuevo != null) {
                                  setState(() {
                                    _diaSemana = nuevo;
                                    _fechaPrimerPago =
                                        _calcularPrimeraFechaPorRegla();
                                  });
                                }
                              },
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: _abrirSelectorDiaMes,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: _kVerdeOscuro,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _esFinDeMes
                                        ? 'Último día del mes (Fin de mes)'
                                        : 'Día $_diaMes de cada mes',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _kSlateDark,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _kSlateMuted,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. PARTICIPANTES VOLUNTARIOS
                _buildSeccionCard(
                  icono: Icons.people_alt_rounded,
                  titulo: '3. Conductores que Participan',
                  subtitulo:
                      'Elige únicamente a los conductores que voluntariamente entrarán al Pasanaku.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botón abrir selector con buscador
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _cargandoConductores
                            ? null
                            : _abrirSelectorConductores,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _kMintBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _kVerdeOscuro.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: _kVerdeOscuro,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$cant de ${_conductoresActivos.length} conductores seleccionados',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: _kVerdeOscuro,
                                      ),
                                    ),
                                    const Text(
                                      'Toca aquí para marcar o desmarcar participantes uno por uno',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: _kSlateMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: _kVerdeOscuro,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 17,
                              color: _kVerdeOscuro,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cada conductor seleccionado aporta su cuota en cada ronda y recibirá el pozo completo una vez cuando le toque su turno.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kSlateMuted,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. RESUMEN AUTOMÁTICO: ENTREGA AL DÍA SIGUIENTE Y POZO FINAL
                _buildSeccionCard(
                  icono: Icons.event_available_rounded,
                  titulo: '4. Pago al Ganador y Resumen del Pozo',
                  subtitulo:
                      'Cambia automático según el paso 2. El plazo de cobro es de 1 día y se entrega al día siguiente.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kMintBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _kVerdeOscuro.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.redeem_rounded,
                                color: _kVerdeOscuro,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ENTREGA AL GANADOR (AL DÍA SIGUIENTE)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: _kVerdeOscuro,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    reglaEntrega,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _kVerdeOscuro,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '1ª entrega: ${_formatearFechaConDia(_fechaPrimeraEntrega)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _kVerdeMedio,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Resumen matemático del Pozo al final
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kVerdeOscuro, _kVerdeMedio],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'POZO A ENTREGAR EN CADA TURNO',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatearBs(pozoTotal),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '$cant participantes × ${formatearBs(monto)} = $cant rondas',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // BOTÓN GUARDAR Y PASAR AL SORTEO
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarYContinuarAlSorteo,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.casino_rounded, color: Colors.white),
                    label: Text(
                      _guardando
                          ? 'Creando Pasanaku...'
                          : 'Crear Pasanaku e Ir al Sorteo de Turnos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kVerdeOscuro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionCard({
    required IconData icono,
    required String titulo,
    String? subtitulo,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kMintBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: _kVerdeOscuro, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: _kSlateDark,
                      ),
                    ),
                    if (subtitulo != null && subtitulo.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _kSlateMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildChipPeriodicidad(String valor, String titulo, String subtitulo) {
    final sel = _periodicidad == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_periodicidad == valor) return;
          setState(() {
            _periodicidad = valor;
            _fechaPrimerPago = _calcularPrimeraFechaPorRegla();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          decoration: BoxDecoration(
            color: sel ? _kMintBg : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? _kVerdeOscuro : const Color(0xFFCBD5E1),
              width: sel ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: sel ? _kVerdeOscuro : _kSlateDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 11,
                  color: sel ? _kVerdeMedio : _kSlateMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PANTALLA DE DETALLE DE PASANAKU: SORTEO TRANSPARENTE, RONDAS Y ENTREGAS
// =============================================================================
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

class _PasanacoDetalleScreenState extends State<PasanacoDetalleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _pasanaco;
  List<Map<String, dynamic>> _participantes = [];
  List<Map<String, dynamic>> _rondas = [];
  List<Map<String, DateTime>> _fechasProyectadas = [];
  bool _isLoading = true;
  bool _primeraCarga = true;

  // Estado del Sorteo en Vivo
  String _modoSorteo = 'ruleta'; // 'ruleta' | 'fichas' | 'random' | 'manual'
  bool _sorteandoTodo = false;
  late AnimationController _wheelCtrl;
  double _anguloActualRuleta = 0.0;
  double _anguloInicioRuleta = 0.0;
  double _anguloDestinoRuleta = 0.0;
  bool _girandoRuleta = false;

  // Estado de Fichas Ocultas (Bolillos)
  final Map<int, int> _turnoPorSlotFicha = {};
  String? _idParticipanteEligiendoFicha;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _wheelCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3500),
        )..addListener(() {
          final t = Curves.easeOutQuart.transform(_wheelCtrl.value);
          setState(() {
            _anguloActualRuleta =
                _anguloInicioRuleta +
                (_anguloDestinoRuleta - _anguloInicioRuleta) * t;
          });
        });
    _cargarTodo();
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _sorteoConfirmado {
    final flag = (_pasanaco?['sorteo_confirmado'] as num?)?.toInt() ?? 0;
    return flag == 1 || _rondas.isNotEmpty;
  }

  List<Map<String, dynamic>> get _participantesSinTurno => _participantes
      .where((p) => ((p['numero_turno'] as num?)?.toInt() ?? 0) <= 0)
      .toList();

  List<Map<String, dynamic>> get _participantesConTurno {
    final lista = _participantes
        .where((p) => ((p['numero_turno'] as num?)?.toInt() ?? 0) > 0)
        .toList();
    lista.sort(
      (a, b) => ((a['numero_turno'] as num?)?.toInt() ?? 0).compareTo(
        (b['numero_turno'] as num?)?.toInt() ?? 0,
      ),
    );
    return lista;
  }

  List<int> get _turnosDisponibles {
    final usados = _participantesConTurno
        .map((p) => (p['numero_turno'] as num).toInt())
        .toSet();
    return [
      for (int i = 1; i <= _participantes.length; i++)
        if (!usados.contains(i)) i,
    ];
  }

  Map<String, dynamic>? get _participanteActivoSorteo {
    final pendientes = _participantesSinTurno;
    if (pendientes.isEmpty) return null;
    return pendientes
            .where(
              (p) =>
                  p['id_participante'].toString() ==
                  _idParticipanteEligiendoFicha,
            )
            .firstOrNull ??
        pendientes.first;
  }

  Future<void> _cargarTodo() async {
    setState(() => _isLoading = true);
    try {
      final p = await EconomiaRepo.instance.obtenerPasanacoPorId(
        widget.idPasanaco,
      );
      final parts = await EconomiaRepo.instance.participantesPasanaco(
        widget.idPasanaco,
      );
      final ronds = await EconomiaRepo.instance.rondasDePasanaco(
        widget.idPasanaco,
      );

      final fechaBase =
          DateTime.tryParse(p?['fecha_inicio']?.toString() ?? '') ??
          DateTime.now();
      final diasMargen = (p?['dias_margen_entrega'] as num?)?.toInt() ?? 2;
      final periodicidad = p?['periodicidad']?.toString() ?? 'semanal';

      final fechas = EconomiaRepo.calcularFechasRondasPasanaco(
        fechaPrimerPago: fechaBase,
        diasMargenEntrega: diasMargen,
        periodicidad: periodicidad,
        totalRondas: parts.length,
        diaMesObjetivo: (p?['dia_mes_cobro'] as num?)?.toInt(),
        esFinDeMes: (p?['es_fin_de_mes'] as num?)?.toInt() == 1,
      );

      if (mounted) {
        setState(() {
          _pasanaco = p;
          _participantes = parts;
          _rondas = ronds;
          _fechasProyectadas = fechas;
          _isLoading = false;
          _sincronizarBolillosOcultos();
          if (_primeraCarga) {
            _primeraCarga = false;
            // Si aún no se confirmó el sorteo, mostrar primero la pestaña de Sorteo (índice 0)
            // Si ya está confirmado, mostrar la pestaña de Rondas y Pagos (índice 1)
            _tabController.index = _sorteoConfirmado ? 1 : 0;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sincronizarBolillosOcultos() {
    final n = _participantes.length;
    final rng = math.Random.secure();
    final usados = _participantesConTurno
        .map((p) => (p['numero_turno'] as num).toInt())
        .toSet();

    // Limpiar slots que ya no corresponden a un turno asignado
    _turnoPorSlotFicha.removeWhere(
      (slot, turno) => slot < 0 || slot >= n || !usados.contains(turno),
    );

    // Ubicar en posiciones aleatorias turnos ya asignados sin slot previo
    final turnosYaMapeados = _turnoPorSlotFicha.values.toSet();
    final libres = [
      for (int i = 0; i < n; i++)
        if (!_turnoPorSlotFicha.containsKey(i)) i,
    ]..shuffle(rng);
    int posLibre = 0;
    for (final turno in usados) {
      if (!turnosYaMapeados.contains(turno) && posLibre < libres.length) {
        _turnoPorSlotFicha[libres[posLibre++]] = turno;
      }
    }

    final pendientes = _participantesSinTurno;
    if (pendientes.isNotEmpty) {
      final existe = pendientes.any(
        (p) => p['id_participante'].toString() == _idParticipanteEligiendoFicha,
      );
      if (!existe) {
        final elegidoAlAzar = pendientes[rng.nextInt(pendientes.length)];
        _idParticipanteEligiendoFicha = elegidoAlAzar['id_participante']
            .toString();
      }
    } else {
      _idParticipanteEligiendoFicha = null;
    }
  }

  // ---------------------------------------------------------------------------
  // DINÁMICA 1: GIRAR LA RULETA VISUAL EN VIVO
  // ---------------------------------------------------------------------------
  Future<void> _girarRuleta() async {
    if (_girandoRuleta) return;
    final candidatos = _participantesSinTurno;
    final turnosDisponibles = _turnosDisponibles;
    if (candidatos.isEmpty || turnosDisponibles.isEmpty) return;

    final choferActual = _participanteActivoSorteo!;

    // Si solo queda 1 turno disponible para el último conductor, asignarlo directamente
    if (turnosDisponibles.length == 1 || candidatos.length == 1) {
      final turnoFinal = turnosDisponibles.first;
      await EconomiaRepo.instance.asignarTurnoParticipantePasanaco(
        idParticipante: choferActual['id_participante'].toString(),
        numeroTurno: turnoFinal,
      );
      await _cargarTodo();
      if (mounted) {
        _mostrarDialogoGanadorTurno(choferActual, turnoFinal);
      }
      return;
    }

    final rng = math.Random.secure();
    final indiceElegido = rng.nextInt(turnosDisponibles.length);
    final turnoGanado = turnosDisponibles[indiceElegido];

    final sliceAngle = (2 * math.pi) / turnosDisponibles.length;
    // En nuestro CustomPainter, la flecha indicadora está arriba (-pi/2).
    // Para que el segmento `indiceElegido` quede exactamente bajo la flecha (-pi/2):
    // angulo + (indiceElegido + 0.5) * sliceAngle = -pi/2 (mod 2*pi)
    final offsetDentroDeSlice = (rng.nextDouble() * 0.5 + 0.25) * sliceAngle;
    final anguloMetaMod =
        (-math.pi / 2) - (indiceElegido * sliceAngle) - offsetDentroDeSlice;

    final vueltasExtra = (6 + rng.nextInt(3)) * 2 * math.pi;
    final baseNormalizada =
        _anguloActualRuleta - (_anguloActualRuleta % (2 * math.pi));

    setState(() {
      _girandoRuleta = true;
      _anguloInicioRuleta = _anguloActualRuleta;
      _anguloDestinoRuleta = baseNormalizada + vueltasExtra + anguloMetaMod;
    });

    await _wheelCtrl.forward(from: 0.0);

    await EconomiaRepo.instance.asignarTurnoParticipantePasanaco(
      idParticipante: choferActual['id_participante'].toString(),
      numeroTurno: turnoGanado,
    );

    if (!mounted) return;
    setState(() => _girandoRuleta = false);
    await _cargarTodo();

    // Si tras este giro solo queda 1 último conductor sin turno, asignarle el último turno automáticamente
    if (_participantesSinTurno.length == 1 && _turnosDisponibles.length == 1) {
      final ultimoRestante = _participantesSinTurno.first;
      final ultimoTurno = _turnosDisponibles.first;
      await EconomiaRepo.instance.asignarTurnoParticipantePasanaco(
        idParticipante: ultimoRestante['id_participante'].toString(),
        numeroTurno: ultimoTurno,
      );
      await _cargarTodo();
    }

    if (mounted) {
      _mostrarDialogoGanadorTurno(choferActual, turnoGanado);
    }
  }

  // ---------------------------------------------------------------------------
  // DINÁMICA 2: DESTAPAR FICHA OCULTA (EL CHOFER TOCA CON SU DEDO)
  // ---------------------------------------------------------------------------
  Future<void> _destaparFichaOculta(int slotIdx) async {
    if (_turnoPorSlotFicha.containsKey(slotIdx)) return;
    final chofer = _participanteActivoSorteo;
    final disponibles = _turnosDisponibles;
    if (chofer == null || disponibles.isEmpty) return;

    final rng = math.Random.secure();
    final turnoGanado = disponibles[rng.nextInt(disponibles.length)];
    _turnoPorSlotFicha[slotIdx] = turnoGanado;

    await EconomiaRepo.instance.asignarTurnoParticipantePasanaco(
      idParticipante: chofer['id_participante'].toString(),
      numeroTurno: turnoGanado,
    );
    await _cargarTodo();

    if (_participantesSinTurno.length == 1 && _turnosDisponibles.length == 1) {
      final ultimoRestante = _participantesSinTurno.first;
      final ultimoTurno = _turnosDisponibles.first;
      await EconomiaRepo.instance.asignarTurnoParticipantePasanaco(
        idParticipante: ultimoRestante['id_participante'].toString(),
        numeroTurno: ultimoTurno,
      );
      await _cargarTodo();
    }

    if (mounted) {
      _mostrarDialogoGanadorTurno(chofer, turnoGanado);
    }
  }

  // ---------------------------------------------------------------------------
  // DINÁMICA 4: SORTEO RÁPIDO AUTOMÁTICO (UN SOLO BOTÓN TODO AL AZAR)
  // ---------------------------------------------------------------------------
  Future<void> _sortearTodosAleatoriamente() async {
    if (_sorteandoTodo) return;
    final pendientes = List<Map<String, dynamic>>.from(_participantesSinTurno);
    final disponibles = List<int>.from(_turnosDisponibles);
    if (pendientes.isEmpty || disponibles.isEmpty) return;

    setState(() => _sorteandoTodo = true);
    try {
      final rng = math.Random.secure();
      pendientes.shuffle(rng);
      disponibles.shuffle(rng);

      final cantidad = math.min(pendientes.length, disponibles.length);
      for (int i = 0; i < cantidad; i++) {
        await EconomiaRepo.instance.asignarTurnoParticipantePasanaco(
          idParticipante: pendientes[i]['id_participante'].toString(),
          numeroTurno: disponibles[i],
        );
      }
      _turnoPorSlotFicha.clear();
      await _cargarTodo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Listo! Todos los turnos se sortearon aleatoriamente.',
            ),
            backgroundColor: _kVerdeOscuro,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sorteandoTodo = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DINÁMICA 3: ASIGNACIÓN MANUAL (SORTEO EN REUNIÓN CON PAPELITOS)
  // ---------------------------------------------------------------------------
  void _dialogoAsignarTurnoManual(Map<String, dynamic> participante) {
    final total = _participantes.length;
    final mapaOcupados = <int, String>{};
    for (final p in _participantesConTurno) {
      final t = (p['numero_turno'] as num?)?.toInt() ?? 0;
      if (t > 0) {
        mapaOcupados[t] = p['conductor_nombre']?.toString() ?? '';
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asignar turno a ${participante['conductor_nombre']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kSlateDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecciona el número de turno que sacó el conductor:',
              style: TextStyle(fontSize: 12.5, color: _kSlateMuted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(total, (i) {
                final numTurno = i + 1;
                final ocupadoPor = mapaOcupados[numTurno];
                final esActual =
                    ((participante['numero_turno'] as num?)?.toInt() ?? 0) ==
                    numTurno;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    Navigator.pop(ctx);
                    // Si otro tenía ese turno, intercambiarlo o liberarlo
                    if (ocupadoPor != null && !esActual) {
                      final otro = _participantes.firstWhere(
                        (x) =>
                            ((x['numero_turno'] as num?)?.toInt() ?? 0) ==
                            numTurno,
                      );
                      final turnoAnterior =
                          (participante['numero_turno'] as num?)?.toInt() ?? 0;
                      await EconomiaRepo.instance
                          .asignarTurnoParticipantePasanaco(
                            idParticipante: otro['id_participante'].toString(),
                            numeroTurno: turnoAnterior,
                          );
                    }
                    await EconomiaRepo.instance
                        .asignarTurnoParticipantePasanaco(
                          idParticipante: participante['id_participante']
                              .toString(),
                          numeroTurno: numTurno,
                        );
                    _cargarTodo();
                  },
                  child: Container(
                    width: 68,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: esActual
                          ? _kVerdeOscuro
                          : (ocupadoPor != null
                                ? const Color(0xFFF1F5F9)
                                : _kMintBg),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: esActual
                            ? _kVerdeOscuro
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '#$numTurno',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: esActual ? Colors.white : _kVerdeOscuro,
                          ),
                        ),
                        Text(
                          ocupadoPor != null ? 'Ocupado' : 'Libre',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: esActual ? Colors.white70 : _kSlateMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoGanadorTurno(
    Map<String, dynamic> participante,
    int numeroTurno,
  ) {
    final aporte = (_pasanaco?['monto_aporte'] as num?)?.toDouble() ?? 0.0;
    final pozo = aporte * _participantes.length;
    final fechas =
        (numeroTurno >= 1 && numeroTurno <= _fechasProyectadas.length)
        ? _fechasProyectadas[numeroTurno - 1]
        : null;
    final fPagoStr = fechas != null
        ? _formatearFechaConDia(fechas['fecha_limite_pago']!)
        : '—';
    final fRecojoStr = fechas != null
        ? _formatearFechaConDia(fechas['fecha_entrega_programada']!)
        : '—';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kVerdeOscuro, _kVerdeMedio],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _kVerdeClaro,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '¡TURNO ASIGNADO!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TURNO #$numeroTurno',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                      letterSpacing: 0.8,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AvatarConductor(
              nombre: participante['conductor_nombre']?.toString() ?? '',
              foto: participante['conductor_foto']?.toString(),
              radio: 32,
            ),
            const SizedBox(height: 12),
            Text(
              participante['conductor_nombre']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _kSlateDark,
              ),
            ),
            Text(
              'CI: ${participante['conductor_ci']} · Grupo ${participante['conductor_grupo'] ?? '101'}',
              style: const TextStyle(fontSize: 12.5, color: _kSlateMuted),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    'Pozo a recibir: ${formatearBs(pozo)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _kVerdeOscuro,
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Aportes se pagan hasta:',
                        style: TextStyle(fontSize: 11.5, color: _kSlateMuted),
                      ),
                      Text(
                        fPagoStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kSlateDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Día que recoge su pozo:',
                        style: TextStyle(fontSize: 11.5, color: _kSlateMuted),
                      ),
                      Text(
                        fRecojoStr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _kVerdeOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarReiniciarSorteo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reiniciar Sorteo de Turnos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Se limpiarán los turnos asignados hasta el momento para volver a realizar el sorteo desde el Turno #1.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeOscuro,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, reiniciar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await EconomiaRepo.instance.reiniciarSorteoPasanaco(widget.idPasanaco);
      _turnoPorSlotFicha.clear();
      _idParticipanteEligiendoFicha = null;
      await _cargarTodo();
    }
  }

  Future<void> _confirmarActaDeSorteo() async {
    if (_participantesSinTurno.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aún faltan ${_participantesSinTurno.length} participante(s) por recibir su turno.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: _kVerdeOscuro),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirmar y Cerrar Acta de Sorteo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Al confirmar el sorteo:\n\n'
          '1. El orden de los ${_participantes.length} turnos quedará bloqueado oficialmente para transparencia de todos los conductores.\n'
          '2. Se activarán automáticamente las ${_participantes.length} rondas con su Fecha Límite de Pago y su Fecha de Entrega del Pozo.',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Revisar antes',
              style: TextStyle(color: _kSlateMuted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeOscuro,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            label: const Text('Confirmar y Activar Rondas'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await EconomiaRepo.instance.confirmarSorteoYGenerarCronogramaPasanaco(
          idPasanaco: widget.idPasanaco,
          metodoSorteo: _modoSorteo,
          idUsuario: SesionService.instance.idUsuario ?? 'sistema',
        );
        await _cargarTodo();
        if (mounted) {
          _tabController.index = 1;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sorteo confirmado. ¡Rondas y pagos activados!',
              ),
              backgroundColor: _kVerdeOscuro,
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
    }
  }

  // ---------------------------------------------------------------------------
  // COBRO DE APORTES DENTRO DE LA RONDA (CON RECIBO OFICIAL VERDE)
  // ---------------------------------------------------------------------------
  void _abrirSheetAportesRonda(Map<String, dynamic> ronda) async {
    final idRonda = ronda['id_ronda'].toString();
    final nroRonda = ronda['numero_ronda']?.toString() ?? '1';
    final fPagoStr = _formatearIsoConDia(ronda['fecha_limite']?.toString());
    final fEntregaStr = _formatearIsoConDia(
      ronda['fecha_entrega_programada']?.toString(),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AportesRondaSheet(
        idRonda: idRonda,
        nroRonda: nroRonda,
        beneficiarioNombre: ronda['beneficiario_nombre']?.toString() ?? '',
        fechaLimitePago: fPagoStr,
        fechaEntregaPozo: fEntregaStr,
        montoPozo: (ronda['monto_total'] as num?)?.toDouble() ?? 0.0,
        puedeEditar: widget.puedeEditar,
        onCambio: _cargarTodo,
      ),
    );
    _cargarTodo();
  }

  // ---------------------------------------------------------------------------
  // ENTREGA DEL POZO AL BENEFICIARIO DE LA RONDA
  // ---------------------------------------------------------------------------
  void _confirmarEntregarPozoRonda(Map<String, dynamic> ronda) {
    final total = (ronda['monto_total'] as num?)?.toDouble() ?? 0.0;
    final recaudado = (ronda['total_recaudado'] as num?)?.toDouble() ?? 0.0;
    final pagados = (ronda['aportes_pagados'] as num?)?.toInt() ?? 0;
    final esperados = (ronda['total_aportes_esperados'] as num?)?.toInt() ?? 0;
    final beneficiario = ronda['beneficiario_nombre']?.toString() ?? '';
    final nroRonda = ronda['numero_ronda']?.toString() ?? '1';
    final faltaRecaudar = (total - recaudado).clamp(0.0, double.infinity);
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.redeem_rounded, color: _kVerdeOscuro),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Entregar Pozo · Ronda #$nroRonda',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
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
                  color: _kMintBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    AvatarConductor(
                      nombre: beneficiario,
                      foto: ronda['beneficiario_foto']?.toString(),
                      radio: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conductor que recoge el pozo:',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kVerdeOscuro,
                            ),
                          ),
                          Text(
                            beneficiario,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: _kSlateDark,
                            ),
                          ),
                          Text(
                            'Pozo Total: ${formatearBs(total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: _kVerdeOscuro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (faltaRecaudar > 0.01)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB45309),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Atención: Se han cobrado $pagados de $esperados aportes (${formatearBs(recaudado)}). Aún falta recaudar ${formatearBs(faltaRecaudar)}.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kMintBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _kVerdeOscuro,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los $esperados participantes pagaron su cuota (${formatearBs(recaudado)} completos).',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kVerdeOscuro,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                decoration: InputDecoration(
                  labelText: 'Observación de entrega (opcional)',
                  hintText: 'Ej. Entregado en efectivo en parada Villadela',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _kSlateMuted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeOscuro,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await EconomiaRepo.instance.entregarRondaPasanaco(
                  ronda['id_ronda'].toString(),
                  observacion: obsCtrl.text.trim(),
                );
                await _cargarTodo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pozo de ${formatearBs(total)} entregado a $beneficiario.',
                      ),
                      backgroundColor: _kVerdeOscuro,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Confirmar Entrega del Pozo'),
          ),
        ],
      ),
    );
  }

  void _mostrarActaEntregaPozo(Map<String, dynamic> ronda) {
    final total = (ronda['monto_total'] as num?)?.toDouble() ?? 0.0;
    final beneficiario = ronda['beneficiario_nombre']?.toString() ?? '';
    final ci = ronda['beneficiario_ci']?.toString() ?? '';
    final nroRonda = ronda['numero_ronda']?.toString() ?? '1';
    final fEntrega = _formatearIsoConDia(ronda['fecha_entrega']?.toString());
    final obs = ronda['observacion_entrega']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.all(22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: _kMintBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: _kVerdeOscuro,
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ACTA DE ENTREGA DE POZO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _kVerdeOscuro,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${_pasanaco?['nombre'] ?? 'Pasanaku'} · Ronda #$nroRonda',
              style: const TextStyle(fontSize: 12, color: _kSlateMuted),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filaActa('Beneficiario:', beneficiario),
                  const SizedBox(height: 6),
                  _filaActa('Cédula (CI):', ci),
                  const SizedBox(height: 6),
                  _filaActa('Turno / Ronda:', 'Turno #$nroRonda'),
                  const SizedBox(height: 6),
                  _filaActa('Monto Entregado:', formatearBs(total)),
                  const SizedBox(height: 6),
                  _filaActa('Fecha de Entrega:', fEntrega),
                  if (obs != null && obs.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _filaActa('Observación:', obs),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaActa(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kSlateMuted)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _kSlateDark,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _pasanaco?['nombre']?.toString() ?? 'Detalle del Pasanaku';
    final aporte = (_pasanaco?['monto_aporte'] as num?)?.toDouble() ?? 0.0;
    final periodicidad = _pasanaco?['periodicidad']?.toString() ?? 'semanal';
    final diasMargen =
        (_pasanaco?['dias_margen_entrega'] as num?)?.toInt() ?? 2;
    final pozoTotal = aporte * _participantes.length;
    final entregadas = _rondas
        .where(
          (r) => (r['estado']?.toString().toLowerCase() ?? '') == 'entregada',
        )
        .length;

    final esSoloSorteo = !_sorteoConfirmado;

    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              esSoloSorteo ? 'Sorteo de Turnos' : nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            if (esSoloSorteo)
              Text(
                '$nombre · ${_participantesConTurno.length}/${_participantes.length} sorteados',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: _kVerdeOscuro,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _cargarTodo,
          ),
        ],
        bottom: esSoloSorteo
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3.5,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(
                      Icons.format_list_numbered_rounded,
                      size: 18,
                    ),
                    text: 'Orden de Turnos (${_participantes.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    text: 'Rondas y Pagos ($entregadas/${_participantes.length})',
                  ),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kVerdeOscuro))
          : esSoloSorteo
              ? _buildTabSorteoYTurnos()
              : Column(
                  children: [
                    // Resumen superior
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pozo por Turno',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _kSlateMuted,
                                ),
                              ),
                              Text(
                                formatearBs(pozoTotal),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: _kVerdeOscuro,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Aporte ($periodicidad)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _kSlateMuted,
                                ),
                              ),
                              Text(
                                formatearBs(aporte),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _kSlateDark,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Margen Entrega',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _kSlateMuted,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _kMintBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+$diasMargen día(s) tras pago',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _kVerdeOscuro,
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
                          _buildTabSorteoYTurnos(),
                          _buildTabRondasYPagos(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ===========================================================================
  // PESTAÑA 1: SORTEO EN VIVO (RULETA / FICHAS OCULTAS / MANUAL) Y TURNOS
  // ===========================================================================
  Widget _buildTabSorteoYTurnos() {
    if (_sorteoConfirmado) {
      return _buildListaTurnosConfirmados();
    }

    final pendientes = _participantesSinTurno;
    final turnosDisponibles = _turnosDisponibles;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Selector de modalidad de sorteo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: _kVerdeOscuro, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sorteo Transparente en Vivo (Sin Sospechas)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: _kSlateDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige cómo sortear los turnos frente a los conductores participantes:',
                style: TextStyle(fontSize: 12, color: _kSlateMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBotonModoSorteo(
                    keyModo: 'ruleta',
                    icono: Icons.pie_chart_rounded,
                    titulo: 'Ruleta Visual',
                  ),
                  const SizedBox(width: 8),
                  _buildBotonModoSorteo(
                    keyModo: 'fichas',
                    icono: Icons.touch_app_rounded,
                    titulo: 'Fichas Ocultas',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBotonModoSorteo(
                    keyModo: 'random',
                    icono: Icons.shuffle_rounded,
                    titulo: 'Al Azar (Todo)',
                  ),
                  const SizedBox(width: 8),
                  _buildBotonModoSorteo(
                    keyModo: 'manual',
                    icono: Icons.edit_note_rounded,
                    titulo: 'Papelitos / Manual',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Si ya todos tienen turno pero aún no confirmaron el acta
        if (pendientes.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kMintBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kVerdeOscuro, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _kVerdeOscuro,
                  size: 42,
                ),
                const SizedBox(height: 8),
                const Text(
                  '¡Todos los turnos han sido sorteados!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _kVerdeOscuro,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Revisa la tabla inferior con las fechas de pago y recojo de cada turno y confirma el Acta de Sorteo para activar las rondas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: _kSlateDark),
                ),
                if (widget.puedeEditar) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _confirmarActaDeSorteo,
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Siguiente: Ir a Rondas y Pagos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kVerdeOscuro,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _confirmarReiniciarSorteo,
                    icon: const Icon(
                      Icons.restart_alt_rounded,
                      size: 18,
                      color: _kSlateMuted,
                    ),
                    label: const Text(
                      'Volver a sortear desde cero',
                      style: TextStyle(color: _kSlateMuted, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          )
        else if (_modoSorteo == 'ruleta')
          _buildWidgetRuletaEnVivo(pendientes, turnosDisponibles)
        else if (_modoSorteo == 'fichas')
          _buildWidgetFichasOcultas(pendientes)
        else if (_modoSorteo == 'random')
          _buildWidgetSorteoRapidoRandom(pendientes, turnosDisponibles)
        else
          _buildWidgetInstruccionManual(),

        const SizedBox(height: 18),

        // Tabla en tiempo real de los turnos y sus fechas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Tabla de Turnos y Fechas de Recojo',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: _kSlateDark,
                ),
              ),
            ),
            if (_participantesConTurno.isNotEmpty && widget.puedeEditar)
              TextButton.icon(
                onPressed: _confirmarReiniciarSorteo,
                icon: const Icon(
                  Icons.restart_alt_rounded,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text(
                  'Reiniciar',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_participantes.length, (i) {
          final numTurno = i + 1;
          final asignado = _participantes
              .where(
                (p) => ((p['numero_turno'] as num?)?.toInt() ?? 0) == numTurno,
              )
              .firstOrNull;
          final fechas = i < _fechasProyectadas.length
              ? _fechasProyectadas[i]
              : null;
          final fPago = fechas != null
              ? _formatearFechaConDia(fechas['fecha_limite_pago']!)
              : '—';
          final fRecojo = fechas != null
              ? _formatearFechaConDia(fechas['fecha_entrega_programada']!)
              : '—';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: asignado != null
                    ? _kVerdeOscuro.withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: asignado != null
                        ? _kVerdeOscuro
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$numTurno',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                      color: asignado != null ? Colors.white : _kSlateMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asignado != null
                            ? (asignado['conductor_nombre']?.toString() ?? '')
                            : 'Esperando sorteo...',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: asignado != null ? _kSlateDark : _kSlateMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pagan hasta: $fPago',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _kSlateMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recoge el pozo: $fRecojo',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _kVerdeOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.puedeEditar &&
                    _modoSorteo == 'manual' &&
                    asignado != null)
                  IconButton(
                    icon: const Icon(
                      Icons.swap_vert_rounded,
                      color: _kVerdeOscuro,
                    ),
                    onPressed: () => _dialogoAsignarTurnoManual(asignado),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBotonModoSorteo({
    required String keyModo,
    required IconData icono,
    required String titulo,
  }) {
    final sel = _modoSorteo == keyModo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modoSorteo = keyModo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: sel ? _kVerdeOscuro : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? _kVerdeOscuro : const Color(0xFFCBD5E1),
            ),
          ),
          child: Column(
            children: [
              Icon(icono, size: 20, color: sel ? Colors.white : _kVerdeOscuro),
              const SizedBox(height: 4),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: sel ? Colors.white : _kSlateDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorConductorPendiente({
    required List<Map<String, dynamic>> pendientes,
    required Map<String, dynamic>? choferActual,
    required String etiqueta,
    bool bloqueado = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kMintBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _kVerdeOscuro.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              if (choferActual != null) ...[
                AvatarConductor(
                  nombre: choferActual['conductor_nombre']?.toString() ?? '',
                  foto: choferActual['conductor_foto']?.toString(),
                  radio: 20,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etiqueta,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kVerdeOscuro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      choferActual?['conductor_nombre']?.toString() ??
                          'Selecciona conductor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _kSlateDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (pendientes.length > 1) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pendientes.map((p) {
                final idP = p['id_participante'].toString();
                final sel = idP == choferActual?['id_participante'].toString();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      p['conductor_nombre']?.toString().split(' ').first ?? '',
                    ),
                    selected: sel,
                    selectedColor: _kVerdeOscuro,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : _kSlateDark,
                    ),
                    onSelected: bloqueado
                        ? null
                        : (_) => setState(
                              () => _idParticipanteEligiendoFicha = idP,
                            ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // WIDGET DE LA RULETA VISUAL ANIMADA (MUESTRA TURNOS DISPONIBLES 1, 2, 3...)
  Widget _buildWidgetRuletaEnVivo(
    List<Map<String, dynamic>> candidatos,
    List<int> turnosDisponibles,
  ) {
    final choferActual = _participanteActivoSorteo ?? candidatos.firstOrNull;
    final nombreCompleto =
        choferActual?['conductor_nombre']?.toString() ?? 'Conductor';
    final primerNombre = nombreCompleto.trim().split(RegExp(r'\s+')).first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _kMintBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'QUEDAN ${turnosDisponibles.length} DE ${_participantes.length} TURNOS POR SORTEAR',
              style: const TextStyle(
                color: _kVerdeOscuro,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cada conductor toca "Girar Ruleta" para sacar su turno',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kSlateMuted,
            ),
          ),
          const SizedBox(height: 14),

          // Flecha indicadora superior + Ruleta de turnos disponibles
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: 265,
                  height: 265,
                  child: CustomPaint(
                    painter: _RuletaSorteoPainter(
                      turnosDisponibles: turnosDisponibles,
                      anguloRotacion: _anguloActualRuleta,
                    ),
                  ),
                ),
              ),
              // Puntero superior fijo
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Conductor en turno justo debajo de la ruleta
          _buildSelectorConductorPendiente(
            pendientes: candidatos,
            choferActual: choferActual,
            etiqueta: 'Conductor que gira la ruleta ahora:',
            bloqueado: _girandoRuleta,
          ),

          const SizedBox(height: 14),

          if (widget.puedeEditar)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _girandoRuleta ? null : _girarRuleta,
                icon: Icon(
                  _girandoRuleta
                      ? Icons.autorenew_rounded
                      : Icons.casino_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _girandoRuleta
                      ? 'Girando la ruleta para $primerNombre...'
                      : (turnosDisponibles.length == 1
                            ? 'Asignar Último Turno (#${turnosDisponibles.first}) a $primerNombre'
                            : 'GIRAR RULETA · $primerNombre'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // WIDGET DE FICHAS OCULTAS (EL CHOFER TOCA SU PROPIA FICHA)
  Widget _buildWidgetFichasOcultas(List<Map<String, dynamic>> pendientes) {
    final mapaPorTurno = <int, Map<String, dynamic>>{};
    for (final p in _participantesConTurno) {
      mapaPorTurno[(p['numero_turno'] as num).toInt()] = p;
    }

    final choferActual = _participanteActivoSorteo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectorConductorPendiente(
            pendientes: pendientes,
            choferActual: choferActual,
            etiqueta: 'Conductor elegido al azar para destapar:',
          ),

          const SizedBox(height: 12),
          const Text(
            'Cada ficha oculta un turno mezclado al azar. Toca cualquiera (?) para descubrir el turno:',
            style: TextStyle(fontSize: 12.5, color: _kSlateMuted),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _participantes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (ctx, idx) {
              final numDescubierto = _turnoPorSlotFicha[idx];
              final yaAbierta = numDescubierto != null;
              final dueno = yaAbierta ? mapaPorTurno[numDescubierto] : null;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: (!widget.puedeEditar || yaAbierta)
                    ? null
                    : () => _destaparFichaOculta(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: yaAbierta
                        ? null
                        : const LinearGradient(
                            colors: [_kVerdeOscuro, _kVerdeMedio],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: yaAbierta ? _kMintBg : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: yaAbierta ? _kVerdeOscuro : _kVerdeClaro,
                      width: 1.5,
                    ),
                  ),
                  child: yaAbierta
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TURNO #$numDescubierto',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: _kVerdeOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dueno?['conductor_nombre']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kSlateDark,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sorpresa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Tocar al azar',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetSorteoRapidoRandom(
    List<Map<String, dynamic>> pendientes,
    List<int> turnosDisponibles,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: _kMintBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shuffle_rounded,
              color: _kVerdeOscuro,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sorteo Rápido Automático',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: _kSlateDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'La app mezclará al azar los ${turnosDisponibles.length} turno(s) disponibles entre los ${pendientes.length} conductor(es) pendientes con un solo toque.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _kSlateMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.puedeEditar)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _sorteandoTodo ? null : _sortearTodosAleatoriamente,
                icon: Icon(
                  _sorteandoTodo
                      ? Icons.autorenew_rounded
                      : Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _sorteandoTodo
                      ? 'Sorteando turnos al azar...'
                      : 'ELEGIR ALEATORIAMENTE TODO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWidgetInstruccionManual() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registro de Sorteo Físico (Papelitos en Asamblea)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: _kSlateDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca sobre cada conductor para anotar el número de turno que sacó en la reunión:',
            style: TextStyle(fontSize: 12, color: _kSlateMuted),
          ),
          const SizedBox(height: 10),
          ..._participantes.map((p) {
            final t = (p['numero_turno'] as num?)?.toInt() ?? 0;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: AvatarConductor(
                nombre: p['conductor_nombre']?.toString() ?? '',
                foto: p['conductor_foto']?.toString(),
                radio: 18,
              ),
              title: Text(
                p['conductor_nombre']?.toString() ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text('CI: ${p['conductor_ci']}'),
              trailing: OutlinedButton(
                onPressed: widget.puedeEditar
                    ? () => _dialogoAsignarTurnoManual(p)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kVerdeOscuro,
                  side: const BorderSide(color: _kVerdeOscuro),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  t > 0 ? 'Turno #$t' : 'Elegir #',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // LISTA DE TURNOS CUANDO EL SORTEO YA ESTÁ CONFIRMADO Y BLOQUEADO
  Widget _buildListaTurnosConfirmados() {
    final metodo = (_pasanaco?['metodo_sorteo']?.toString() ?? 'ruleta')
        .toUpperCase();
    final mapaRondaPorTurno = <int, Map<String, dynamic>>{};
    for (final r in _rondas) {
      final n = (r['numero_ronda'] as num?)?.toInt() ?? 0;
      if (n > 0) mapaRondaPorTurno[n] = r;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kMintBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kVerdeOscuro.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: _kVerdeOscuro,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acta de Sorteo Confirmada y Bloqueada',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: _kVerdeOscuro,
                      ),
                    ),
                    Text(
                      'Modalidad utilizada: $metodo · El orden de entregas es definitivo.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _kSlateDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._participantes.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final turno = (p['numero_turno'] as num?)?.toInt() ?? (i + 1);
          final ronda = mapaRondaPorTurno[turno];
          final entregada =
              (ronda?['estado']?.toString().toLowerCase() ?? '') == 'entregada';

          final fechas = (turno >= 1 && turno <= _fechasProyectadas.length)
              ? _fechasProyectadas[turno - 1]
              : null;
          final fPago = ronda != null
              ? _formatearIsoConDia(ronda['fecha_limite']?.toString())
              : (fechas != null
                    ? _formatearFechaConDia(fechas['fecha_limite_pago']!)
                    : '—');
          final fRecojo = ronda != null
              ? _formatearIsoConDia(
                  ronda['fecha_entrega_programada']?.toString() ??
                      ronda['fecha_limite']?.toString(),
                )
              : (fechas != null
                    ? _formatearFechaConDia(fechas['fecha_entrega_programada']!)
                    : '—');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: entregada
                    ? _kVerdeOscuro.withValues(alpha: 0.45)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: entregada ? _kVerdeOscuro : _kMintBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$turno',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: entregada ? Colors.white : _kVerdeOscuro,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['conductor_nombre']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: _kSlateDark,
                        ),
                      ),
                      Text(
                        'CI: ${p['conductor_ci']} · Interno #${p['conductor_interno'] ?? '—'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _kSlateMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pagan cuota hasta: $fPago',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kSlateMuted,
                        ),
                      ),
                      Text(
                        'Día que recoge su pozo: $fRecojo',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _kVerdeOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: entregada ? _kMintBg : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entregada ? 'RECIBIÓ POZO' : 'PROGRAMADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: entregada ? _kVerdeOscuro : _kSlateMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // PESTAÑA 2: RONDAS, DOBLE CALENDARIO, COBROS Y ENTREGA DEL POZO
  // ===========================================================================
  Widget _buildTabRondasYPagos() {
    if (!_sorteoConfirmado || _rondas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _kMintBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.casino_rounded,
                  size: 38,
                  color: _kVerdeOscuro,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Primero realiza el Sorteo de Turnos',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _kSlateDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Una vez que sortees los turnos con la Ruleta o las Fichas Ocultas y confirmes el acta, se activarán todas las rondas con sus fechas de pago y de entrega.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _kSlateMuted),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.casino_rounded, color: Colors.white),
                label: const Text(
                  'Ir a la Pestaña de Sorteo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      itemCount: _rondas.length,
      itemBuilder: (ctx, i) => _buildCardRonda(_rondas[i]),
    );
  }

  Widget _buildCardRonda(Map<String, dynamic> r) {
    final nro = (r['numero_ronda'] as num?)?.toInt() ?? 1;
    final estado = r['estado']?.toString().toLowerCase() ?? 'pendiente';
    final isEntregada = estado == 'entregada';
    final total = (r['monto_total'] as num?)?.toDouble() ?? 0.0;
    final recaudado = (r['total_recaudado'] as num?)?.toDouble() ?? 0.0;
    final pagados = (r['aportes_pagados'] as num?)?.toInt() ?? 0;
    final totalAportes = (r['total_aportes_esperados'] as num?)?.toInt() ?? 0;
    final pozoCompleto = total > 0 && recaudado >= (total - 0.01);

    final fPagoStr = _formatearIsoConDia(r['fecha_limite']?.toString());
    final fRecojoRaw = r['fecha_entrega_programada']?.toString();
    final fRecojoStr = (fRecojoRaw != null && fRecojoRaw.isNotEmpty)
        ? _formatearIsoConDia(fRecojoRaw)
        : (nro <= _fechasProyectadas.length
              ? _formatearFechaConDia(
                  _fechasProyectadas[nro - 1]['fecha_entrega_programada']!,
                )
              : fPagoStr);

    final double progreso = total > 0
        ? (recaudado / total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEntregada
              ? _kVerdeOscuro.withValues(alpha: 0.45)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la ronda
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kVerdeOscuro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'RONDA #$nro',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEntregada
                      ? _kMintBg
                      : (pozoCompleto
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isEntregada
                      ? 'POZO ENTREGADO'
                      : (pozoCompleto
                            ? 'POZO LISTO PARA ENTREGAR'
                            : 'EN RECAUDACIÓN'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isEntregada || pozoCompleto
                        ? _kVerdeOscuro
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Beneficiario que recoge el pozo
          Row(
            children: [
              AvatarConductor(
                nombre: r['beneficiario_nombre']?.toString() ?? '',
                foto: r['beneficiario_foto']?.toString(),
                radio: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recoge el pozo en este turno:',
                      style: TextStyle(fontSize: 11, color: _kSlateMuted),
                    ),
                    Text(
                      r['beneficiario_nombre']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: _kSlateDark,
                      ),
                    ),
                    Text(
                      'CI: ${r['beneficiario_ci']} · Turno #$nro',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _kSlateMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatearBs(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: _kVerdeOscuro,
                    ),
                  ),
                  Text(
                    'Recaudado: ${formatearBs(recaudado)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // CAJA DOBLE DE FECHAS: DÍA DE PAGO VS. DÍA DE RECOJO
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        size: 18,
                        color: _kSlateMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '1. Pagan cuota hasta:',
                              style: TextStyle(
                                fontSize: 10,
                                color: _kSlateMuted,
                              ),
                            ),
                            Text(
                              fPagoStr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _kSlateDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kMintBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _kVerdeOscuro.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.redeem_rounded,
                        size: 18,
                        color: _kVerdeOscuro,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEntregada
                                  ? '2. Pozo entregado el:'
                                  : '2. Recoge el pozo el:',
                              style: const TextStyle(
                                fontSize: 10,
                                color: _kVerdeOscuro,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isEntregada
                                  ? _formatearIsoConDia(
                                      r['fecha_entrega']?.toString(),
                                    )
                                  : fRecojoStr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: _kVerdeOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barra de progreso de aportes
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_kVerdeOscuro),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aportes pagados: $pagados de $totalAportes',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kSlateMuted,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _abrirSheetAportesRonda(r),
                    icon: const Icon(Icons.checklist_rounded, size: 16),
                    label: Text(
                      widget.puedeEditar ? 'Cobrar / Ver' : 'Ver Aportes',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kVerdeOscuro,
                      side: const BorderSide(color: _kVerdeOscuro),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (!isEntregada && widget.puedeEditar) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmarEntregarPozoRonda(r),
                      icon: const Icon(
                        Icons.redeem_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Entregar Pozo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kVerdeOscuro,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ] else if (isEntregada) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _mostrarActaEntregaPozo(r),
                      icon: const Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: _kVerdeOscuro,
                      ),
                      label: const Text(
                        'Acta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _kVerdeOscuro,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: RULETA VISUAL DE SORTEO EN VIVO
// =============================================================================
class _RuletaSorteoPainter extends CustomPainter {
  final List<int> turnosDisponibles;
  final double anguloRotacion;

  _RuletaSorteoPainter({
    required this.turnosDisponibles,
    required this.anguloRotacion,
  });

  static const List<Color> _paleta = [
    Color(0xFFFFB5A7), // Coral pastel
    Color(0xFF93C5FD), // Azul cielo
    Color(0xFFFDE68A), // Amarillo sol
    Color(0xFFC4B5FD), // Lavanda
    Color(0xFFF9A8D4), // Rosa sakura
    Color(0xFF7DD3FC), // Celeste aqua
    Color(0xFFFDBA74), // Durazno
    Color(0xFFA5B4FC), // Lila suave
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    // Borde exterior verde claro
    final outerPaint = Paint()
      ..color = _kVerdeClaro
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius + 2, outerPaint);

    if (turnosDisponibles.isEmpty) return;

    final n = turnosDisponibles.length;
    final sliceAngle = (2 * math.pi) / n;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < n; i++) {
      final numTurno = turnosDisponibles[i];
      final startAngle = anguloRotacion + i * sliceAngle;
      var colorIdx = i % _paleta.length;
      if (i == n - 1 && n > 1 && colorIdx == 0) {
        colorIdx = 2; // Evitar que el último gajo repita el color del primero
      }
      final paintSlice = Paint()
        ..color = _paleta[colorIdx]
        ..style = PaintingStyle.fill;

      if (n == 1) {
        canvas.drawCircle(center, radius, paintSlice);
      } else {
        canvas.drawArc(rect, startAngle, sliceAngle, true, paintSlice);

        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(rect, startAngle, sliceAngle, true, borderPaint);
      }

      final etiqueta = n <= 12 ? 'Turno $numTurno' : '#$numTurno';

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sliceAngle / 2);

      final tp = TextPainter(
        text: TextSpan(
          text: etiqueta,
          style: TextStyle(
            color: _kSlateDark,
            fontSize: n > 14 ? 11 : (n > 8 ? 12.5 : 14),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: radius * 0.62);

      // Posicionar el número hacia la zona media-exterior donde el gajo es más ancho
      final radialOffset = radius * 0.60 - tp.width / 2;
      tp.paint(canvas, Offset(math.max(radius * 0.30, radialOffset), -tp.height / 2));
      canvas.restore();
    }

    // Centro estético claro con acento verde claro
    canvas.drawCircle(center, 24, Paint()..color = Colors.white);
    canvas.drawCircle(center, 18, Paint()..color = _kVerdeClaro);
    canvas.drawCircle(center, 7, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RuletaSorteoPainter oldDelegate) {
    if (oldDelegate.anguloRotacion != anguloRotacion ||
        oldDelegate.turnosDisponibles.length != turnosDisponibles.length) {
      return true;
    }
    for (int i = 0; i < turnosDisponibles.length; i++) {
      if (oldDelegate.turnosDisponibles[i] != turnosDisponibles[i]) {
        return true;
      }
    }
    return false;
  }
}

// =============================================================================
// BOTTOM SHEET DE APORTES DE UNA RONDA (COBRO RÁPIDO IN-SITU + RECIBO OFICIAL)
// =============================================================================
class _AportesRondaSheet extends StatefulWidget {
  final String idRonda;
  final String nroRonda;
  final String beneficiarioNombre;
  final String fechaLimitePago;
  final String fechaEntregaPozo;
  final double montoPozo;
  final bool puedeEditar;
  final VoidCallback onCambio;

  const _AportesRondaSheet({
    required this.idRonda,
    required this.nroRonda,
    required this.beneficiarioNombre,
    required this.fechaLimitePago,
    required this.fechaEntregaPozo,
    required this.montoPozo,
    required this.puedeEditar,
    required this.onCambio,
  });

  @override
  State<_AportesRondaSheet> createState() => _AportesRondaSheetState();
}

class _AportesRondaSheetState extends State<_AportesRondaSheet> {
  List<Map<String, dynamic>> _aportes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await EconomiaRepo.instance.aportesDeRonda(widget.idRonda);
    if (mounted) {
      setState(() {
        _aportes = lista;
        _cargando = false;
      });
    }
  }

  Future<void> _cobrarAporteDirecto(Map<String, dynamic> a) async {
    final saldo = (a['saldo'] as num?)?.toDouble() ?? 0.0;
    final nombreCond = a['conductor_nombre']?.toString() ?? 'Conductor';
    final idCuota = a['id_cuota'].toString();
    String metodo = 'efectivo';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cobrar Aporte · Ronda #${widget.nroRonda}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conductor: $nombreCond',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Importe a cobrar: ${formatearBs(saldo)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: _kVerdeOscuro,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Método de pago:',
                style: TextStyle(fontSize: 12, color: _kSlateMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Efectivo'),
                      selected: metodo == 'efectivo',
                      selectedColor: _kVerdeOscuro,
                      labelStyle: TextStyle(
                        color: metodo == 'efectivo'
                            ? Colors.white
                            : _kSlateDark,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) =>
                          setDialogState(() => metodo = 'efectivo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('QR / Transferencia'),
                      selected: metodo == 'qr',
                      selectedColor: _kVerdeOscuro,
                      labelStyle: TextStyle(
                        color: metodo == 'qr' ? Colors.white : _kSlateDark,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setDialogState(() => metodo = 'qr'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVerdeOscuro,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Confirmar Cobro'),
            ),
          ],
        ),
      ),
    );

    if (confirmar == true) {
      try {
        final recibo = await EconomiaRepo.instance.registrarPago(
          idCuota: idCuota,
          monto: saldo,
          metodo: metodo,
          idUsuario: SesionService.instance.idUsuario ?? 'sistema',
        );
        await _cargar();
        widget.onCambio();
        if (mounted) {
          await DialogoReciboModal.mostrar(context, recibo);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _verReciboExistente(Map<String, dynamic> a) {
    final datosRecibo = {
      'nro_recibo': a['ultimo_nro_recibo'] ?? 'REC-000000',
      'fecha': a['ultima_fecha_pago'] ?? a['fecha'] ?? '',
      'monto_pagado': a['monto_pagado'] ?? a['monto'] ?? 0.0,
      'monto': a['monto_pagado'] ?? a['monto'] ?? 0.0,
      'metodo': a['ultimo_metodo'] ?? 'efectivo',
      'observacion': a['ultima_observacion'],
      'tipo_nombre': a['tipo_nombre'] ?? 'Pasanaku',
      'concepto': a['concepto'] ?? 'Aporte Pasanaku',
      'conductor_nombre': a['conductor_nombre'] ?? '',
      'conductor_ci': a['conductor_ci'] ?? '',
      'total_cuota': a['monto'] ?? 0.0,
      'saldo_restante': a['saldo'] ?? 0.0,
    };
    DialogoReciboModal.mostrar(context, datosRecibo);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aportes Ronda #${widget.nroRonda}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _kSlateDark,
                      ),
                    ),
                    Text(
                      'Beneficiario: ${widget.beneficiarioNombre} · Pozo: ${formatearBs(widget.montoPozo)}',
                      style: const TextStyle(fontSize: 12, color: _kSlateMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: _kSlateMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kMintBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pagan hasta: ${widget.fechaLimitePago}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _kSlateDark,
                  ),
                ),
                Text(
                  'Entrega pozo: ${widget.fechaEntregaPozo}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: _kVerdeOscuro,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : ListView.builder(
                    itemCount: _aportes.length,
                    itemBuilder: (ctx, i) {
                      final a = _aportes[i];
                      final estado =
                          a['estado']?.toString().toLowerCase() ?? 'pendiente';
                      final saldo = (a['saldo'] as num?)?.toDouble() ?? 0.0;
                      final isPagado = estado == 'pagado' || saldo <= 0.001;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isPagado
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPagado
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            AvatarConductor(
                              nombre: a['conductor_nombre']?.toString() ?? '',
                              foto: a['conductor_foto']?.toString(),
                              radio: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a['conductor_nombre']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: _kSlateDark,
                                    ),
                                  ),
                                  Text(
                                    isPagado
                                        ? 'Aporte pagado (${formatearBs((a['monto'] as num?)?.toDouble() ?? 0)})'
                                        : 'Pendiente: ${formatearBs(saldo)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isPagado
                                          ? _kVerdeOscuro
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPagado)
                              OutlinedButton.icon(
                                onPressed: () => _verReciboExistente(a),
                                icon: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Recibo',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kVerdeOscuro,
                                  side: const BorderSide(color: _kVerdeOscuro),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )
                            else if (widget.puedeEditar)
                              ElevatedButton.icon(
                                onPressed: () => _cobrarAporteDirecto(a),
                                icon: const Icon(
                                  Icons.payments_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Cobrar',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kVerdeOscuro,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PENDIENTE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
