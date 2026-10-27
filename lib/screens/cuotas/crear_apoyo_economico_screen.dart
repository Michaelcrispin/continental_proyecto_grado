import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/avatar_conductor.dart';
import 'widgets/selector_beneficiario_sheet.dart';
import 'widgets/selector_conductores_sheet.dart';

/// Pantalla especializada para la creación de cuotas de "Apoyo Económico" (Solidarias).
/// Permite:
/// - Elegir al conductor beneficiario (quien queda excluido automáticamente del cobro).
/// - Seleccionar la modalidad de aporte: "Obligatoria" vs "Voluntaria".
/// - Registrar el motivo específico (accidente, salud, gastos médicos, etc.).
/// - Fijar el importe por conductor (Bs.) y fecha límite opcional.
/// - Elegir los conductores aportantes mediante selector interactivo.
/// - Previsualizar el total estimado de recaudación en tiempo real.
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

  // Modalidad: 'obligatoria' o 'voluntaria'
  String _modalidad = 'obligatoria';

  // Conductor beneficiario seleccionado
  Map<String, dynamic>? _beneficiario;

  // Fecha límite de recepción (opcional)
  DateTime? _fechaLimite;

  // Lista de todos los conductores activos y seleccionados para aportar
  List<Map<String, dynamic>> _conductoresActivos = [];
  Set<String> _idsConductoresAportantes = {};
  bool _cargandoConductores = true;
  bool _guardando = false;

  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

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
    // Lista de posibles aportantes (excluyendo al beneficiario)
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
    if (picked != null) {
      setState(() => _fechaLimite = picked);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡$nombre creado! Se registró la ayuda para $nombreBeneficiario con ${aportantesFinales.length} aportantes.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;
    final idBen = _beneficiario?['id_conductor']?.toString();
    final cantAportantes = _idsConductoresAportantes
        .where((id) => id != idBen)
        .length;
    final totalMeta = importe * cantAportantes;

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
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/logo.png',
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_bus_rounded,
                color: Color(0xFF0F2B5B),
                size: 28,
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    children: [
                      // ENCABEZADO
                      const Text(
                        'Apoyo Económico',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F2B5B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Crea un fondo solidario para apoyar a un conductor del sindicato en caso de accidente o emergencia.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
                      ),
                      const SizedBox(height: 18),

                      // 1. SELECTOR DEL CONDUCTOR BENEFICIARIO
                      _buildSeccionBeneficiario(),
                      const SizedBox(height: 16),

                      // 2. SELECTOR DE MODALIDAD (OBLIGATORIA VS VOLUNTARIA)
                      _buildSeccionModalidad(),
                      const SizedBox(height: 16),

                      // 3. TÍTULO Y MOTIVO / DETALLE
                      _buildSeccionTituloYMotivo(),
                      const SizedBox(height: 16),

                      // 4. IMPORTE POR CONDUCTOR Y FECHA LÍMITE
                      _buildSeccionImporteYFecha(),
                      const SizedBox(height: 16),

                      // 5. CONDUCTORES APORTANTES
                      _buildSeccionAportantes(cantAportantes),
                      const SizedBox(height: 18),

                      // 6. RESUMEN FINANCIERO EN TIEMPO REAL
                      _buildResumenFinanciero(cantAportantes, importe, totalMeta),
                      const SizedBox(height: 24),

                      // BOTONES: CANCELAR Y GUARDAR
                      _buildBotonesAccion(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. CONDUCTOR BENEFICIARIO
  // ===========================================================================
  Widget _buildSeccionBeneficiario() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _beneficiario != null ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          width: _beneficiario != null ? 1.5 : 1,
        ),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿A quién estamos ayudando?',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2B5B),
                      ),
                    ),
                    Text(
                      'Conductor beneficiario de este apoyo',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (_beneficiario != null)
                TextButton(
                  onPressed: _abrirSelectorBeneficiario,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (_beneficiario == null) ...[
            InkWell(
              onTap: _abrirSelectorBeneficiario,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Seleccionar Conductor Beneficiario',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Al seleccionarlo, se excluirá automáticamente de la lista de aportantes.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  AvatarConductor(
                    foto: _beneficiario!['foto']?.toString(),
                    nombre: _beneficiario!['nombre']?.toString() ?? 'Conductor',
                    radio: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _beneficiario!['nombre']?.toString() ?? 'Conductor',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2B5B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CI: ${_beneficiario!['ci'] ?? 'S/CI'}${_beneficiario!['telefono'] != null ? ' · Cel: ${_beneficiario!['telefono']}' : ''}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Beneficiario',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MODALIDAD DEL APORTE (OBLIGATORIA VS VOLUNTARIA)
  // ===========================================================================
  Widget _buildSeccionModalidad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modalidad del Aporte',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2B5B),
                    ),
                  ),
                  Text(
                    'Elige cómo se exigirá y registrará en el informe',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // TOGGLE VISUAL DE 2 TARJETAS
          Row(
            children: [
              // OPCIÓN 1: OBLIGATORIA
              Expanded(
                child: _buildTarjetaOpcionModalidad(
                  titulo: 'Obligatoria',
                  subtitulo: 'Cuota fija para todos los socios',
                  icono: Icons.verified_user_rounded,
                  activoColor: const Color(0xFF2563EB),
                  activoBgColor: const Color(0xFFEFF6FF),
                  esSeleccionado: _modalidad == 'obligatoria',
                  onTap: () => setState(() => _modalidad = 'obligatoria'),
                ),
              ),
              const SizedBox(width: 12),
              // OPCIÓN 2: VOLUNTARIA
              Expanded(
                child: _buildTarjetaOpcionModalidad(
                  titulo: 'Voluntaria',
                  subtitulo: 'Aporte libre y solidario',
                  icono: Icons.volunteer_activism_rounded,
                  activoColor: const Color(0xFF10B981),
                  activoBgColor: const Color(0xFFECFDF5),
                  esSeleccionado: _modalidad == 'voluntaria',
                  onTap: () => setState(() => _modalidad = 'voluntaria'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Texto explicativo dinámico según la modalidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: _modalidad == 'obligatoria'
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _modalidad == 'obligatoria'
                        ? 'Modalidad Obligatoria: Se generará como deuda pendiente fija para cada conductor aportante.'
                        : 'Modalidad Voluntaria: Los socios aportan según su voluntad o el importe sugerido, sin generar sanciones.',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaOpcionModalidad({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color activoColor,
    required Color activoBgColor,
    required bool esSeleccionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: esSeleccionado ? activoBgColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: esSeleccionado ? activoColor : const Color(0xFFE2E8F0),
            width: esSeleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icono,
                  color: esSeleccionado ? activoColor : const Color(0xFF94A3B8),
                  size: 22,
                ),
                if (esSeleccionado)
                  Icon(Icons.check_circle_rounded, color: activoColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: esSeleccionado ? activoColor : const Color(0xFF0F2B5B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. TÍTULO Y MOTIVO / DETALLE
  // ===========================================================================
  Widget _buildSeccionTituloYMotivo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Título y Motivo del Apoyo',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2B5B),
                    ),
                  ),
                  Text(
                    'Identifica la ayuda y describe la situación',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // CAMPO TÍTULO
          const Text(
            'Título de la Cuota Solidaria',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2B5B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nombreCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ej. Apoyo Económico: Carlos Mamani',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Ingresa un título para identificar la ayuda'
                : null,
          ),
          const SizedBox(height: 14),

          // CAMPO MOTIVO / DETALLE
          const Text(
            'Detalle o Causa de la Ayuda',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2B5B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _motivoCtrl,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'ej. Accidente de tránsito en carretera a Viacha, gastos médicos de hospitalización y reposo.',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          // CHIPS DE SUGERENCIA RÁPIDA
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChipSugerencia('Accidente de tránsito'),
              _buildChipSugerencia('Gastos médicos / Hospital'),
              _buildChipSugerencia('Cirugía de emergencia'),
              _buildChipSugerencia('Emergencia familiar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipSugerencia(String texto) {
    return ActionChip(
      label: Text(texto, style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A))),
      backgroundColor: const Color(0xFFEFF6FF),
      side: const BorderSide(color: Color(0xFFBFDBFE), width: 0.8),
      padding: EdgeInsets.zero,
      onPressed: () {
        if (_motivoCtrl.text.trim().isEmpty) {
          _motivoCtrl.text = texto;
        } else {
          _motivoCtrl.text = '${_motivoCtrl.text.trim()}, $texto';
        }
      },
    );
  }

  // ===========================================================================
  // 4. IMPORTE POR CONDUCTOR Y FECHA LÍMITE
  // ===========================================================================
  Widget _buildSeccionImporteYFecha() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _modalidad == 'obligatoria' ? 'Importe Fijo por Chofer' : 'Importe Sugerido por Chofer',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2B5B),
                    ),
                  ),
                  const Text(
                    'Monto en Bolivianos (Bs.)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // IMPORTE BS
          TextFormField(
            controller: _importeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Text(
                  'Bs.',
                  style: TextStyle(
                    fontSize: 16,
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
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa el importe';
              final val = double.tryParse(v.trim());
              if (val == null || val <= 0) return 'Ingresa un monto válido mayor a 0';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // FECHA LÍMITE (OPCIONAL)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha Límite de Recepción',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F2B5B)),
                  ),
                  Text(
                    'Plazo para recaudar la ayuda',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              InkWell(
                onTap: _seleccionarFechaLimite,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF0F2B5B)),
                      const SizedBox(width: 8),
                      Text(
                        _fechaLimite != null ? _dateFmt.format(_fechaLimite!) : 'Sin límite',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2B5B),
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
  }

  // ===========================================================================
  // 5. CONDUCTORES APORTANTES
  // ===========================================================================
  Widget _buildSeccionAportantes(int cantAportantes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conductores Aportantes',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2B5B),
                        ),
                      ),
                      Text(
                        '$cantAportantes compañeros participando',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _abrirSelectorAportantes,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F2B5B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.checklist_rounded, size: 16),
                label: const Text('Modificar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _beneficiario != null
                        ? 'Se han seleccionado todos los socios activos excepto a ${_beneficiario!['nombre']}.'
                        : 'Todos los conductores activos están seleccionados para aportar.',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. RESUMEN FINANCIERO EN TIEMPO REAL
  // ===========================================================================
  Widget _buildResumenFinanciero(int cantAportantes, double importe, double totalMeta) {
    final nombreBen = _beneficiario?['nombre']?.toString() ?? 'Sin seleccionar';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5B), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F2B5B),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.volunteer_activism_rounded, color: Color(0xFF93C5FD), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Resumen de la Ayuda',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _modalidad == 'obligatoria'
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _modalidad == 'obligatoria' ? 'OBLIGATORIA' : 'VOLUNTARIA',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x33FFFFFF)),
          const SizedBox(height: 12),

          // FILA BENEFICIARIO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Beneficiario:', style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
              Flexible(
                child: Text(
                  nombreBen,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // FILA APORTANTES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Conductores aportantes:', style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
              Text(
                '$cantAportantes choferes',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // FILA CUOTA INDIVIDUAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _modalidad == 'obligatoria' ? 'Cuota por chofer:' : 'Cuota sugerida:',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              ),
              Text(
                'Bs. ${importe.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x33FFFFFF)),
          const SizedBox(height: 10),

          // META TOTAL ESTIMADA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Meta a Recaudar:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD)),
              ),
              Text(
                'Bs. ${totalMeta.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF34D399),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTONES CANCELAR Y GUARDAR
  // ===========================================================================
  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _guardando ? null : () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2B5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.volunteer_activism_rounded, size: 20),
              label: Text(
                _guardando ? 'Creando...' : 'Crear Apoyo Económico',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
