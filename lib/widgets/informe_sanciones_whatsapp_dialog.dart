import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/cuotas/widgets/dialogo_informe_whatsapp.dart';

/// Diálogo y generador oficial del Informe Diario de Sanciones y Tardanzas
/// para la Mesa Directiva del Sindicato Continental vía WhatsApp.
///
/// Automatiza:
/// 1. Registro de tardanzas detectadas (hora de llegada y minutos de retraso).
/// 2. Control de cumplimiento de vueltas adicionales de castigo (asignadas, cumplidas y pendientes).
/// 3. Generación y envío instantáneo del reporte para la Directiva sin redacción manual.
class InformeSancionesWhatsappDialog extends StatefulWidget {
  final List<Map<String, dynamic>> sanciones;
  final String horaLimite;

  const InformeSancionesWhatsappDialog({
    super.key,
    required this.sanciones,
    required this.horaLimite,
  });

  /// Abre el modal de vista previa y envío del informe a la Directiva.
  static Future<void> mostrar(
    BuildContext context, {
    required List<Map<String, dynamic>> sanciones,
    required String horaLimite,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InformeSancionesWhatsappDialog(
        sanciones: sanciones,
        horaLimite: horaLimite,
      ),
    );
  }

  /// Construye el texto oficial con formato profesional para WhatsApp.
  static String construirTextoInforme({
    required List<Map<String, dynamic>> sanciones,
    required String horaLimite,
    String? notaAdicional,
  }) {
    final now = DateTime.now();
    final fechaTexto = _formatearFechaLarga(now);

    final total = sanciones.length;
    int cumplidas = 0;
    int enCurso = 0;
    int vueltasAsignadas = 0;
    int vueltasCumplidas = 0;

    for (final s in sanciones) {
      final estado = s['estado']?.toString().toLowerCase() ?? '';
      final asig = (s['vueltas_asignadas'] as num?)?.toInt() ?? 2;
      final cump = (s['vueltas_cumplidas'] as num?)?.toInt() ?? 0;

      vueltasAsignadas += asig;
      vueltasCumplidas += cump;

      if (estado == 'cumplida' || (asig > 0 && cump >= asig)) {
        cumplidas++;
      } else {
        enCurso++;
      }
    }

    final vueltasPendientes = (vueltasAsignadas - vueltasCumplidas).clamp(0, 9999);

    final sb = StringBuffer();
    sb.writeln('📋 *SINDICATO MIXTO DE TRANSPORTES "CONTINENTAL"*');
    sb.writeln('🏛️ *INFORME DIARIO DE SANCIONES Y TARDANZAS*');
    sb.writeln('📅 *Fecha:* $fechaTexto');
    sb.writeln('⏰ *Horario Oficial de Entrada:* 07:30 AM');
    sb.writeln('⏱️ *Horario Límite de Control:* $horaLimite (Tolerancia: 30 min)');
    sb.writeln('👮 *Destinado a:* Mesa Directiva y Control de Operaciones');
    sb.writeln();
    sb.writeln('════════════════════════════');
    sb.writeln('📊 *RESUMEN DE CONTROL DEL DÍA:*');
    sb.writeln('• 🚨 *Total Sanciones por Atraso:* $total');
    sb.writeln('• ⏳ *En Curso (Cumpliendo vueltas):* $enCurso');
    sb.writeln('• ✅ *Cumplidas (Sanción levantada):* $cumplidas');
    sb.writeln('• 🔄 *Vueltas de Castigo Asignadas:* $vueltasAsignadas (+2 por chofer)');
    sb.writeln('• 🏁 *Vueltas de Castigo Cumplidas:* $vueltasCumplidas');
    sb.writeln('• ⚠️ *Vueltas de Castigo Pendientes:* $vueltasPendientes');
    sb.writeln('════════════════════════════');
    sb.writeln();

    if (sanciones.isEmpty) {
      sb.writeln('✨ *¡JORNADA EJEMPLAR!*');
      sb.writeln('Ningún conductor registró tardanza el día de hoy. Todos marcaron asistencia dentro del horario reglamentario (≤ $horaLimite).');
    } else {
      sb.writeln('🚗 *DETALLE DE CONDUCTORES SANCIONADOS:*');
      sb.writeln();

      for (int i = 0; i < sanciones.length; i++) {
        final s = sanciones[i];
        final nombre = s['conductor_nombre']?.toString() ?? 'Conductor';
        final llegada = s['hora']?.toString() ??
            s['hora_llegada']?.toString() ??
            '--:--';
        final retraso = (s['minutos_retraso'] as num?)?.toInt() ?? 0;
        final asig = (s['vueltas_asignadas'] as num?)?.toInt() ?? 2;
        final cump = (s['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
        final esCumplida = s['estado']?.toString().toLowerCase() == 'cumplida' ||
            (asig > 0 && cump >= asig);

        final iconoEstado = esCumplida ? '🟢' : (cump > 0 ? '🟡' : '🔴');
        final textoEstado = esCumplida
            ? 'CUMPLIDA (Castigo completado)'
            : 'EN CURSO (Faltan ${asig - cump} vueltas)';

        sb.writeln('${i + 1}. $iconoEstado *$nombre*');
        sb.writeln('   • ⏰ Llegada registrada: $llegada ${retraso > 0 ? '(+$retraso min de atraso)' : ''}');
        sb.writeln('   • 🔄 Progreso de vueltas: $cump de $asig cumplidas');
        sb.writeln('   • 📌 Estado: *$textoEstado*');
        sb.writeln('   • 🚫 Cierre en sistema: ${esCumplida ? 'Levantado / Concluido' : 'Bloqueado hasta completar vueltas'}');
        sb.writeln();
      }
    }

    sb.writeln('════════════════════════════');
    sb.writeln('🌙 *CONTROL NOCTURNO POR GPS:*');
    sb.writeln('Conforme a la reglamentación sindical, las vueltas de castigo se cumplen a partir de las 21:00 PM en el circuito Cruce Villadela ⇄ Teleférico Amarillo y son verificadas satelitalmente.');

    if (notaAdicional != null && notaAdicional.trim().isNotEmpty) {
      sb.writeln();
      sb.writeln('📝 *Observaciones de Administración:*');
      sb.writeln(notaAdicional.trim());
    }

    sb.writeln();
    sb.writeln('_Reporte automático generado por el Sistema de Control Continental._');

    return sb.toString().trim();
  }

  static String _formatearFechaLarga(DateTime f) {
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

    final nomDia = dias[(f.weekday - 1).clamp(0, 6)];
    final nomMes = meses[(f.month - 1).clamp(0, 11)];
    return '$nomDia, ${f.day.toString().padLeft(2, '0')} de $nomMes de ${f.year}';
  }

  @override
  State<InformeSancionesWhatsappDialog> createState() =>
      _InformeSancionesWhatsappDialogState();
}

class _InformeSancionesWhatsappDialogState
    extends State<InformeSancionesWhatsappDialog> {
  late TextEditingController _msgCtrl;
  final TextEditingController _notaCtrl = TextEditingController();
  bool _editando = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(
      text: InformeSancionesWhatsappDialog.construirTextoInforme(
        sanciones: widget.sanciones,
        horaLimite: widget.horaLimite,
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  void _regenerarTexto() {
    setState(() {
      _msgCtrl.text = InformeSancionesWhatsappDialog.construirTextoInforme(
        sanciones: widget.sanciones,
        horaLimite: widget.horaLimite,
        notaAdicional: _notaCtrl.text,
      );
    });
  }

  Future<void> _enviarWhatsApp() async {
    setState(() => _enviando = true);
    try {
      await DialogoInformeWhatsapp.lanzarWhatsappDirecto(
        context,
        texto: _msgCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¡Informe enviado a WhatsApp y copiado al portapapeles!',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _copiarTexto() async {
    await Clipboard.setData(ClipboardData(text: _msgCtrl.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texto del informe copiado al portapapeles.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sanciones.length;
    int enCurso = 0;
    int cumplidas = 0;
    for (final s in widget.sanciones) {
      final estado = s['estado']?.toString().toLowerCase() ?? '';
      final asig = (s['vueltas_asignadas'] as num?)?.toInt() ?? 2;
      final cump = (s['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
      if (estado == 'cumplida' || (asig > 0 && cump >= asig)) {
        cumplidas++;
      } else {
        enCurso++;
      }
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Barra de arrastre superior
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Encabezado del Modal con branding WhatsApp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF16A34A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informe Directiva WhatsApp',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Contenido desplazable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3 Métricas Rápidas
                  Row(
                    children: [
                      _metricPill(
                        'Sancionados',
                        '$total',
                        const Color(0xFFEF4444),
                        const Color(0xFFFEF2F2),
                      ),
                      const SizedBox(width: 8),
                      _metricPill(
                        'En curso',
                        '$enCurso',
                        const Color(0xFFD97706),
                        const Color(0xFFFEF3C7),
                      ),
                      const SizedBox(width: 8),
                      _metricPill(
                        'Cumplidas',
                        '$cumplidas',
                        const Color(0xFF16A34A),
                        const Color(0xFFF0FDF4),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Caja de Vista Previa estilo WhatsApp
                  Row(
                    children: [
                      const Icon(Icons.preview_rounded, size: 16, color: Color(0xFF02634C)),
                      const SizedBox(width: 6),
                      const Text(
                        'Vista previa del mensaje a enviar:',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _editando = !_editando);
                        },
                        icon: Icon(
                          _editando ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                          size: 16,
                          color: const Color(0xFF02634C),
                        ),
                        label: Text(
                          _editando ? 'Listo' : 'Editar',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF02634C),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEAE2), // Fondo clásico de WhatsApp chat
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: _editando
                          ? TextField(
                              controller: _msgCtrl,
                              maxLines: 12,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF0F172A),
                                height: 1.35,
                                fontFamily: 'monospace',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            )
                          : SelectableText(
                              _msgCtrl.text,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF0F172A),
                                height: 1.35,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Botón Copiar Texto
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _copiarTexto,
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                      label: const Text(
                        'Copiar texto completo',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Campo opcional de Nota Adicional
                  TextField(
                    controller: _notaCtrl,
                    onChanged: (_) => _regenerarTexto(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Agregar observación para la Directiva (opcional)',
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Botón Principal de Enviar a WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _enviarWhatsApp,
                      icon: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                      label: Text(
                        _enviando ? 'Abriendo WhatsApp...' : 'Enviar a la Directiva por WhatsApp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

  Widget _metricPill(String label, String valor, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

