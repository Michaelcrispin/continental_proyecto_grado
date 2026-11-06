import 'package:flutter/material.dart';

import '../../core/permisos.dart';
import '../../services/database_helper.dart';
import '../../services/sesion_service.dart';
import '../perfil_screen.dart';
import 'conductores_screen.dart';

// Paleta verde corporativa (coherente con toda la app)
const _kVerdeOscuro = Color(0xFF02634C);
const _kMentaFondo = Color(0xFFE8F5EF);
const _kGrisTexto = Color(0xFF64748B);

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

  @override
  void dispose() {
    super.dispose();
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
    // Métricas unificadas para el Grupo Continental 101-127
    final cantTotal = _conductores.length;
    final cantActivos = _conductores
        .where((c) =>
            (c['estado'] ?? 'activo').toString().toLowerCase() == 'activo')
        .length;
    final cantAutos = _conductores
        .where((c) =>
            c['placa'] != null && c['placa'].toString().trim().isNotEmpty)
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Encabezado Verde Curvo
          _buildGreenHeader(context),

          // Cuerpo con tarjeta unificada
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: _buildTarjetaGrupo(
                          grupo: '101-127',
                          titulo: 'Grupo Continental 101-127',
                          subtitulo: 'Sector Trufi 101-127',
                          etiquetaSector: 'Sector 101-127',
                          cantTotal: cantTotal,
                          cantActivos: cantActivos,
                          cantAutos: cantAutos,
                          onTap: () => _abrirGrupo('101-127'),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Encabezado verde corporativo con tamaño original espacioso y prominente
  Widget _buildGreenHeader(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, padding.top + 8, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Flecha atrás a la izquierda y Botón de Avatar a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Volver',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PerfilScreen()),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _kVerdeOscuro,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fila 2: Título grande como estaba antes
            const Text(
              'Conductores',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de Grupo con tamaño equilibrado (ni muy grande ni muy pequeña)
  Widget _buildTarjetaGrupo({
    required String grupo,
    required String titulo,
    required String subtitulo,
    required String etiquetaSector,
    required int cantTotal,
    required int cantActivos,
    required int cantAutos,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          splashColor: _kVerdeOscuro.withOpacity(0.06),
          highlightColor: _kVerdeOscuro.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Fila Superior: Ícono de Auto en círculo menta + Título + Badge de Sector
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ícono de auto en círculo color menta
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: _kMentaFondo,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: _kVerdeOscuro,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Título y Subtítulo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitulo,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kGrisTexto,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pastilla con "Sector 101" / "Sector 127"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _kMentaFondo,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        etiquetaSector,
                        style: const TextStyle(
                          color: _kVerdeOscuro,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Fila Intermedia de Estado: Indicadores útiles
                Row(
                  children: [
                    _buildPillInfo(
                      Icons.check_circle_outline_rounded,
                      '$cantActivos Activos',
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _buildPillInfo(
                      Icons.local_taxi_rounded,
                      '$cantAutos con Trufi',
                      const Color(0xFF0284C7),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Fila Inferior: Conteo de Conductores a la izquierda + Botón "Ver grupo →" a la derecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Conteo de conductores
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: _kVerdeOscuro,
                          size: 20,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$cantTotal Conductores',
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    // Botón píldora verde oscuro "Ver grupo →"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _kVerdeOscuro,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _kVerdeOscuro.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver grupo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
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

  Widget _buildPillInfo(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
