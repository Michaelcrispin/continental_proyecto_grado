import 'package:flutter/material.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/avatar_conductor.dart';
import 'widgets/selector_beneficiario_sheet.dart';
import 'widgets/selector_conductores_sheet.dart';

/// Pantalla especializada para la creación de cuotas de "Apoyo Económico" (Solidarias).
/// Diseño por pasos numerados y tarjeta de resumen en tiempo real.
class CrearApoyoEconomicoScreen extends StatefulWidget {
  const CrearApoyoEconomicoScreen({super.key});

  @override
  State<CrearApoyoEconomicoScreen> createState() => _CrearApoyoEconomicoScreenState();
}

class _CrearApoyoEconomicoScreenState extends State<CrearApoyoEconomicoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _motivoCtrl;
  late final TextEditingController _importeCtrl;

  // Modalidad: 'voluntaria' o 'obligatoria' (por defecto 'voluntaria')
  String _modalidad = 'voluntaria';

  // Conductor beneficiario seleccionado
  Map<String, dynamic>? _beneficiario;

  // Fecha límite de recepción
  DateTime? _fechaLimite;

  // Lista de todos los conductores activos y seleccionados para aportar
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
    _fechaLimite = DateTime(now.year, now.month, now.day).add(const Duration(days: 15));

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
        if (_nombreCtrl.text.isEmpty || _nombreCtrl.text.startsWith('Apoyo Económico:')) {
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
            primary: Color(0xFF0F2B5B),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F2B5B),
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
      _mostrarSnack('Por favor selecciona al conductor beneficiario de la ayuda.');
      return;
    }

    final nombre = _nombreCtrl.text.trim();
    final motivo = _motivoCtrl.text.trim();
    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;

    if (importe <= 0) {
      _mostrarSnack('Ingresa un importe válido mayor a 0 Bs.');
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
      final nombreBeneficiario = _beneficiario!['nombre']?.toString() ?? 'Conductor';

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
    final idBen = _beneficiario?['id_conductor']?.toString();
    final cantAportantes = _idsConductoresAportantes
        .where((id) => id != idBen)
        .length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nueva Cuota Solidaria',
          style: TextStyle(
            color: Color(0xFF0F2B5B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/logo.png',
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_bus_rounded,
                color: Color(0xFF0F2B5B),
                size: 26,
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _cargandoConductores
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F2B5B)),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    children: [
                      // ENCABEZADO CON ILUSTRACIÓN DE MANO Y CORAZÓN
                      _buildEncabezado(),
                      const SizedBox(height: 14),

                      // PASO 1: BENEFICIARIO
                      _buildPaso1Beneficiario(),
                      const SizedBox(height: 12),

                      // PASO 2: MODALIDAD
                      _buildPaso2Modalidad(),
                      const SizedBox(height: 12),

                      // PASO 3: TÍTULO Y MOTIVO
                      _buildPaso3TituloYMotivo(),
                      const SizedBox(height: 12),

                      // PASO 4: IMPORTE
                      _buildPaso4Importe(),
                      const SizedBox(height: 12),

                      // PASO 5: FECHA LÍMITE
                      _buildPaso5FechaLimite(),
                      const SizedBox(height: 12),

                      // PASO 6: CONDUCTORES APORTANTES
                      _buildPaso6Aportantes(cantAportantes),
                      const SizedBox(height: 20),

                      // BOTONES: CANCELAR Y CREAR
                      _buildBotonesAccion(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ENCABEZADO PRINCIPAL
  // ===========================================================================
  Widget _buildEncabezado() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apoyo Económico',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2B5B),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Crea un fondo solidario para apoyar a un conductor del sindicato en caso de accidente o emergencia.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
          ),
          child: const CustomPaint(
            painter: _HeartHandPainter(),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CONTENEDOR BASE DE SECCIÓN
  // ===========================================================================
  Widget _buildCardPaso({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    Widget? trailing,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F2B5B),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icono,
                  color: const Color(0xFF2563EB),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2B5B),
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // BENEFICIARIO
  // ===========================================================================
  Widget _buildPaso1Beneficiario() {
    return _buildCardPaso(
      icono: Icons.person_rounded,
      titulo: '¿A quién estamos ayudando?',
      subtitulo: 'Conductor beneficiario de este apoyo',
      child: _beneficiario == null
          ? InkWell(
              onTap: _abrirSelectorBeneficiario,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 19),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Seleccionar Conductor Beneficiario',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB), size: 20),
                  ],
                ),
              ),
            )
          : InkWell(
              onTap: _abrirSelectorBeneficiario,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    AvatarConductor(
                      foto: _beneficiario!['foto']?.toString(),
                      nombre: _beneficiario!['nombre']?.toString() ?? 'Conductor',
                      radio: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _beneficiario!['nombre']?.toString() ?? 'Conductor',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2B5B),
                            ),
                          ),
                          Text(
                            'CI: ${_beneficiario!['ci'] ?? 'S/CI'}${_beneficiario!['telefono'] != null ? ' · Cel: ${_beneficiario!['telefono']}' : ''}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Cambiar',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ===========================================================================
  // MODALIDAD DEL APORTE
  // ===========================================================================
  Widget _buildPaso2Modalidad() {
    final esVoluntaria = _modalidad == 'voluntaria';
    return _buildCardPaso(
      icono: Icons.tune_rounded,
      titulo: 'Modalidad del Aporte',
      subtitulo: 'Elige cómo se exigirá y registrará en el informe',
      child: Row(
        children: [
          // OPCIÓN OBLIGATORIA
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _modalidad = 'obligatoria'),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                  color: !esVoluntaria ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !esVoluntaria ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    width: !esVoluntaria ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: !esVoluntaria ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          width: !esVoluntaria ? 5 : 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Obligatoria',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2B5B),
                            ),
                          ),
                          Text(
                            'Cuota fija para todos los socios',
                            style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                            maxLines: 1,
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
          const SizedBox(width: 8),

          // OPCIÓN VOLUNTARIA
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _modalidad = 'voluntaria'),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                  color: esVoluntaria ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: esVoluntaria ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    width: esVoluntaria ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      esVoluntaria ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 18,
                      color: esVoluntaria ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voluntaria',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            'Aporte libre y solidario',
                            style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (esVoluntaria)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1FAE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TÍTULO Y MOTIVO DEL APOYO
  // ===========================================================================
  Widget _buildPaso3TituloYMotivo() {
    return _buildCardPaso(
      icono: Icons.edit_note_rounded,
      titulo: 'Título y Motivo del Apoyo',
      subtitulo: 'Identifica la ayuda y describe la situación',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Título de la Cuota Solidaria',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2B5B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nombreCtrl,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'ej. Apoyo Económico: Carlos Mamani',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Ingresa un título para identificar la ayuda'
                : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Detalle o Causa de la Ayuda',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2B5B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _motivoCtrl,
            minLines: 2,
            maxLines: 3,
            maxLength: 250,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'ej. Accidente de tránsito en carretera a Viacha, gastos médicos de hospitalización y reposo.',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Máx. 250 caracteres',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PASO 4: IMPORTE
  // ===========================================================================
  // IMPORTE
  // ===========================================================================
  Widget _buildPaso4Importe() {
    final esVoluntaria = _modalidad == 'voluntaria';
    return _buildCardPaso(
      icono: Icons.payments_rounded,
      titulo: esVoluntaria ? 'Importe Sugerido por Chofer' : 'Importe Fijo por Chofer',
      subtitulo: 'Monto en Bolivianos (Bs.)',
      child: TextFormField(
        controller: _importeCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Text(
              'Bs.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: 'ej. 20',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.normal),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Ingresa el importe';
          final val = double.tryParse(v.trim());
          if (val == null || val <= 0) return 'Ingresa un monto válido mayor a 0';
          return null;
        },
      ),
    );
  }

  // ===========================================================================
  // FECHA LÍMITE DE RECEPCIÓN
  // ===========================================================================
  Widget _buildPaso5FechaLimite() {
    return _buildCardPaso(
      icono: Icons.calendar_month_rounded,
      titulo: 'Fecha Límite de Recepción',
      subtitulo: 'Plazo para recaudar la ayuda',
      trailing: InkWell(
        onTap: _seleccionarFechaLimite,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0F2B5B)),
              const SizedBox(width: 6),
              Text(
                _formatearFecha(_fechaLimite),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2B5B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CONDUCTORES APORTANTES
  // ===========================================================================
  Widget _buildPaso6Aportantes(int cantAportantes) {
    return _buildCardPaso(
      icono: Icons.people_alt_rounded,
      titulo: 'Conductores Aportantes',
      subtitulo: '$cantAportantes compañeros participando',
      trailing: OutlinedButton.icon(
        onPressed: _abrirSelectorAportantes,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F2B5B),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.tune_rounded, size: 14),
        label: const Text('Modificar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _beneficiario != null
                    ? 'Todos los conductores activos excepto ${_beneficiario!['nombre']} están seleccionados para aportar.'
                    : 'Todos los conductores activos están seleccionados para aportar.',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTONES CANCELAR Y GUARDAR
  // ===========================================================================
  Widget _buildBotonesAccion() {
    return Row(
      children: [
        // Botón Cancelar
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _guardando ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF0F2B5B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Botón Guardar
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B074), // Verde idéntico a las demás pantallas
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dibuja la ilustración personalizada del encabezado: mano azul sosteniendo un corazón verde.
class _HeartHandPainter extends CustomPainter {
  const _HeartHandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Corazón verde
    final heartPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final heartPath = Path();
    final hx = w * 0.50;
    final hy = h * 0.35;
    final hs = w * 0.28;
    heartPath.moveTo(hx, hy + hs * 0.45);
    heartPath.cubicTo(
      hx - hs * 0.65, hy - hs * 0.2,
      hx - hs * 0.65, hy - hs * 0.75,
      hx, hy - hs * 0.35,
    );
    heartPath.cubicTo(
      hx + hs * 0.65, hy - hs * 0.75,
      hx + hs * 0.65, hy - hs * 0.2,
      hx, hy + hs * 0.45,
    );
    heartPath.close();
    canvas.drawPath(heartPath, heartPaint);

    // Mano en azul marino
    final handPaint = Paint()
      ..color = const Color(0xFF0F2B5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final handPath = Path();
    // Muñeca / manga
    handPath.moveTo(w * 0.22, h * 0.72);
    handPath.lineTo(w * 0.36, h * 0.72);
    // Palma que sube
    handPath.moveTo(w * 0.30, h * 0.72);
    handPath.cubicTo(
      w * 0.40, h * 0.82,
      w * 0.66, h * 0.82,
      w * 0.78, h * 0.64,
    );
    handPath.lineTo(w * 0.72, h * 0.58);
    // Dedo pulgar
    handPath.moveTo(w * 0.40, h * 0.72);
    handPath.quadraticBezierTo(w * 0.46, h * 0.58, w * 0.56, h * 0.62);

    canvas.drawPath(handPath, handPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
