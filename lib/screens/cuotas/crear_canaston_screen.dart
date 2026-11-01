import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/cronograma_cuotas.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import 'widgets/selector_conductores_sheet.dart';
import 'widgets/selector_dia_mes_dialog.dart';

/// Pantalla "Nueva cuota" para el Canastón / Ahorro Navideño.
/// Mismo diseño uniforme basado en tarjetas que Apoyo Económico:
/// - Encabezado limpio con ilustración temática.
/// - Tarjetas seccionales con icono y descripción.
/// - Selector de modalidad/frecuencia interactivo.
/// - Selector interactivo de conductores y resumen del cronograma.
/// - Botones inferiores simétricos Cancelar y Guardar.
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nombreCtrl = TextEditingController();
    _importeCtrl = TextEditingController();

    _fechaInicio = DateTime(now.year, now.month, now.day);
    // Fecha límite por defecto: 31 de diciembre del año en curso
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
          primary: Color(0xFF0F2B5B),
          onPrimary: Colors.white,
          onSurface: Color(0xFF0F2B5B),
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

  void _toggleSeleccionarTodos(bool? valor) {
    setState(() {
      if (valor == true) {
        _idsConductoresSeleccionados = _conductoresActivos
            .map((c) => c['id_conductor']?.toString())
            .whereType<String>()
            .toSet();
      } else {
        _idsConductoresSeleccionados.clear();
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;

    if (importe <= 0) {
      _mostrarSnack('Ingresa un importe válido mayor a 0 Bs.');
      return;
    }

    if (_idsConductoresSeleccionados.isEmpty) {
      _mostrarSnack('Selecciona al menos un conductor.');
      return;
    }

    final cronograma = _calcularCronogramaActual();
    if (cronograma.isEmpty) {
      _mostrarSnack('Con las fechas y día seleccionados no se genera ningún cobro.');
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
        '¡$nombre creado! Se generaron ${cronograma.length} cuotas para ${_idsConductoresSeleccionados.length} conductores.',
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
    final cronograma = _calcularCronogramaActual();
    final totalConductores = _conductoresActivos.length;
    final seleccionadosCount = _idsConductoresSeleccionados.length;
    final todosSeleccionados = totalConductores > 0 && seleccionadosCount == totalConductores;

    final importe = double.tryParse(_importeCtrl.text.trim()) ?? 0.0;
    final totalPorConductor = importe * cronograma.length;

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
          'Nueva cuota',
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
                      // ENCABEZADO CON ILUSTRACIÓN CIRCULAR
                      _buildEncabezado(),
                      const SizedBox(height: 14),

                      // SECCIÓN 1: NOMBRE DE LA CUOTA
                      _buildSeccionNombre(),
                      const SizedBox(height: 12),

                      // SECCIÓN 2: IMPORTE
                      _buildSeccionImporte(),
                      const SizedBox(height: 12),

                      // SECCIÓN 3: FRECUENCIA (SEMANAL / MENSUAL)
                      _buildSeccionFrecuencia(),
                      const SizedBox(height: 12),

                      // SECCIÓN 4: DÍA DE COBRO
                      _buildSeccionDiaCobro(),
                      const SizedBox(height: 12),

                      // SECCIÓN 5: PERIODO DE COBRO (FECHAS)
                      _buildSeccionFechas(),
                      const SizedBox(height: 12),

                      // SECCIÓN 6: CONDUCTORES PARTICIPANTES Y CRONOGRAMA
                      _buildSeccionConductores(
                        cronograma: cronograma,
                        seleccionadosCount: seleccionadosCount,
                        todosSeleccionados: todosSeleccionados,
                        totalPorConductor: totalPorConductor,
                      ),
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
  // ENCABEZADO PRINCIPAL CON ILUSTRACIÓN
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
                'Canastón / Ahorro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2B5B),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Programa un fondo de cuotas periódicas (semanal o mensual) para el canastón o ahorro de fin de año.',
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
            Icons.card_giftcard_rounded,
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
  // 1. NOMBRE DE LA CUOTA
  // ===========================================================================
  Widget _buildSeccionNombre() {
    return _buildCardBase(
      icono: Icons.edit_note_rounded,
      titulo: 'Nombre de la Cuota',
      subtitulo: 'Identifica el fondo o concepto de ahorro',
      child: TextFormField(
        controller: _nombreCtrl,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)),
        decoration: InputDecoration(
          hintText: 'Ej. Canastón Navideño',
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
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return 'Ingresa el nombre de la cuota';
          }
          return null;
        },
      ),
    );
  }

  // ===========================================================================
  // 2. IMPORTE POR CONDUCTOR
  // ===========================================================================
  Widget _buildSeccionImporte() {
    return _buildCardBase(
      icono: Icons.payments_rounded,
      titulo: 'Importe por Conductor',
      subtitulo: 'Monto en Bolivianos (Bs.) por cada cuota periódica',
      child: TextFormField(
        controller: _importeCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
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
          hintText: 'Ej. 10',
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
        validator: (val) {
          final n = double.tryParse(val ?? '');
          if (n == null || n <= 0) {
            return 'Ingresa un importe válido mayor a 0';
          }
          return null;
        },
      ),
    );
  }

  // ===========================================================================
  // 3. FRECUENCIA DEL APORTE (SEMANAL VS MENSUAL)
  // ===========================================================================
  Widget _buildSeccionFrecuencia() {
    final esMensual = _frecuencia == 'mensual';
    return _buildCardBase(
      icono: Icons.tune_rounded,
      titulo: 'Frecuencia del Aporte',
      subtitulo: 'Elige cómo se distribuirá el calendario de cobros',
      child: Row(
        children: [
          // SEMANAL
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _frecuencia = 'semanal'),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                  color: !esMensual ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !esMensual ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    width: !esMensual ? 1.5 : 1,
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
                          color: !esMensual ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          width: !esMensual ? 5 : 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Semanal',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2B5B),
                            ),
                          ),
                          Text(
                            'Cada semana',
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

          // MENSUAL
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _frecuencia = 'mensual'),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                  color: esMensual ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: esMensual ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    width: esMensual ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      esMensual ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 18,
                      color: esMensual ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensual',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            'Una vez al mes',
                            style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (esMensual)
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
  // 4. DÍA DE COBRO
  // ===========================================================================
  Widget _buildSeccionDiaCobro() {
    return _buildCardBase(
      icono: Icons.calendar_today_rounded,
      titulo: 'Día de Cobro',
      subtitulo: _frecuencia == 'semanal'
          ? 'Día de la semana fijado para recaudar'
          : 'Día del mes fijado para recaudar',
      child: _frecuencia == 'semanal'
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _diaSemana,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F2B5B)),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Lunes', style: TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)))),
                    DropdownMenuItem(value: 2, child: Text('Martes', style: TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)))),
                    DropdownMenuItem(value: 3, child: Text('Miércoles', style: TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)))),
                    DropdownMenuItem(value: 4, child: Text('Jueves', style: TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)))),
                    DropdownMenuItem(value: 5, child: Text('Viernes', style: TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)))),
                    DropdownMenuItem(value: 6, child: Text('Sábado', style: TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)))),
                    DropdownMenuItem(value: 7, child: Text('Domingo', style: TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _diaSemana = val);
                  },
                ),
              ),
            )
          : InkWell(
              onTap: _abrirSelectorDiaMes,
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
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _esFinDeMes ? 'Fin de mes (último día válido)' : 'Día $_diaMes de cada mes',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F2B5B),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ===========================================================================
  // 5. PERIODO DE COBRO (FECHAS)
  // ===========================================================================
  Widget _buildSeccionFechas() {
    return _buildCardBase(
      icono: Icons.date_range_rounded,
      titulo: 'Periodo de Cobro',
      subtitulo: 'Fecha de inicio y fecha límite opcional',
      child: Row(
        children: [
          // FECHA DE INICIO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha de inicio',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F2B5B)),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _seleccionarFechaInicio,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0F2B5B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateFmt.format(_fechaInicio),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // FECHA LÍMITE (OPCIONAL)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha límite (opcional)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F2B5B)),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _seleccionarFechaLimite,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0F2B5B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fechaLimite != null ? _dateFmt.format(_fechaLimite!) : 'Sin límite',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
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
    );
  }

  // ===========================================================================
  // 6. CONDUCTORES PARTICIPANTES Y CRONOGRAMA
  // ===========================================================================
  Widget _buildSeccionConductores({
    required List<DateTime> cronograma,
    required int seleccionadosCount,
    required bool todosSeleccionados,
    required double totalPorConductor,
  }) {
    return _buildCardBase(
      icono: Icons.people_alt_rounded,
      titulo: 'Conductores Participantes',
      subtitulo: '$seleccionadosCount compañeros participando',
      trailing: OutlinedButton.icon(
        onPressed: _cargandoConductores ? null : _abrirSelectorConductores,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox interactivo "Seleccionar todos"
          InkWell(
            onTap: () => _toggleSeleccionarTodos(!todosSeleccionados),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: todosSeleccionados,
                      activeColor: const Color(0xFF0F2B5B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: _toggleSeleccionarTodos,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Seleccionar todos los conductores activos',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2B5B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tarjeta verde con cronograma calculado
          if (cronograma.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Se generarán ${cronograma.length} cuotas periódicas',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Primera: ${_dateFmt.format(cronograma.first)}  ·  Última: ${_dateFmt.format(cronograma.last)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                        ),
                        if (totalPorConductor > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              'Meta estimada por chofer: Bs. ${totalPorConductor.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                      ],
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
                backgroundColor: const Color(0xFF00B074), // Verde idéntico a Apoyo Económico
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
