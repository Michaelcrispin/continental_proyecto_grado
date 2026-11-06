import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/avatar_conductor.dart';
import '../widgets/informe_sanciones_whatsapp_dialog.dart';

const _kVerdeContinental = Color(0xFF02634C);
const _kVerdeOscuro = Color(0xFF064E3B);
const _kVerdeClaro = Color(0xFFE6F4F0);
const _kVerdeActivo = Color(0xFF10B981);
const _kTexto = Color(0xFF0F172A);
const _kSlate = Color(0xFF64748B);
const _kBorde = Color(0xFFE2E8F0);
const _kFondo = Color(0xFFF8FAFC);

/// Pantalla de Reportes e Informes Consolidados de la Jornada (HU07 | RF15-RF16).
/// Diseño Corporativo Verde Sindicato Continental (#02634C).
class InformesScreen extends StatefulWidget {
  const InformesScreen({super.key});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _resumen = {};
  List<Map<String, dynamic>> _tardanzasDetalle = [];
  List<Map<String, dynamic>> _sancionesHoy = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.sincronizarHorariosSanciones();
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final datos = await DatabaseHelper.instance.resumenInformesHoy();
      final asistenciasHoy =
          await DatabaseHelper.instance.asistenciasDetalle(fecha: hoy);
      final sanciones = await DatabaseHelper.instance.sancionesDetalle();

      final tardanzasHoy = asistenciasHoy.where((a) {
        final st = a['estado']?.toString().toLowerCase();
        final minRetraso = (a['minutos_retraso'] as num?)?.toInt() ?? 0;
        return st == 'tardanza' || minRetraso > 0;
      }).toList();

      final listaTardanzas = <Map<String, dynamic>>[];
      for (final t in tardanzasHoy) {
        final idC = t['id_conductor']?.toString() ?? '';
        final nom = t['conductor_nombre']?.toString() ?? 'Conductor';
        final foto = t['conductor_foto']?.toString();
        final hora = t['hora_llegada']?.toString() ?? '--:--';
        final atrasoMin = (t['minutos_retraso'] as num?)?.toInt() ?? 0;
        final punto = t['punto_nombre']?.toString() ?? 'Cruce Villadela';

        Map<String, dynamic>? sancion;
        for (final s in sanciones) {
          if (s['id_conductor'] == idC &&
              (s['fecha'] == hoy || s['estado'] == 'pendiente') &&
              (s['tipo'] == 'tardanza' ||
                  (s['vueltas_asignadas'] as num? ?? 0) > 0)) {
            sancion = s;
            break;
          }
        }

        final vueltasAsignadas =
            (sancion?['vueltas_asignadas'] as num?)?.toInt() ?? 2;
        final vueltasCumplidas =
            (sancion?['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
        final estadoSancion =
            sancion?['estado']?.toString().toLowerCase() ?? 'pendiente';
        final cumplido =
            estadoSancion == 'cumplida' || vueltasCumplidas >= vueltasAsignadas;

        final String textoSancion = cumplido
            ? 'Cumplida ($vueltasAsignadas/$vueltasAsignadas)'
            : 'En curso ($vueltasCumplidas/$vueltasAsignadas)';

        listaTardanzas.add({
          'conductor': nom,
          'foto': foto,
          'hora': hora,
          'atraso': atrasoMin > 0 ? '+$atrasoMin min' : 'Tardanza',
          'punto': punto,
          'sancion': textoSancion,
          'cumplido': cumplido,
        });
      }

      if (mounted) {
        setState(() {
          _resumen = datos;
          _tardanzasDetalle = listaTardanzas;
          _sancionesHoy = sanciones;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatearFechaHoy() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = now.year.toString();
    return 'Hoy $d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final totalConductores =
        (_resumen['total_conductores'] as num?)?.toInt() ?? 0;
    final aTiempo = (_resumen['a_tiempo'] as num?)?.toInt() ?? 0;
    final tardanzasCount = _tardanzasDetalle.length;
    final totalVueltas = (_resumen['total_vueltas'] as num?)?.toInt() ?? 0;
    final cajaHoy = (_resumen['caja_hoy'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: _kFondo,
      body: Column(
        children: [
          _buildCurvedHeader(topPad),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _kVerdeContinental,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    color: _kVerdeContinental,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Tarjeta Ejecutiva Consolidada en Verde Continental
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kVerdeContinental, _kVerdeOscuro],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _kVerdeContinental.withValues(alpha: 0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Consolidado Oficial • ${_formatearFechaHoy()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Horario de entrada: 07:30 - 08:00 AM',
                                        style: TextStyle(
                                          color: Color(0xFFD1FAE5),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. 4 Métricas Globales del Día
                          Row(
                            children: [
                              _buildMetricCard(
                                icon: Icons.check_circle_rounded,
                                color: _kVerdeContinental,
                                bg: _kVerdeClaro,
                                borderColor: const Color(0xFFA7F3D0),
                                valor: '$aTiempo / $totalConductores',
                                titulo: 'A Tiempo',
                                subtitulo: '07:30 - 08:00 AM',
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFD97706),
                                bg: const Color(0xFFFFFBEB),
                                borderColor: const Color(0xFFFDE68A),
                                valor: '$tardanzasCount Choferes',
                                titulo: 'Llegaron Tarde',
                                subtitulo: 'Con +2 vueltas',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildMetricCard(
                                icon: Icons.loop_rounded,
                                color: _kVerdeContinental,
                                bg: Colors.white,
                                borderColor: _kBorde,
                                valor: '$totalVueltas Vueltas',
                                titulo: 'Vueltas GPS Hoy',
                                subtitulo: 'Cruce ⇄ Teleférico',
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                icon: Icons.payments_rounded,
                                color: _kVerdeActivo,
                                bg: Colors.white,
                                borderColor: _kBorde,
                                valor: 'Bs. ${cajaHoy.toStringAsFixed(0)}',
                                titulo: 'Caja del Día',
                                subtitulo: 'Cuotas y Aportes',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. SECCIÓN DE CONDUCTORES CON TARDANZA (> 08:00 AM)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _tardanzasDetalle.isEmpty
                                    ? const Color(0xFFA7F3D0)
                                    : _kBorde,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: _kVerdeContinental,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _tardanzasDetalle.isEmpty
                                            ? Icons.check_circle_rounded
                                            : Icons.schedule_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _tardanzasDetalle.isEmpty
                                              ? 'Puntualidad en la Jornada (Sin tardanzas)'
                                              : 'Conductores que Llegaron Tarde (> 08:00 AM)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_tardanzasDetalle.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 22,
                                      horizontal: 16,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            color: _kVerdeActivo,
                                            size: 36,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Ningún conductor tiene tardanza hoy.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _kVerdeContinental,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _tardanzasDetalle.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      height: 1,
                                      color: _kBorde,
                                    ),
                                    itemBuilder: (context, index) {
                                      final t = _tardanzasDetalle[index];
                                      final cumplido = t['cumplido'] as bool;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            AvatarConductor(
                                              foto: t['foto']?.toString(),
                                              nombre:
                                                  t['conductor'].toString(),
                                              radio: 18,
                                              fontSize: 11,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    t['conductor'].toString(),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: _kTexto,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Llegó: ${t['hora']} (${t['atraso']}) • ${t['punto']}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: _kSlate,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: cumplido
                                                    ? const Color(0xFFECFDF5)
                                                    : const Color(0xFFFFFBEB),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: cumplido
                                                      ? const Color(0xFFA7F3D0)
                                                      : const Color(0xFFFDE68A),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    cumplido
                                                        ? Icons
                                                            .check_circle_rounded
                                                        : Icons
                                                            .schedule_rounded,
                                                    size: 13,
                                                    color: cumplido
                                                        ? _kVerdeContinental
                                                        : const Color(
                                                            0xFFB45309),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    t['sancion'].toString(),
                                                    style: TextStyle(
                                                      color: cumplido
                                                          ? _kVerdeContinental
                                                          : const Color(
                                                              0xFFB45309),
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 10.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. Desglose Operativo por Grupo para la Directiva
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _kBorde),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.fact_check_rounded,
                                      color: _kVerdeContinental,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Resumen Consolidado de la Jornada',
                                      style: TextStyle(
                                        color: _kTexto,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: _kBorde),
                                _buildFilaResumen(
                                  'Grupo Continental 101-127',
                                  '$totalConductores Choferes activos ($totalVueltas vueltas registradas hoy)',
                                ),
                                const SizedBox(height: 8),
                                _buildFilaResumen(
                                  'Puntos de Control GPS',
                                  'Cruce Villadela y Teleférico Amarillo (Geocercas rectangulares)',
                                ),
                                const SizedBox(height: 8),
                                _buildFilaResumen(
                                  'Recaudación en Caja del Día',
                                  'Total acumulado hoy: Bs. ${cajaHoy.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. Botones de Exportar Informe Oficial y Enviar por WhatsApp
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    InformeSancionesWhatsappDialog.mostrar(
                                      context,
                                      sanciones: _sancionesHoy,
                                      horaLimite: '08:00 AM',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_rounded,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    'Informe Directiva WhatsApp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kVerdeContinental,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
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
        ],
      ),
    );
  }

  Widget _buildCurvedHeader(double topPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 18),
      decoration: const BoxDecoration(
        color: _kVerdeContinental,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporte Diario de la Jornada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Informe consolidado para la Directiva Sindical',
                  style: TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _cargarDatos,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _kVerdeContinental,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required Color bg,
    required Color borderColor,
    required String valor,
    required String titulo,
    required String subtitulo,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valor,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: _kTexto,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: _kSlate,
                      fontSize: 10,
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

  Widget _buildFilaResumen(String titulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: _kVerdeContinental,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: _kTexto,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              Text(
                valor,
                style: const TextStyle(
                  color: _kSlate,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
