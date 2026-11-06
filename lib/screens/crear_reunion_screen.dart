import 'package:flutter/material.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/app_snackbar.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);

/// Pantalla completa para la creación y convocatoria de una nueva reunión.
/// Rediseñada fielmente al diseño modular de tarjetas con cabecera curva verde corporativa.
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
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
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
            primary: _kVerdeOscuro,
            onPrimary: Colors.white,
            onSurface: _kVerdeOscuro,
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
    final topPadding = MediaQuery.of(context).padding.top;
    final valorActual = double.tryParse(_multaCtrl.text.trim()) ?? 0.0;

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
                    titulo: 'Reunión / Asamblea',
                    subtitulo:
                        'Convoca una asamblea oficial del sindicato y fija el valor de la multa por inasistencia.',
                    icono: Icons.gavel_rounded,
                  ),

                  const SizedBox(height: 16),

                  // TARJETA 1: TEMA O ASUNTO
                  _buildCardContainer(
                    icono: Icons.layers_rounded,
                    titulo: 'Tema o Asunto',
                    subtitulo: 'Motivo principal de la reunión o asamblea',
                    child: _buildInputContainer(
                      child: TextFormField(
                        controller: _temaCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Reunión Ordinaria de Rutas',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa el tema de la reunión'
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 2: MULTA POR FALTA
                  _buildCardContainer(
                    icono: Icons.payments_rounded,
                    titulo: 'Multa por Falta / Inasistencia',
                    subtitulo:
                        'Monto que se sancionará a cada chofer ausente',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chips rápidos de montos sugeridos
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _multasSugeridas.map((m) {
                              final sel = (valorActual == m);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => setState(() =>
                                      _multaCtrl.text = m.toStringAsFixed(2)),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: sel ? _kMintBg : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? _kVerdeOscuro
                                            : const Color(0xFFE2E8F0),
                                        width: sel ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      'Bs. ${m.toInt()}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight:
                                            sel ? FontWeight.bold : FontWeight.w600,
                                        color: sel
                                            ? _kVerdeOscuro
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Input de monto personalizado
                        _buildInputContainer(
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
                                  controller: _multaCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    hintText: '50.00',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  validator: (v) {
                                    final n = double.tryParse(v ?? '');
                                    if (n == null || n < 0) {
                                      return 'Ingresa un monto válido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 3: FECHA DE LA REUNIÓN
                  _buildCardContainer(
                    icono: Icons.calendar_month_rounded,
                    titulo: 'Fecha de la Reunión',
                    subtitulo: 'Indica el día oficial en que se llevará a cabo',
                    child: InkWell(
                      onTap: _seleccionarFecha,
                      borderRadius: BorderRadius.circular(14),
                      child: _buildInputContainer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_available_rounded,
                                  size: 18,
                                  color: _kVerdeOscuro,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatearFechaTexto(_fechaSeleccionada),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: _kVerdeOscuro,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 4: MODO DE LLAMADO DE LISTA
                  _buildCardContainer(
                    icono: Icons.checklist_rounded,
                    titulo: 'Modo de Asistencia Inicial',
                    subtitulo:
                        'Define cómo se precargará la lista de los 20 conductores',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRadioCard(
                            titulo: 'Presentes',
                            subtitulo: 'Todos presentes',
                            seleccionado: _iniciarTodosPresentes,
                            onTap: () =>
                                setState(() => _iniciarTodosPresentes = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRadioCard(
                            titulo: 'Falta',
                            subtitulo: 'Todos con falta',
                            seleccionado: !_iniciarTodosPresentes,
                            onTap: () =>
                                setState(() => _iniciarTodosPresentes = false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 5: INFORMACIÓN Y PROCESO
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: _kVerdeOscuro,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Control Automático de Multas',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _kVerdeOscuro,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Al pasar lista y cerrar la asamblea, a cada conductor con estado "Falta" se le generará automáticamente una cuota por cobrar de Bs. ${valorActual.toStringAsFixed(2)}.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 3. BARRA INFERIOR DE ACCIONES (CANCELAR Y CONVOCAR REUNIÓN)
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
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
          child: Icon(
            icono,
            color: _kVerdeOscuro,
            size: 28,
          ),
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
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
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
                child: Icon(
                  icono,
                  color: _kVerdeOscuro,
                  size: 20,
                ),
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
                      color: seleccionado ? _kVerdeOscuro : const Color(0xFF0F172A),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // BOTÓN CONVOCAR REUNIÓN / GUARDAR
          Expanded(
            child: ElevatedButton(
              onPressed: _guardando ? null : _crearReunion,
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
                        Icon(Icons.check_rounded, size: 20, color: Colors.white),
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
