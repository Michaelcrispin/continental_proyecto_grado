import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/cronograma_cuotas.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_snackbar.dart';
import 'widgets/selector_conductores_sheet.dart';
import 'widgets/selector_dia_mes_dialog.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);

/// Pantalla "Nueva cuota" para el Canastón / Ahorro Navideño.
/// Rediseñada fielmente al diseño modular de tarjetas con cabecera curva verde corporativa.
class CrearCanastonScreen extends StatefulWidget {
  const CrearCanastonScreen({super.key});

  @override
  State<CrearCanastonScreen> createState() => _CrearCanastonScreenState();
}

class _CrearCanastonScreenState extends State<CrearCanastonScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _importeCtrl;

  String _frecuencia = 'semanal'; // 'semanal' | 'mensual'
  int _diaSemana = 2; // 2 = Martes
  int _diaMes = 11; // Día 11 por defecto
  bool _esFinDeMes = false;

  late DateTime _fechaInicio;
  DateTime? _fechaLimite;

  List<Map<String, dynamic>> _conductoresActivos = [];
  Set<String> _idsConductoresSeleccionados = {};
  bool _cargandoConductores = true;
  bool _guardando = false;

  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  final List<String> _diasNombres = const [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nombreCtrl = TextEditingController();
    _importeCtrl = TextEditingController();

    _fechaInicio = DateTime(now.year, now.month, now.day);
    _fechaLimite = DateTime(now.year, 12, 31);

    _cargarConductores();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _importeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    try {
      final lista = await EconomiaRepo.instance.listarConductoresActivos();
      if (mounted) {
        setState(() {
          _conductoresActivos = lista;
          _idsConductoresSeleccionados = lista
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

  List<DateTime> _calcularCronogramaActual() {
    final limite = _fechaLimite ?? DateTime(_fechaInicio.year, 12, 31);
    return CronogramaCuotas.generarFechas(
      fechaInicio: _fechaInicio,
      fechaLimite: limite,
      frecuencia: _frecuencia,
      diaSemana: _diaSemana,
      diaMes: _diaMes,
      esFinDeMes: _esFinDeMes,
    );
  }

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => _tematizarPicker(child),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        if (_fechaLimite != null && _fechaLimite!.isBefore(_fechaInicio)) {
          _fechaLimite = _fechaInicio.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _seleccionarFechaLimite() async {
    final inicial = _fechaLimite ?? DateTime(_fechaInicio.year, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(_fechaInicio) ? _fechaInicio : inicial,
      firstDate: _fechaInicio,
      lastDate: DateTime(2035),
      builder: (context, child) => _tematizarPicker(child),
    );
    if (picked != null) {
      setState(() => _fechaLimite = picked);
    }
  }

  Widget _tematizarPicker(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _kVerdeOscuro,
          onPrimary: Colors.white,
          onSurface: _kVerdeOscuro,
        ),
      ),
      child: child ?? const SizedBox(),
    );
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
      });
    }
  }

  Future<void> _abrirSelectorConductores() async {
    final resultado = await SelectorConductoresSheet.mostrar(
      context,
      todosConductores: _conductoresActivos,
      idsSeleccionados: _idsConductoresSeleccionados,
    );
    if (resultado != null && mounted) {
      setState(() => _idsConductoresSeleccionados = resultado);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;

    if (importe < 1) {
      _mostrarSnack('El importe mínimo por cuota es Bs. 1.00.');
      return;
    }

    if (_idsConductoresSeleccionados.isEmpty) {
      _mostrarSnack('Selecciona al menos un conductor.');
      return;
    }

    final cronograma = _calcularCronogramaActual();
    if (cronograma.isEmpty) {
      _mostrarSnack(
        'Con las fechas y día seleccionados no se genera ningún cobro.',
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final idUsuario = SesionService.instance.idUsuario ?? 'admin';
      final reglaDiaStr = _frecuencia == 'semanal'
          ? CronogramaCuotas.nombreDiaSemana(_diaSemana)
          : (_esFinDeMes ? 'Fin de mes' : 'Día $_diaMes de cada mes');

      await EconomiaRepo.instance.crearCanastonConCronograma(
        nombre: nombre,
        importeCuota: importe,
        frecuencia: _frecuencia,
        reglaDia: reglaDiaStr,
        fechasCronograma: cronograma,
        idsConductores: _idsConductoresSeleccionados.toList(),
        idUsuario: idUsuario,
      );

      if (!mounted) return;
      AppSnackBar.exito(
        context,
        '¡$nombre creado! Se programaron ${cronograma.length} cuotas para ${_idsConductoresSeleccionados.length} conductores.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _mostrarSnack('Error: $e');
      }
    }
  }

  void _mostrarSnack(String mensaje) {
    AppSnackBar.error(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final cronograma = _calcularCronogramaActual();
    final seleccionadosCount = _idsConductoresSeleccionados.length;
    final totalConductores = _conductoresActivos.length;
    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;
    final totalPorConductor = importe * cronograma.length;

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
                    titulo: 'Canastón / Ahorro',
                    subtitulo:
                        'Programa un fondo de cuotas periódicas (semanal o mensual) para el canastón o ahorro de fin de año.',
                    icono: Icons.card_giftcard_rounded,
                  ),

                  const SizedBox(height: 16),

                  // TARJETA 1: NOMBRE DE LA CUOTA
                  _buildCardContainer(
                    icono: Icons.layers_rounded,
                    titulo: 'Nombre de la Cuota',
                    subtitulo: 'Identifica el fondo o concepto de ahorro',
                    child: _buildInputContainer(
                      child: TextFormField(
                        controller: _nombreCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Canastón Navideño',
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
                            return 'Por favor ingresa un nombre para la cuota';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 2: IMPORTE POR CONDUCTOR
                  _buildCardContainer(
                    icono: Icons.person_rounded,
                    titulo: 'Importe por Conductor',
                    subtitulo:
                        'Monto en Bolivianos (Bs.) por cada cuota periódica',
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
                                hintText: 'Ej. 10',
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

                  // TARJETA 3: FRECUENCIA DEL APORTE
                  _buildCardContainer(
                    icono: Icons.calendar_today_rounded,
                    titulo: 'Frecuencia del Aporte',
                    subtitulo:
                        'Elige cómo se distribuirá el calendario de cobros',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRadioCard(
                            titulo: 'Semanal',
                            subtitulo: 'Cada semana',
                            seleccionado: _frecuencia == 'semanal',
                            onTap: () =>
                                setState(() => _frecuencia = 'semanal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRadioCard(
                            titulo: 'Mensual',
                            subtitulo: 'Una vez al mes',
                            seleccionado: _frecuencia == 'mensual',
                            onTap: () =>
                                setState(() => _frecuencia = 'mensual'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 4: DÍA DE COBRO
                  _buildCardContainer(
                    icono: Icons.edit_calendar_rounded,
                    titulo: 'Día de Cobro',
                    subtitulo: _frecuencia == 'semanal'
                        ? 'Día de la semana fijado para recaudar'
                        : 'Día del mes fijado para recaudar',
                    child: _frecuencia == 'semanal'
                        ? _buildInputContainer(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _diaSemana,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF64748B),
                                  size: 22,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                items: List.generate(7, (i) {
                                  return DropdownMenuItem<int>(
                                    value: i + 1,
                                    child: Text(_diasNombres[i]),
                                  );
                                }),
                                onChanged: (nuevo) {
                                  if (nuevo != null) {
                                    setState(() => _diaSemana = nuevo);
                                  }
                                },
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: _abrirSelectorDiaMes,
                            borderRadius: BorderRadius.circular(14),
                            child: _buildInputContainer(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _esFinDeMes
                                        ? 'Último día del mes (Fin de mes)'
                                        : 'Día $_diaMes de cada mes',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF64748B),
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 5: PERIODO DE COBRO
                  _buildCardContainer(
                    icono: Icons.access_time_rounded,
                    titulo: 'Periodo de Cobro',
                    subtitulo: 'Fecha de inicio y fecha límite opcional',
                    child: Row(
                      children: [
                        // Fecha de inicio
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha de inicio',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _seleccionarFechaInicio,
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
                                      Text(
                                        _dateFmt.format(_fechaInicio),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Fecha límite
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha límite (opcional)',
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
                                          _fechaLimite != null
                                              ? _dateFmt.format(_fechaLimite!)
                                              : 'Sin límite',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TARJETA 6: CONDUCTORES PARTICIPANTES
                  _buildCardContainer(
                    icono: Icons.groups_rounded,
                    titulo: 'Conductores Participantes',
                    subtitulo: 'Conductores que aportarán a esta cuota',
                    child: InkWell(
                      onTap: _cargandoConductores
                          ? null
                          : _abrirSelectorConductores,
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
                                    '$seleccionadosCount / $totalConductores',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _kVerdeOscuro,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  seleccionadosCount == totalConductores
                                      ? 'Todos incluidos'
                                      : '$seleccionadosCount seleccionados',
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
                              Icons.calculate_rounded,
                              color: _kVerdeOscuro,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Resumen de Recaudación Proyectada',
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
                              titulo: 'Cuotas',
                              valor: '${cronograma.length}',
                            ),
                            _buildResumenDato(
                              titulo: 'Por Conductor',
                              valor:
                                  'Bs. ${totalPorConductor.toStringAsFixed(2)}',
                            ),
                            _buildResumenDato(
                              titulo: 'Fondo Estimado',
                              valor:
                                  'Bs. ${(totalPorConductor * seleccionadosCount).toStringAsFixed(2)}',
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
