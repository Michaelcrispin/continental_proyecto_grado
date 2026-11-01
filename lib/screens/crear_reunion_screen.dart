import 'package:flutter/material.dart';
import '../services/economia_repo.dart';
import '../widgets/app_background.dart';
import '../widgets/app_snackbar.dart';

/// Pantalla completa para la creación y convocatoria de una nueva reunión.
/// Diseño uniforme con Apoyo Económico y Canastón / Ahorro:
/// - Encabezado limpio con ilustración temática.
/// - Tarjetas seccionales con icono azul (#EFF6FF / #2563EB) y subtítulo.
/// - Botones inferiores simétricos Cancelar y Guardar (verde #00B074).
class CrearReunionScreen extends StatefulWidget {
  const CrearReunionScreen({super.key});

  @override
  State<CrearReunionScreen> createState() => _CrearReunionScreenState();
}

class _CrearReunionScreenState extends State<CrearReunionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _temaCtrl;
  late final TextEditingController _multaCtrl;
  DateTime _fechaSeleccionada = DateTime.now();
  bool _iniciarTodosPresentes = true;
  bool _guardando = false;

  final List<double> _multasSugeridas = const [20.0, 30.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _temaCtrl = TextEditingController();
    _multaCtrl = TextEditingController(text: '50.00');
  }

  @override
  void dispose() {
    _temaCtrl.dispose();
    _multaCtrl.dispose();
    super.dispose();
  }

  String _formatearFechaTexto(DateTime f) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final diaSemana = dias[f.weekday - 1];
    final mes = meses[f.month - 1];
    return '$diaSemana, ${f.day} de $mes de ${f.year}';
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F2B5B),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F2B5B),
          ),
        ),
        child: child ?? const SizedBox(),
      ),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  Future<void> _crearReunion() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    final tema = _temaCtrl.text.trim();
    final multa = double.tryParse(_multaCtrl.text.trim()) ?? 50.0;
    final fechaStr =
        '${_fechaSeleccionada.year.toString().padLeft(4, '0')}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}';

    setState(() => _guardando = true);
    try {
      final idReunion = await EconomiaRepo.instance.crearReunion(
        tema: tema,
        fecha: fechaStr,
        montoMulta: multa,
        estadoInicial: _iniciarTodosPresentes ? 'presente' : 'falta',
      );
      if (!mounted) return;
      AppSnackBar.exito(context, '¡Reunión "$tema" convocada con éxito!');
      Navigator.pop(context, idReunion);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        AppSnackBar.error(context, 'Error al crear reunión: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Nueva Reunión',
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
                Icons.groups_rounded,
                color: Color(0xFF0F2B5B),
                size: 26,
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              children: [
                // ENCABEZADO CON ILUSTRACIÓN CIRCULAR
                _buildEncabezado(),
                const SizedBox(height: 14),

                // SECCIÓN 1: TEMA O ASUNTO
                _buildCardTema(),
                const SizedBox(height: 12),

                // SECCIÓN 2: FECHA DE LA REUNIÓN
                _buildCardFecha(),
                const SizedBox(height: 12),

                // SECCIÓN 3: MULTA POR FALTA
                _buildCardMulta(),
                const SizedBox(height: 12),

                // SECCIÓN 4: MODO DE LLAMADO DE LISTA
                _buildCardModoInicial(),
                const SizedBox(height: 20),

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
                'Convocatoria Sindical',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2B5B),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Registra una reunión oficial, define la fecha y la multa para los conductores ausentes.',
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
          child: const Icon(
            Icons.groups_rounded,
            color: Color(0xFF2563EB),
            size: 30,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CONTENEDOR BASE DE SECCIÓN TIPO TARJETA
  // ===========================================================================
  Widget _buildCardBase({
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
  // 1. TEMA O ASUNTO
  // ===========================================================================
  Widget _buildCardTema() {
    return _buildCardBase(
      icono: Icons.campaign_rounded,
      titulo: 'Tema o Asunto de la Reunión',
      subtitulo: 'Ingresa el motivo o asunto por el cual se convoca',
      child: TextFormField(
        controller: _temaCtrl,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)),
        decoration: InputDecoration(
          hintText: 'Ej. Reunión Ordinaria de Rutas',
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
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el tema de la reunión' : null,
      ),
    );
  }

  // ===========================================================================
  // 2. FECHA DE LA REUNIÓN
  // ===========================================================================
  Widget _buildCardFecha() {
    final fechaTexto = _formatearFechaTexto(_fechaSeleccionada);

    return _buildCardBase(
      icono: Icons.calendar_month_rounded,
      titulo: 'Fecha de la Reunión',
      subtitulo: 'Indica el día oficial en que se llevará a cabo',
      child: InkWell(
        onTap: _seleccionarFecha,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    fechaTexto[0].toUpperCase() + fechaTexto.substring(1),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2B5B),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. MULTA POR FALTA
  // ===========================================================================
  Widget _buildCardMulta() {
    final valorActual = double.tryParse(_multaCtrl.text.trim()) ?? 0.0;

    return _buildCardBase(
      icono: Icons.payments_rounded,
      titulo: 'Multa por Falta / Inasistencia',
      subtitulo: 'Monto que se sancionará a cada chofer ausente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips rápidos de montos sugeridos
          Row(
            children: _multasSugeridas.map((m) {
              final sel = (valorActual == m);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('Bs. ${m.toInt()}'),
                  selected: sel,
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : const Color(0xFF334155),
                    fontSize: 11.5,
                    fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: sel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                  onSelected: (_) => setState(() => _multaCtrl.text = m.toStringAsFixed(2)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Campo de monto
          TextFormField(
            controller: _multaCtrl,
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
              hintText: '50.00',
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
              final n = double.tryParse(v ?? '');
              if (n == null || n < 0) return 'Ingresa un monto válido';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. MODO DE LLAMADO DE LISTA
  // ===========================================================================
  Widget _buildCardModoInicial() {
    return _buildCardBase(
      icono: Icons.checklist_rounded,
      titulo: 'Modo de Llamado de Lista',
      subtitulo: 'Define el estado de asistencia inicial',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          value: _iniciarTodosPresentes,
          activeColor: const Color(0xFF10B981),
          title: const Text(
            'Iniciar a todos como "Presentes"',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
          ),
          subtitle: const Text(
            'Ahorra tiempo: solo marcarás Falta a los que no asistieron.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          onChanged: (val) => setState(() => _iniciarTodosPresentes = val),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTONES INFERIORES: CANCELAR (OUTLINE) Y GUARDAR (VERDE)
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
              onPressed: _guardando ? null : _crearReunion,
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
