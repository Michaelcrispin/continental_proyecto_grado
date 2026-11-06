import 'package:flutter/material.dart';

enum AppBottomTab { inicio, asistencias, vueltas, cuotas }

/// Barra de navegación inferior única, unificada y oficial del sistema Continental.
/// Garantiza que los íconos, tipografía, estados activos e inactivos sean 100% idénticos
/// en todas las pantallas de la aplicación.
class AppBottomBar extends StatelessWidget {
  final AppBottomTab currentTab;
  final ValueChanged<AppBottomTab> onTabSelected;

  const AppBottomBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  static const Color verdeCorporativo = Color(0xFF02634C);
  static const Color inactivoColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Inicio
              _buildBarItem(
                tab: AppBottomTab.inicio,
                iconActive: Icons.home_rounded,
                iconInactive: Icons.home_outlined,
                label: 'Inicio',
              ),

              // 2. Asistencias
              _buildBarItem(
                tab: AppBottomTab.asistencias,
                iconActive: Icons.groups_rounded,
                iconInactive: Icons.groups_outlined,
                label: 'Asistencias',
              ),

              // 3. Vueltas (Ruta continua unificada oficial)
              _buildBarItem(
                tab: AppBottomTab.vueltas,
                iconActive: Icons.route_rounded,
                iconInactive: Icons.route_outlined,
                label: 'Vueltas',
              ),

              // 4. Cuotas (Billetera oficial)
              _buildBarItem(
                tab: AppBottomTab.cuotas,
                iconActive: Icons.account_balance_wallet_rounded,
                iconInactive: Icons.account_balance_wallet_outlined,
                label: 'Cuotas',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem({
    required AppBottomTab tab,
    required IconData iconActive,
    required IconData iconInactive,
    required String label,
  }) {
    final isActive = currentTab == tab;

    return InkWell(
      onTap: () => onTabSelected(tab),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconActive : iconInactive,
              size: 24,
              color: isActive ? verdeCorporativo : inactivoColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? verdeCorporativo : inactivoColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

