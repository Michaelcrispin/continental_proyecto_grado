// lib/screens/vueltas_screen.dart
//
// Pantalla de Control de VUELTAS DE CASTIGO por GPS:
//  - Las vueltas nacen de una sanción por tardanza (módulo Asistencia, después de las 08:00 AM)
//    y se cumplen de noche, desde la hora de castigo configurada (21:00).
//  - Estructura inspirada en el diseño institucional verde (#02634C) del Sindicato Continental.
//  - 4 KPIs superiores: Con castigo, Cumplidas, En curso y Pendiente.
//  - Tarjeta de acceso a la Ruta Oficial del Día (Villadela ⇄ Teleférico).
//  - Píldoras de filtrado dinámico: Todos, Cumplidas, En curso, Pendientes.
//  - Lista de tarjetas con avatar, nombre, tardanza y badge de vueltas (Cumplido / En curso / Pendiente).
//  - Al tocar un conductor: mapa con la ruta oficial y el recorrido GPS de cada vuelta de castigo.
//  - Tarjeta inferior de Resumen General y barra de navegación AppBottomBar unificada.

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/avatar_conductor.dart';
import '../widgets/vuelta_castigo_sheet.dart';
import 'asistencia/asistencia_screen.dart';
import 'cuotas/cuotas_screen.dart';
import 'gps/ruta_oficial_screen.dart';
import 'home_screen.dart';

class VueltasScreen extends StatefulWidget {
  const VueltasScreen({super.key});

  @override
  State<VueltasScreen> createState() => _VueltasScreenState();
}

class _VueltasScreenState extends State<VueltasScreen> {
  String _filtro = 'todos'; // 'todos' | 'cumplidas' | 'en_curso' | 'pendientes'
  bool _isLoading = true;
  List<Map<String, dynamic>> _vueltasConductores = [];
  int _vueltasTotalesHoy = 0;
  String _horaInicioCastigo = '21:00';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final helper = DatabaseHelper.instance;
      try {
        await helper.sembrarVueltasCastigoDemo();
      } catch (e) {
        debugPrint('No se pudieron crear los datos de demostración: $e');
      }
      final db = await helper.database;
      final horaInicio = await helper.getConfig('hora_inicio_castigo', '21:00') ?? '21:00';
      final conductores = await helper.conductoresConAuto();
      final sanciones = await helper.sancionesDetalle();

      final conductorPorId = <String, Map<String, dynamic>>{
        for (final c in conductores) (c['id_conductor']?.toString() ?? ''): c,
      };

      final lista = <Map<String, dynamic>>[];
      int totalVueltasSuma = 0;

      // Cada sanción por tardanza (generada desde Asistencia) es una obligación de
      // vueltas nocturnas: se muestran las pendientes y las cerradas el día de hoy.
      for (final s in sanciones) {
        final asignadas = (s['vueltas_asignadas'] as num?)?.toInt() ?? 0;
        if (asignadas <= 0) continue;

        final estadoSancion = s['estado']?.toString();
        final cerradaHoy = estadoSancion == 'cumplida' &&
            (s['updated_at']?.toString() ?? '').startsWith(hoy);
        if (estadoSancion != 'pendiente' && !cerradaHoy) continue;

        final idCond = s['id_conductor']?.toString() ?? '';
        final idAsistencia = s['id_asistencia']?.toString();
        final tieneAsistencia = idAsistencia != null && idAsistencia.isNotEmpty;
        final c = conductorPorId[idCond];

        final hechas = ((s['vueltas_cumplidas'] as num?)?.toInt() ?? 0).clamp(0, asignadas);

        // Horas reales en las que se registró el cierre de cada vuelta de castigo
        final filasCierre = await db.query(
          'vueltas',
          columns: ['hora'],
          where: tieneAsistencia
              ? "id_conductor = ? AND tipo = 'sancion' AND id_asistencia = ?"
              : "id_conductor = ? AND tipo = 'sancion'",
          whereArgs: tieneAsistencia ? [idCond, idAsistencia] : [idCond],
          orderBy: 'created_at ASC',
        );

        String estado;
        if (hechas >= asignadas) {
          estado = 'cumplidas';
        } else if (hechas > 0) {
          estado = 'en_curso';
        } else {
          estado = 'pendientes';
        }
        totalVueltasSuma += hechas;

        lista.add({
          'id_sancion': s['id_sancion'],
          'id_conductor': idCond,
          'unidad': (c?['numero_interno'] ?? s['numero_interno'] ?? '-').toString(),
          'conductor': (c?['nombre'] ?? s['conductor_nombre'] ?? 'Conductor').toString(),
          'placa': (c?['placa'] ?? s['placa'] ?? 'S/P').toString(),
          'foto': (c?['foto'] ?? s['conductor_foto'])?.toString(),
          'vueltas_hechas': hechas,
          'vueltas_meta': asignadas,
          'estado': estado,
          'fecha_sancion': s['fecha'],
          'hora_llegada': s['hora_llegada'] ?? s['hora'],
          'minutos_retraso': s['minutos_retraso'],
          'hora_inicio_castigo': horaInicio,
          'horas_cierre': filasCierre.map((f) => f['hora']?.toString() ?? '').toList(),
        });
      }

      const orden = {'en_curso': 0, 'pendientes': 1, 'cumplidas': 2};
      lista.sort((a, b) => orden[a['estado']]!.compareTo(orden[b['estado']]!));

      if (mounted) {
        setState(() {
          _vueltasConductores = lista;
          _vueltasTotalesHoy = totalVueltasSuma;
          _horaInicioCastigo = horaInicio;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarOpcionesConductor(Map<String, dynamic> v) {
    VueltaCastigoSheet.mostrar(context, v);
  }

  void _mostrarModalResumenGeneral(int cumplidas, int enCurso, int pendientes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Resumen de Vueltas de Castigo',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Circuito Cruce Villadela ⇄ Teleférico Amarillo (14.69 km)',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _filaItemResumen('Sanciones con vueltas de castigo', '${_vueltasConductores.length}', const Color(0xFF02634C)),
            _filaItemResumen('Castigo cumplido (todas las vueltas)', '$cumplidas', const Color(0xFF10B981)),
            _filaItemResumen('En recorrido activo (en curso)', '$enCurso', const Color(0xFF2563EB)),
            _filaItemResumen('Pendientes de iniciar', '$pendientes', const Color(0xFFEF4444)),
            _filaItemResumen('Vueltas de castigo cumplidas', '$_vueltasTotalesHoy', const Color(0xFFD97706)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02634C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaItemResumen(String label, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600)),
          Text(valor, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _vueltasConductores.where((v) {
      if (_filtro == 'todos') return true;
      return v['estado'] == _filtro;
    }).toList();

    final totalCount = _vueltasConductores.length;
    final cumplidasCount = _vueltasConductores.where((v) => v['estado'] == 'cumplidas').length;
    final enCursoCount = _vueltasConductores.where((v) => v['estado'] == 'en_curso').length;
    final pendientesCount = _vueltasConductores.where((v) => v['estado'] == 'pendientes').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: AppBottomBar(
        currentTab: AppBottomTab.vueltas,
        onTabSelected: (tab) {
          if (tab == AppBottomTab.inicio) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } else if (tab == AppBottomTab.asistencias) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
            );
          } else if (tab == AppBottomTab.vueltas) {
            _cargarDatos();
          } else if (tab == AppBottomTab.cuotas) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CuotasScreen()),
            );
          }
        },
      ),
      body: _isLoading && _vueltasConductores.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF02634C)))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: const Color(0xFF02634C),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cabecera curva verde corporativa
                    _buildCurvedHeader(context),

                    // 2. Contenido del panel
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 4 Tarjetas de KPIs superiores
                          _buildKpisRow(totalCount, cumplidasCount, enCursoCount, pendientesCount),
                          const SizedBox(height: 14),

                          // Tarjeta Ruta del Día
                          _buildCardRutaDelDia(),
                          const SizedBox(height: 14),

                          // Píldoras de filtrado
                          _buildFilterPills(totalCount, cumplidasCount, enCursoCount, pendientesCount),
                          const SizedBox(height: 14),

                          // Lista de conductores
                          if (filtrados.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.gavel_rounded,
                                    size: 42,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _vueltasConductores.isEmpty
                                        ? 'No hay vueltas de castigo pendientes'
                                        : 'No hay vueltas en esta categoría',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  if (_vueltasConductores.isEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Se generan solas cuando un conductor marca asistencia después de las 08:00 AM y se cumplen desde las $_horaInicioCastigo.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else
                            ...filtrados.map((v) => _buildTarjetaVueltaConductor(v)),

                          const SizedBox(height: 14),

                          // Tarjeta inferior Resumen General
                          _buildCardResumenGeneral(cumplidasCount, enCursoCount, pendientesCount),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CABECERA CURVA VERDE
  // ---------------------------------------------------------------------------
  Widget _buildCurvedHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF02634C),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3302634C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
        child: Row(
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
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vueltas de Castigo por GPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 13,
                        color: Color(0xFFE6F4F0),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'Castigo nocturno desde las $_horaInicioCastigo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _cargarDatos,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF02634C),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FILA DE 4 TARJETAS KPIS SUPERIORES
  // ---------------------------------------------------------------------------
  Widget _buildKpisRow(int total, int cumplidas, int enCurso, int pendientes) {
    return Row(
      children: [
        _buildKpiCard(
          icon: Icons.groups_rounded,
          iconColor: const Color(0xFF02634C),
          iconBg: const Color(0xFFE6F4F0),
          valor: '$total',
          label: 'Con castigo',
          tipo: 'todos',
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFFD1FAE5),
          valor: '$cumplidas',
          label: 'Cumplidas',
          tipo: 'cumplidas',
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          icon: Icons.access_time_filled_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
          valor: '$enCurso',
          label: 'En curso',
          tipo: 'en_curso',
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          icon: Icons.cancel_rounded,
          iconColor: const Color(0xFFEF4444),
          iconBg: const Color(0xFFFEE2E2),
          valor: '$pendientes',
          label: 'Pendiente',
          tipo: 'pendientes',
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String valor,
    required String label,
    required String tipo,
  }) {
    final isSelected = _filtro == tipo;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filtro = _filtro == tipo ? 'todos' : tipo;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? iconColor : iconColor.withValues(alpha: 0.25),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 4),
              Text(
                valor,
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? iconColor : const Color(0xFF475569),
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TARJETA RUTA DEL DÍA
  // ---------------------------------------------------------------------------
  Widget _buildCardRutaDelDia() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RutaOficialScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                color: Color(0xFF02634C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Circuito de castigo',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Villadela → Teleférico y regreso (14.69 km)',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF02634C),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PÍLDORAS DE FILTRADO
  // ---------------------------------------------------------------------------
  Widget _buildFilterPills(int total, int cumplidas, int enCurso, int pendientes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPillItem('todos', 'Todos ($total)'),
          const SizedBox(width: 8),
          _buildPillItem('cumplidas', 'Cumplidas ($cumplidas)'),
          const SizedBox(width: 8),
          _buildPillItem('en_curso', 'En curso ($enCurso)'),
          const SizedBox(width: 8),
          _buildPillItem('pendientes', 'Pendientes ($pendientes)'),
        ],
      ),
    );
  }

  Widget _buildPillItem(String key, String label) {
    final sel = _filtro == key;
    return GestureDetector(
      onTap: () => setState(() => _filtro = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF02634C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? const Color(0xFF02634C) : const Color(0xFFE2E8F0),
            width: sel ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: sel
                  ? const Color(0x3302634C)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : const Color(0xFF0F172A),
            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TARJETA DE VUELTA POR CONDUCTOR
  // ---------------------------------------------------------------------------
  Widget _buildTarjetaVueltaConductor(Map<String, dynamic> v) {
    final hechas = v['vueltas_hechas'] as int;
    final meta = v['vueltas_meta'] as int;
    final estado = v['estado'] as String;
    final nombre = v['conductor']?.toString() ?? 'Conductor';

    return GestureDetector(
      onTap: () => _mostrarOpcionesConductor(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AvatarConductor(
              foto: v['foto'] as String?,
              nombre: nombre,
              radio: 22,
              fontSize: 13,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtituloCastigo(v),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$hechas / $meta vueltas',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                _buildBadgeEstado(estado),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF02634C),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _subtituloCastigo(Map<String, dynamic> v) {
    final partes = (v['fecha_sancion']?.toString() ?? '').split('-');
    final fecha = partes.length == 3 ? '${partes[2]}/${partes[1]}' : '';
    final llegada = v['hora_llegada']?.toString() ?? '';
    return 'Móvil #${v['unidad']} • Tardanza $fecha${llegada.isNotEmpty ? ' · $llegada' : ''}';
  }

  Widget _buildBadgeEstado(String estado) {
    if (estado == 'cumplidas') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
            SizedBox(width: 4),
            Text(
              'Cumplido',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else if (estado == 'en_curso') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_filled_rounded, color: Color(0xFF2563EB), size: 12),
            SizedBox(width: 4),
            Text(
              'En curso',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 12),
            SizedBox(width: 4),
            Text(
              'Pendiente',
              style: TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 6. TARJETA RESUMEN GENERAL
  // ---------------------------------------------------------------------------
  Widget _buildCardResumenGeneral(int cumplidas, int enCurso, int pendientes) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _mostrarModalResumenGeneral(cumplidas, enCurso, pendientes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF02634C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen General',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cumplidas completaron • $enCurso en curso • $pendientes pendiente${pendientes == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF02634C),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
