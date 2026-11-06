import 'package:flutter/material.dart';
import '../../services/sesion_service.dart';
import 'crear_apoyo_economico_screen.dart';
import 'crear_canaston_screen.dart';
import '../reuniones_screen.dart';

const _kVerdeOscuro = Color(0xFF02634C);

/// Pantalla Completa para Seleccionar la Categoría de Cuota a Crear.
/// Refleja:
/// - Encabezado curvo corporativo en color verde con logo oficial Continental.
/// - Tarjetas amplias y destacadas con íconos circulares, badges "Disponible",
///   descripción clara y flecha indicadora.
/// - Categorías:
///   1. 🎁 Ahorro Navideño (Canastón) [DISPONIBLE]
///   2. 🤝 Apoyo Económico [DISPONIBLE]
///   3. ⚖️ Multas por Falta a Reunión [DISPONIBLE]
///   4. 🔄 Pasanaku [NO DISPONIBLE]
class SeleccionarCategoriaScreen extends StatelessWidget {
  const SeleccionarCategoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ENCABEZADO CURVO VERDE CORPORATIVO ADAPTADO
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _kVerdeOscuro,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      // Usuario que está manejando en Squircle Blanco
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
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
                  const SizedBox(height: 14),
                  const Text(
                    'Nueva Cuota',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. LISTA DE CATEGORÍAS EN TARJETAS MÁS GRANDES
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              children: [
                // Título de selección y subtítulo
                const Text(
                  'Elige la categoría',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F2B5B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cada categoría cuenta con su propia pantalla y formulario especializado adaptado a su propósito.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 20),

                // 1. AHORRO NAVIDEÑO (CANASTÓN)
                _buildCategoryCard(
                  context,
                  title: 'Ahorro Navideño\n(Canastón)',
                  description:
                      'Aportaciones periódicas con cuota fija para fin de año.',
                  icon: Icons.card_giftcard_rounded,
                  isAvailable: true,
                  onTap: () async {
                    final creada = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearCanastonScreen(),
                      ),
                    );
                    if (creada == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),

                const SizedBox(height: 14),

                // 2. APOYO ECONÓMICO
                _buildCategoryCard(
                  context,
                  title: 'Apoyo Económico',
                  description:
                      'Ayuda solidaria ante accidentes o emergencias.',
                  icon: Icons.handshake_outlined,
                  isAvailable: true,
                  onTap: () async {
                    final creada = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearApoyoEconomicoScreen(),
                      ),
                    );
                    if (creada == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),

                const SizedBox(height: 14),

                // 3. MULTAS POR FALTA A REUNIÓN
                _buildCategoryCard(
                  context,
                  title: 'Multas por Falta a Reunión',
                  description:
                      'Control de asistencia y multas por inasistencia.',
                  icon: Icons.gavel_rounded,
                  isAvailable: true,
                  onTap: () async {
                    final cambio = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReunionesScreen(),
                      ),
                    );
                    if (cambio == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),

                const SizedBox(height: 14),

                // 4. PASANAKU (NO DISPONIBLE)
                _buildCategoryCard(
                  context,
                  title: 'Pasanaku',
                  description:
                      'Ahorro rotativo y crédito mutuo.',
                  icon: Icons.sync_rounded,
                  isAvailable: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'La categoría "Pasanaku" no se encuentra disponible actualmente.',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: _kVerdeOscuro,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de categoría ampliada con diseño limpio y ergonómico
  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícono en círculo menta suave más grande (58x58)
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? const Color(0xFFE6F4F0)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isAvailable ? _kVerdeOscuro : const Color(0xFF94A3B8),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // Textos y Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.5,
                                color: isAvailable
                                    ? const Color(0xFF0F2B5B)
                                    : const Color(0xFF475569),
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge "Disponible" / "No disponible"
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? const Color(0xFFE6F4F0)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? _kVerdeOscuro
                                        : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isAvailable ? 'Disponible' : 'No disponible',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isAvailable
                                        ? _kVerdeOscuro
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Flecha chevron indicadora
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: isAvailable ? _kVerdeOscuro : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
