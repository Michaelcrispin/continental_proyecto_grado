import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/database_helper.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import 'conductores_screen.dart';

/// Pantalla Principal de Grupos de Conductores (Sindicato Continental Trufi)
/// Muestra las dos grandes tarjetas para:
/// - Grupo Continental 101
/// - Grupo Continental 127
/// con el diseño visual, colores y métricas fieles al módulo de Cuotas.
class GruposConductoresScreen extends StatefulWidget {
  const GruposConductoresScreen({super.key});

  @override
  State<GruposConductoresScreen> createState() =>
      _GruposConductoresScreenState();
}

class _GruposConductoresScreenState extends State<GruposConductoresScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conductores = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(
        context,
        SesionService.instance.rol,
        Permisos.moduloConductores,
      )) {
        return;
      }
    });
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final lista = await DatabaseHelper.instance.conductoresConAuto();
      if (mounted) {
        setState(() {
          _conductores = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirGrupo(String grupo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConductoresScreen(grupo: grupo),
      ),
    );
    if (mounted) {
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Métricas Grupo 101
    final cond101 = _conductores
        .where((c) => (c['grupo'] ?? '101').toString() == '101')
        .toList();
    final cant101 = cond101.length;
    final activos101 = cond101
        .where((c) =>
            (c['estado'] ?? 'activo').toString().toLowerCase() == 'activo')
        .length;
    final autos101 = cond101
        .where((c) =>
            c['placa'] != null && c['placa'].toString().trim().isNotEmpty)
        .length;

    // Métricas Grupo 127
    final cond127 = _conductores
        .where((c) => (c['grupo'] ?? '101').toString() == '127')
        .toList();
    final cant127 = cond127.length;
    final activos127 = cond127
        .where((c) =>
            (c['estado'] ?? 'activo').toString().toLowerCase() == 'activo')
        .length;
    final autos127 = cond127
        .where((c) =>
            c['placa'] != null && c['placa'].toString().trim().isNotEmpty)
        .length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Conductores',
          style: TextStyle(
            color: Color(0xFF0F2B5B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F2B5B)),
            tooltip: 'Actualizar',
            onPressed: _cargarDatos,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(
                Icons.local_taxi_rounded,
                color: Color(0xFF0F2B5B),
                size: 26,
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    // ENCABEZADO DE PRESENTACIÓN
                    const Text(
                      'Padrón por Grupos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2B5B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Selecciona el grupo de conductores para ver y gestionar sus miembros, vehículos y estado operativo.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TARJETA GRANDE 1: GRUPO CONTINENTAL 101
                    _buildTarjetaGrupo(
                      grupo: '101',
                      titulo: 'Grupo Continental 101',
                      subtitulo: 'Sector Trufi 101 • Línea Oficial',
                      cantTotal: cant101,
                      cantActivos: activos101,
                      cantAutos: autos101,
                      colorTema: const Color(0xFF1E3A8A),
                      colorFondoIcono: const Color(0xFFEFF6FF),
                      colorBorde: const Color(0xFF93C5FD),
                      colorBadgeFondo: const Color(0xFFDBEAFE),
                      colorBadgeTexto: const Color(0xFF1E40AF),
                      onTap: () => _abrirGrupo('101'),
                    ),

                    const SizedBox(height: 18),

                    // TARJETA GRANDE 2: GRUPO CONTINENTAL 127
                    _buildTarjetaGrupo(
                      grupo: '127',
                      titulo: 'Grupo Continental 127',
                      subtitulo: 'Sector Trufi 127 • Línea Oficial',
                      cantTotal: cant127,
                      cantActivos: activos127,
                      cantAutos: autos127,
                      colorTema: const Color(0xFF0D9488),
                      colorFondoIcono: const Color(0xFFF0FDF4),
                      colorBorde: const Color(0xFF99F6E4),
                      colorBadgeFondo: const Color(0xFFCCFBF1),
                      colorBadgeTexto: const Color(0xFF115E59),
                      onTap: () => _abrirGrupo('127'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTarjetaGrupo({
    required String grupo,
    required String titulo,
    required String subtitulo,
    required int cantTotal,
    required int cantActivos,
    required int cantAutos,
    required Color colorTema,
    required Color colorFondoIcono,
    required Color colorBorde,
    required Color colorBadgeFondo,
    required Color colorBadgeTexto,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F2B5B),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          splashColor: colorTema.withOpacity(0.08),
          highlightColor: colorTema.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Ícono de Taxi + Título + Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono de Taxi destacado
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: colorFondoIcono,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorBorde, width: 1.2),
                      ),
                      child: Icon(
                        Icons.local_taxi_rounded,
                        color: colorTema,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Título y Sector
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Color(0xFF0F2B5B),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge de Sector
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorBadgeFondo,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Sector $grupo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorBadgeTexto,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitulo,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Fila de Métricas del Grupo (Mismo estilo que Cuotas)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Total Conductores
                      Expanded(
                        child: _buildMiniStat(
                          icono: Icons.people_outline_rounded,
                          colorIcono: colorTema,
                          label: 'Conductores',
                          valor: '$cantTotal',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFE2E8F0),
                      ),
                      // Activos
                      Expanded(
                        child: _buildMiniStat(
                          icono: Icons.check_circle_outline_rounded,
                          colorIcono: const Color(0xFF10B981),
                          label: 'Activos',
                          valor: '$cantActivos',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFE2E8F0),
                      ),
                      // Vehículos Trufis
                      Expanded(
                        child: _buildMiniStat(
                          icono: Icons.local_taxi_outlined,
                          colorIcono: const Color(0xFF3B82F6),
                          label: 'Trufis',
                          valor: '$cantAutos',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Botón elegante de Acceso al Grupo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colorTema,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colorTema.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ver Conductores del Grupo $grupo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icono,
    required Color colorIcono,
    required String label,
    required String valor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 14, color: colorIcono),
            const SizedBox(width: 4),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0F2B5B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

