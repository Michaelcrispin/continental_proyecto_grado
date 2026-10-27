import 'package:flutter/material.dart';
import '../../widgets/app_background.dart';
import 'crear_apoyo_economico_screen.dart';
import 'crear_canaston_screen.dart';
import '../reuniones_screen.dart';

/// Pantalla Completa para Seleccionar la Categoría de Cuota a Crear.
/// Reemplaza el modal flotante genérico y ofrece una interfaz visual de tarjetas:
/// - 🎁 Ahorro Navideño (Canastón) [DISPONIBLE]: abre el formulario especializado de Canastón.
/// - 🤝 Apoyo Económico [PRÓXIMAMENTE]
/// - ⚽ Deportes y Eventos [PRÓXIMAMENTE]
/// - 🛠️ Infraestructura / Pro-Fondos [PRÓXIMAMENTE]
class SeleccionarCategoriaScreen extends StatelessWidget {
  const SeleccionarCategoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Nueva Cuota',
          style: TextStyle(
            color: Color(0xFF0F2B5B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/logo.png',
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_bus_rounded,
                color: Color(0xFF0F2B5B),
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              // ENCABEZADO DE SELECCIÓN
              const Text(
                'Elige la Categoría',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2B5B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cada categoría cuenta con su propia pantalla y formulario especializado adaptado a su propósito.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),

              // 1. TARJETA CANASTÓN / AHORRO NAVIDEÑO (ACTIVA Y DISPONIBLE)
              _buildCategoryCard(
                context,
                title: 'Ahorro Navideño (Canastón)',
                description:
                    'Fondo de aportaciones periódicas con cuota fija uniforme para compras y víveres de fin de año.',
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFFEA580C),
                iconBgColor: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFDBA74),
                badgeText: 'Disponible',
                badgeBgColor: const Color(0xFFD1FAE5),
                badgeTextColor: const Color(0xFF065F46),
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

              // 2. TARJETA APOYO ECONÓMICO (ACTIVA Y DISPONIBLE)
              _buildCategoryCard(
                context,
                title: 'Apoyo Económico',
                description:
                    'Cuotas solidarias o de auxilio extraordinario para accidentes, emergencias o salud de un socio.',
                icon: Icons.volunteer_activism_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFF93C5FD),
                badgeText: 'Disponible',
                badgeBgColor: const Color(0xFFDBEAFE),
                badgeTextColor: const Color(0xFF1E40AF),
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

              // 3. TARJETA MULTAS POR FALTA A REUNIÓN (ACTIVA Y DISPONIBLE)
              _buildCategoryCard(
                context,
                title: 'Multas por Falta a Reunión',
                description:
                    'Control de asistencia a asambleas con llamado de lista y generación automática de multas a choferes ausentes.',
                icon: Icons.gavel_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFECACA),
                badgeText: 'Disponible',
                badgeBgColor: const Color(0xFFFEE2E2),
                badgeTextColor: const Color(0xFF991B1B),
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

              // 4. TARJETA DEPORTES Y EVENTOS (PRÓXIMAMENTE)
              _buildCategoryCard(
                context,
                title: 'Deportes y Campeonatos',
                description:
                    'Fondos para campeonatos internos o interinstitucionales, uniformes y actividades recreativas.',
                icon: Icons.sports_soccer_rounded,
                iconColor: const Color(0xFF0D9488),
                iconBgColor: const Color(0xFFF0FDFA),
                borderColor: const Color(0xFFE2E8F0),
                badgeText: 'Próximamente',
                badgeBgColor: const Color(0xFFF1F5F9),
                badgeTextColor: const Color(0xFF64748B),
                isAvailable: false,
                onTap: () {
                  _mostrarAvisoProximamente(
                    context,
                    'La categoría "Deportes y Campeonatos" estará disponible próximamente.',
                  );
                },
              ),

              const SizedBox(height: 14),

              // 4. TARJETA INFRAESTRUCTURA / PRO-FONDOS (PRÓXIMAMENTE)
              _buildCategoryCard(
                context,
                title: 'Infraestructura / Pro-Fondos',
                description:
                    'Aportes extraordinarios para mantenimiento de sedes, paradas o equipamiento sindical.',
                icon: Icons.construction_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFE2E8F0),
                badgeText: 'Próximamente',
                badgeBgColor: const Color(0xFFF1F5F9),
                badgeTextColor: const Color(0xFF64748B),
                isAvailable: false,
                onTap: () {
                  _mostrarAvisoProximamente(
                    context,
                    'La categoría "Infraestructura" estará disponible próximamente.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color borderColor,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isAvailable ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isAvailable ? const Color(0x10EA580C) : const Color(0x060F2B5B),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: iconColor.withOpacity(0.08),
          highlightColor: iconColor.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono en círculo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),

                // Textos y badge
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
                                fontSize: 15.5,
                                color: isAvailable ? const Color(0xFF0F2B5B) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Flechita
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isAvailable ? iconColor : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarAvisoProximamente(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: const Color(0xFF0F2B5B),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
