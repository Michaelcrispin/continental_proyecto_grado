import 'package:flutter/material.dart';

/// Resultado de la selección del día del mes.
class DiaCobroMesResult {
  final int dia;
  final bool esFinDeMes;

  const DiaCobroMesResult({
    required this.dia,
    this.esFinDeMes = false,
  });
}

/// Diálogo modal interactivo para seleccionar el día del mes (1..31 o fin de mes).
/// Reemplaza los menús desplegables gigantes por una cuadrícula tipo calendario
/// moderna, compacta y táctil.
class SelectorDiaMesDialog extends StatefulWidget {
  final int diaActual;
  final bool esFinDeMes;

  const SelectorDiaMesDialog({
    super.key,
    required this.diaActual,
    this.esFinDeMes = false,
  });

  /// Muestra el diálogo modal y retorna el [DiaCobroMesResult] seleccionado o null si se cancela.
  static Future<DiaCobroMesResult?> mostrar(
    BuildContext context, {
    required int diaActual,
    bool esFinDeMes = false,
  }) {
    return showDialog<DiaCobroMesResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SelectorDiaMesDialog(
        diaActual: diaActual,
        esFinDeMes: esFinDeMes,
      ),
    );
  }

  @override
  State<SelectorDiaMesDialog> createState() => _SelectorDiaMesDialogState();
}

class _SelectorDiaMesDialogState extends State<SelectorDiaMesDialog> {
  late int _diaSeleccionado;
  late bool _esFinDeMes;

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = widget.diaActual.clamp(1, 31);
    _esFinDeMes = widget.esFinDeMes;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de calendario en cabecera
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF2563EB),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),

            // Título y subtítulo
            const Text(
              'Seleccionar día de pago',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F2B5B),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige el día de cada mes.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Cuadrícula de 31 días en 7 columnas
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 31,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final d = index + 1;
                final seleccionado = !_esFinDeMes && _diaSeleccionado == d;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _diaSeleccionado = d;
                      _esFinDeMes = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: seleccionado ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: seleccionado ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: seleccionado ? 1.5 : 1.0,
                      ),
                      boxShadow: seleccionado
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
                        color: seleccionado ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Opción complementaria: Fin de mes
            InkWell(
              onTap: () {
                setState(() {
                  _esFinDeMes = true;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _esFinDeMes ? const Color(0xFFEFF6FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _esFinDeMes ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _esFinDeMes ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 16,
                      color: _esFinDeMes ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fin de mes (último día válido)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _esFinDeMes ? FontWeight.bold : FontWeight.w500,
                        color: _esFinDeMes ? const Color(0xFF2563EB) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tarjeta de confirmación visual del día seleccionado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Día seleccionado:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _esFinDeMes
                              ? 'Fin de mes (último día del mes)'
                              : 'Día $_diaSeleccionado de cada mes',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2B5B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botón de Aceptar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    DiaCobroMesResult(
                      dia: _diaSeleccionado,
                      esFinDeMes: _esFinDeMes,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
                    fontSize: 15,
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
}

