import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/cronograma_cuotas.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import 'widgets/selector_conductores_sheet.dart';

/// Pantalla "Nueva cuota" para el Canastón / Ahorro Navideño.
/// Implementa fielmente la interfaz del diseño mockup:
/// - Nombre de la cuota
/// - Importe por conductor (Bs.)
/// - Frecuencia (Semanal / Mensual)
/// - Día de cobro dinámico (días de semana o días 1..28 / Fin de mes)
/// - Fecha de inicio y Fecha límite (opcional)
/// - Selector interactivo de conductores activos
/// - Resumen en tiempo real del cronograma generado
/// - Botones: Cancelar y Guardar
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡$nombre creado! Se generaron ${cronograma.length} cuotas para ${_idsConductoresSeleccionados.length} conductores.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
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
            fontSize: 20,
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                // 1. NOMBRE DE LA CUOTA
                _buildLabel('Nombre de la cuota'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F2B5B)),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa el nombre de la cuota';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(hint: 'Ej. Canastón Navideño'),
                ),

                const SizedBox(height: 16),

                // 2. IMPORTE POR CONDUCTOR (Bs.)
                _buildLabel('Importe por conductor (Bs.)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _importeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F2B5B), fontWeight: FontWeight.bold),
                  validator: (val) {
                    final n = double.tryParse(val ?? '');
                    if (n == null || n <= 0) {
                      return 'Ingresa un importe válido mayor a 0';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(hint: 'Ej. 10'),
                ),

                const SizedBox(height: 16),

                // 3. FRECUENCIA (DROPDOWN)
                _buildLabel('Frecuencia'),
                const SizedBox(height: 6),
                _buildDropdownContainer(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _frecuencia,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F2B5B)),
                      items: const [
                        DropdownMenuItem(
                          value: 'semanal',
                          child: Text('Semanal', style: TextStyle(fontSize: 14, color: Color(0xFF0F2B5B))),
                        ),
                        DropdownMenuItem(
                          value: 'mensual',
                          child: Text('Mensual', style: TextStyle(fontSize: 14, color: Color(0xFF0F2B5B))),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _frecuencia = val;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. DÍA DE COBRO (DINÁMICO SEGÚN FRECUENCIA)
                _buildLabel('Día de cobro'),
                const SizedBox(height: 6),
                if (_frecuencia == 'semanal')
                  _buildDropdownContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _diaSemana,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F2B5B)),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Lunes', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 2, child: Text('Martes', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 3, child: Text('Miércoles', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 4, child: Text('Jueves', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 5, child: Text('Viernes', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 6, child: Text('Sábado', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 7, child: Text('Domingo', style: TextStyle(fontSize: 14))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _diaSemana = val);
                        },
                      ),
                    ),
                  )
                else
                  _buildDropdownContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _esFinDeMes ? 'fin_de_mes' : _diaMes.toString(),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F2B5B)),
                        items: [
                          ...List.generate(28, (i) {
                            final d = i + 1;
                            return DropdownMenuItem<String>(
                              value: d.toString(),
                              child: Text('Día $d de cada mes', style: const TextStyle(fontSize: 14)),
                            );
                          }),
                          const DropdownMenuItem<String>(
                            value: 'fin_de_mes',
                            child: Text(
                              'Fin de mes (último día válido)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              if (val == 'fin_de_mes') {
                                _esFinDeMes = true;
                              } else {
                                _esFinDeMes = false;
                                _diaMes = int.tryParse(val) ?? 11;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // 5. FECHA DE INICIO
                _buildLabel('Fecha de inicio'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _seleccionarFechaInicio,
                  borderRadius: BorderRadius.circular(14),
                  child: _buildDateDisplay(_dateFmt.format(_fechaInicio)),
                ),

                const SizedBox(height: 16),

                // 6. FECHA LÍMITE (OPCIONAL)
                _buildLabel('Fecha límite (opcional)'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _seleccionarFechaLimite,
                  borderRadius: BorderRadius.circular(14),
                  child: _buildDateDisplay(
                    _fechaLimite != null ? _dateFmt.format(_fechaLimite!) : 'dd/mm/aaaa',
                  ),
                ),

                const SizedBox(height: 18),

                // 7. CONDUCTORES
                _buildLabel('Conductores'),
                const SizedBox(height: 4),

                // Checkbox: Seleccionar todos
                Row(
                  children: [
                    Checkbox(
                      value: todosSeleccionados,
                      activeColor: const Color(0xFF0F2B5B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: _toggleSeleccionarTodos,
                    ),
                    GestureDetector(
                      onTap: () => _toggleSeleccionarTodos(!todosSeleccionados),
                      child: const Text(
                        'Seleccionar todos',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F2B5B),
                        ),
                      ),
                    ),
                  ],
                ),

                // Fila / Tarjeta interactiva: N conductores seleccionados >
                InkWell(
                  onTap: _cargandoConductores ? null : _abrirSelectorConductores,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _cargandoConductores
                                ? 'Cargando conductores...'
                                : '$seleccionadosCount conductores seleccionados',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F2B5B),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // TARJETA DE VISTA PREVIA DEL CRONOGRAMA
                if (cronograma.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_available_rounded, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Se generarán ${cronograma.length} cuotas periódicas',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Primera: ${_dateFmt.format(cronograma.first)}  ·  Última: ${_dateFmt.format(cronograma.last)}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                              ),
                              if (totalPorConductor > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Meta total por conductor: Bs. ${totalPorConductor.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
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

                const SizedBox(height: 28),

                // BOTONES INFERIORES: CANCELAR (OUTLINE) Y GUARDAR (VERDE)
                Row(
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
                            backgroundColor: const Color(0xFF00B074), // Verde idéntico al mockup
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F2B5B),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F2B5B), width: 1.5),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: child,
    );
  }

  Widget _buildDateDisplay(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            texto,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F2B5B)),
          ),
          const Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}
