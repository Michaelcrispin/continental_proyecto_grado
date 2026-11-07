import 'package:flutter/material.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/avatar_conductor.dart';
import 'widgets/selector_beneficiario_sheet.dart';
import 'widgets/selector_conductores_sheet.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);

/// Pantalla "Nueva cuota" para Apoyo Económico (Solidarias).
/// Rediseñada fielmente al diseño modular de tarjetas con cabecera curva verde corporativa.
class CrearApoyoEconomicoScreen extends StatefulWidget {
  const CrearApoyoEconomicoScreen({super.key});

  @override
  State<CrearApoyoEconomicoScreen> createState() =>
      _CrearApoyoEconomicoScreenState();
}

class _CrearApoyoEconomicoScreenState extends State<CrearApoyoEconomicoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _motivoCtrl;
  late final TextEditingController _importeCtrl;

  String _modalidad = 'voluntaria'; // 'voluntaria' | 'obligatoria'
  Map<String, dynamic>? _beneficiario;
  DateTime? _fechaLimite;

  List<Map<String, dynamic>> _conductoresActivos = [];
  Set<String> _idsConductoresAportantes = {};
  bool _cargandoConductores = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _motivoCtrl = TextEditingController();
    _importeCtrl = TextEditingController();

    // Fecha límite por defecto: 15 días a partir de hoy
    final now = DateTime.now();
    _fechaLimite = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 15));

    _cargarConductores();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _motivoCtrl.dispose();
    _importeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    try {
      final lista = await EconomiaRepo.instance.listarConductoresActivos();
      if (mounted) {
        setState(() {
          _conductoresActivos = lista;
          _idsConductoresAportantes = lista
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

  Future<void> _abrirSelectorBeneficiario() async {
    final seleccionado = await SelectorBeneficiarioSheet.mostrar(
      context,
      conductores: _conductoresActivos,
      idSeleccionadoActual: _beneficiario?['id_conductor']?.toString(),
    );

    if (seleccionado != null && mounted) {
      setState(() {
        _beneficiario = seleccionado;
        final nombreBen = seleccionado['nombre']?.toString() ?? 'Conductor';
        final idBen = seleccionado['id_conductor']?.toString() ?? '';

        // Sugerir título automáticamente si está vacío o si tenía otro conductor
        if (_nombreCtrl.text.isEmpty ||
            _nombreCtrl.text.startsWith('Apoyo Económico:')) {
          _nombreCtrl.text = 'Apoyo Económico: $nombreBen';
        }

        // Excluir automáticamente al beneficiario de la lista de aportantes
        _idsConductoresAportantes.remove(idBen);
      });
    }
  }

  Future<void> _abrirSelectorAportantes() async {
    final idBen = _beneficiario?['id_conductor']?.toString();
    final candidatos = _conductoresActivos
        .where((c) => c['id_conductor']?.toString() != idBen)
        .toList();

    final resultado = await SelectorConductoresSheet.mostrar(
      context,
      todosConductores: candidatos,
      idsSeleccionados: _idsConductoresAportantes,
    );

    if (resultado != null && mounted) {
      setState(() => _idsConductoresAportantes = resultado);
    }
  }

  Future<void> _seleccionarFechaLimite() async {
    final now = DateTime.now();
    final inicial = _fechaLimite ?? now.add(const Duration(days: 15));
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(now) ? now : inicial,
      firstDate: now,
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kVerdeOscuro,
            onPrimary: Colors.white,
            onSurface: _kVerdeOscuro,
          ),
        ),
        child: child ?? const SizedBox(),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _fechaLimite = picked);
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin límite';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_beneficiario == null) {
      _mostrarSnack(
        'Por favor selecciona al conductor beneficiario de la ayuda.',
      );
      return;
    }

    final nombre = _nombreCtrl.text.trim();
    final motivo = _motivoCtrl.text.trim();
    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;

    if (importe < 1) {
      _mostrarSnack('El importe mínimo por conductor es Bs. 1.00.');
      return;
    }

    final idBeneficiario = _beneficiario!['id_conductor']?.toString() ?? '';
    final aportantesFinales = _idsConductoresAportantes
        .where((id) => id != idBeneficiario)
        .toList();

    if (aportantesFinales.isEmpty) {
      _mostrarSnack('Debes seleccionar al menos un conductor aportante.');
      return;
    }

    setState(() => _guardando = true);

    try {
      final idUsuario = SesionService.instance.idUsuario ?? 'admin';
      final nombreBeneficiario =
          _beneficiario!['nombre']?.toString() ?? 'Conductor';

      await EconomiaRepo.instance.crearApoyoEconomico(
        nombre: nombre,
        motivo: motivo,
        modalidad: _modalidad,
        idConductorBeneficiario: idBeneficiario,
        nombreBeneficiario: nombreBeneficiario,
        importePorChofer: importe,
        fechaLimite: _fechaLimite,
        idsAportantes: aportantesFinales,
        idUsuario: idUsuario,
      );

      if (!mounted) return;
      AppSnackBar.exito(
        context,
        '¡$nombre creado! Se registró la ayuda para $nombreBeneficiario con ${aportantesFinales.length} aportantes.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _mostrarSnack('Error al crear apoyo económico: $e');
      }
    }
  }

  void _mostrarSnack(String mensaje) {
    AppSnackBar.error(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final idBen = _beneficiario?['id_conductor']?.toString();
    final candidatos = _conductoresActivos
        .where((c) => c['id_conductor']?.toString() != idBen)
        .toList();
    final aportantesFinales = _idsConductoresAportantes
        .where((id) => id != idBen)
        .toList();
    final cantAportantes = aportantesFinales.length;
    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;
    final totalFondo = importe * cantAportantes;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. CABECERA CURVA VERDE CORPORATIVA CON LOGO
          _buildCurvedHeader(topPadding),

          // 2. CUERPO DEL FORMULARIO CON TARJETAS MODULARES
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // TÍTULO Y DESCRIPCIÓN DE LA CATEGORÍA
                  _buildHeaderInfo(
                    titulo: 'Apoyo Económico',
                    subtitulo:
                        'Ayuda solidaria ante emergencias, salud o accidentes para un miembro del sindicato.',
                    icono: Icons.handshake_outlined,
                  ),

                  const SizedBox(height: 16),

                  // TARJETA 1: CONDUCTOR BENEFICIARIO
                  _buildCardContainer(
                    icono: Icons.person_rounded,
                    titulo: 'Beneficiario de la Ayuda',
                    subtitulo: 'Conductor que recibirá el fondo recaudado',
                    child: InkWell(
                      onTap: _abrirSelectorBeneficiario,
                      borderRadius: BorderRadius.circular(14),
                      child: _buildInputContainer(
                        child: _beneficiario == null
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_add_alt_1_rounded,
                                      color: _kVerdeOscuro,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Toca para seleccionar al beneficiario...',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    AvatarConductor(
                                      foto: _beneficiario!['foto_url']
                                          ?.toString(),
                                      nombre:
                                          _beneficiario!['nombre']
                                              ?.toString() ??
                                          '',
                                      radio: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _beneficiario!['nombre']
                                                    ?.toString() ??
                                                'Conductor',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            'Auto: ${_beneficiario!['numero_auto'] ?? 'S/N'} • CI: ${_beneficiario!['ci'] ?? 'S/CI'}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
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
                                        color: _kMintBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Cambiar',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _kVerdeOscuro,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 2: NOMBRE DE LA CUOTA
                  _buildCardContainer(
                    icono: Icons.layers_rounded,
                    titulo: 'Nombre de la Cuota',
                    subtitulo: 'Identifica la campaña de solidaridad',
                    child: _buildInputContainer(
                      child: TextFormField(
                        controller: _nombreCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Apoyo Económico: Alberto Limachi',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un nombre para la cuota';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 3: IMPORTE POR CONDUCTOR
                  _buildCardContainer(
                    icono: Icons.attach_money_rounded,
                    titulo: 'Importe por Conductor',
                    subtitulo:
                        'Monto fijo en Bolivianos (Bs.) que aportará cada chofer',
                    child: _buildInputContainer(
                      child: Row(
                        children: [
                          const Text(
                            'Bs.   ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _kVerdeOscuro,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _importeCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Ej. 20',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa el monto';
                                }
                                final n = double.tryParse(value);
                                if (n == null || n < 1) {
                                  return 'El mínimo es Bs. 1.00';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 4: MOTIVO DE LA AYUDA
                  _buildCardContainer(
                    icono: Icons.description_rounded,
                    titulo: 'Motivo o Detalle',
                    subtitulo:
                        'Razón médica, familiar o imprevisto de la ayuda',
                    child: _buildInputContainer(
                      child: TextFormField(
                        controller: _motivoCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'Ej. Reposo médico por accidente de tránsito',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el motivo del apoyo';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 5: MODALIDAD Y PLAZO
                  _buildCardContainer(
                    icono: Icons.event_available_rounded,
                    titulo: 'Modalidad y Plazo',
                    subtitulo:
                        'Tipo de recaudación y fecha límite para aportar',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio buttons: Voluntaria / Obligatoria
                        Row(
                          children: [
                            Expanded(
                              child: _buildRadioCard(
                                titulo: 'Voluntaria',
                                subtitulo: 'Aporte libre',
                                seleccionado: _modalidad == 'voluntaria',
                                onTap: () =>
                                    setState(() => _modalidad = 'voluntaria'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRadioCard(
                                titulo: 'Obligatoria',
                                subtitulo: 'Para el grupo',
                                seleccionado: _modalidad == 'obligatoria',
                                onTap: () =>
                                    setState(() => _modalidad = 'obligatoria'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Fecha límite
                        const Text(
                          'Fecha límite de recaudación',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _seleccionarFechaLimite,
                          borderRadius: BorderRadius.circular(14),
                          child: _buildInputContainer(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatearFecha(_fechaLimite),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 18,
                                  color: _kVerdeOscuro,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 6: CONDUCTORES APORTANTES
                  _buildCardContainer(
                    icono: Icons.groups_rounded,
                    titulo: 'Conductores Aportantes',
                    subtitulo:
                        'Choferes asignados para colaborar (excluye al beneficiario)',
                    child: InkWell(
                      onTap: _cargandoConductores
                          ? null
                          : _abrirSelectorAportantes,
                      borderRadius: BorderRadius.circular(14),
                      child: _buildInputContainer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kMintBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$cantAportantes / ${candidatos.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _kVerdeOscuro,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  cantAportantes == candidatos.length
                                      ? 'Todos aportarán'
                                      : '$cantAportantes choferes',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Modificar ›',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _kVerdeOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 7: RESUMEN PROYECTADO
                  Container(
                    decoration: BoxDecoration(
                      color: _kMintBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _kVerdeOscuro.withOpacity(0.25),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.volunteer_activism_rounded,
                              color: _kVerdeOscuro,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Proyección de la Recaudación Solidaria',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _kVerdeOscuro,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildResumenDato(
                              titulo: 'Aportantes',
                              valor: '$cantAportantes choferes',
                            ),
                            _buildResumenDato(
                              titulo: 'Por Chofer',
                              valor: 'Bs. ${importe.toStringAsFixed(2)}',
                            ),
                            _buildResumenDato(
                              titulo: 'Total Estimado',
                              valor: 'Bs. ${totalFondo.toStringAsFixed(2)}',
                              destacado: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 3. BARRA INFERIOR DE ACCIONES (CANCELAR Y GUARDAR CUOTA)
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES DE DISEÑO
  // ===========================================================================

  Widget _buildCurvedHeader(double topPadding) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
        child: Row(
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
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Nueva cuota',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            // Usuario que está manejando en Squircle Blanco
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Tooltip(
                message: SesionService.instance.nombre ?? 'Usuario actual',
                child: const Icon(
                  Icons.person_rounded,
                  color: _kVerdeOscuro,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo({
    required String titulo,
    required String subtitulo,
    required IconData icono,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _kVerdeOscuro,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: _kMintBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: _kVerdeOscuro, size: 28),
        ),
      ],
    );
  }

  Widget _buildCardContainer({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _kMintBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: _kVerdeOscuro, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: child,
    );
  }

  Widget _buildRadioCard({
    required String titulo,
    required String subtitulo,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? _kMintBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? _kVerdeOscuro : const Color(0xFFE2E8F0),
            width: seleccionado ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: seleccionado ? _kVerdeOscuro : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: seleccionado
                          ? _kVerdeOscuro
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenDato({
    required String titulo,
    required String valor,
    bool destacado = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: destacado ? _kVerdeOscuro : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 6
            : 16,
      ),
      child: Row(
        children: [
          // BOTÓN CANCELAR
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64748B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(width: 10),

          // BOTÓN GUARDAR CUOTA
          Expanded(
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVerdeOscuro,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kVerdeOscuro.withOpacity(0.6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Guardar Cuota',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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
