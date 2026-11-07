import 'package:flutter/material.dart';

enum AppBottomTab { asistencias, vueltas, inicio, sanciones, cuotas }

/// Barra de navegación inferior única, unificada y oficial del sistema Continental.
/// Garantiza que los íconos, tipografía, estados activos e inactivos sean 100% idénticos
/// en todas las pantallas de la aplicación.
///
/// Diseño: barra blanca flotante con esquinas superiores redondeadas y, en la pestaña
/// activa, una "bolita" elevada con los colores corporativos verdes de la app.
class AppBottomBar extends StatelessWidget {
  final AppBottomTab currentTab;
  final ValueChanged<AppBottomTab> onTabSelected;

  const AppBottomBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  static const Color verdeCorporativo = Color(0xFF02634C);
  static const Color verdeBrillante = Color(0xFF0B8E6E);
  static const Color inactivoColor = Color(0xFF94A3B8);

  /// Alto de la barra blanca (sin contar la bolita que sobresale).
  static const double _barHeight = 78;

  /// Alto total reservado por el widget (barra + parte de la bolita que sobresale).
  static const double _totalHeight = 106;

  /// Diámetro de la bolita activa.
  static const double _bubbleSize = 64;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: SizedBox(
        height: _totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Fondo blanco de la barra con esquinas superiores redondeadas.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
              ),
            ),

            // Pestañas: Asistencias · Vueltas · Inicio (centro) · Sanciones · Cuotas.
            Positioned.fill(
              child: Row(
                children: [
                  // 1. Asistencias
                  _buildBarItem(
                    tab: AppBottomTab.asistencias,
                    iconActive: Icons.groups_rounded,
                    iconInactive: Icons.groups_outlined,
                    label: 'Asistencias',
                  ),

                  // 2. Vueltas (Ruta continua unificada oficial)
                  _buildBarItem(
                    tab: AppBottomTab.vueltas,
                    iconActive: Icons.route_rounded,
                    iconInactive: Icons.route_outlined,
                    label: 'Vueltas',
                  ),

                  // 3. Inicio (centro, con la bolita elevada)
                  _buildBarItem(
                    tab: AppBottomTab.inicio,
                    iconActive: Icons.home_rounded,
                    iconInactive: Icons.home_outlined,
                    label: 'Inicio',
                  ),

                  // 4. Sanciones
                  _buildBarItem(
                    tab: AppBottomTab.sanciones,
                    iconActive: Icons.gavel_rounded,
                    iconInactive: Icons.gavel_rounded,
                    label: 'Sanciones',
                  ),

                  // 5. Cuotas (Billetera oficial)
                  _buildBarItem(
                    tab: AppBottomTab.cuotas,
                    iconActive: Icons.account_balance_wallet_rounded,
                    iconInactive: Icons.account_balance_wallet_outlined,
                    label: 'Cuotas',
                  ),
                ],
              ),
            ),
          ],
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
    return Expanded(
      child: _BottomBarItem(
        isActive: currentTab == tab,
        iconActive: iconActive,
        iconInactive: iconInactive,
        label: label,
        bubbleSize: _bubbleSize,
        onTap: () => onTabSelected(tab),
      ),
    );
  }
}

/// Pestaña individual con animación de presión y "bolita" elevada cuando está activa.
class _BottomBarItem extends StatefulWidget {
  final bool isActive;
  final IconData iconActive;
  final IconData iconInactive;
  final String label;
  final double bubbleSize;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.isActive,
    required this.iconActive,
    required this.iconInactive,
    required this.label,
    required this.bubbleSize,
    required this.onTap,
  });

  @override
  State<_BottomBarItem> createState() => _BottomBarItemState();
}

class _BottomBarItemState extends State<_BottomBarItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            if (isActive)
              // Bolita elevada de la pestaña activa (aparece con un "pop").
              Positioned(
                top: 2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.55, end: 1),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: widget.bubbleSize,
                    height: widget.bubbleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppBottomBar.verdeBrillante,
                          AppBottomBar.verdeCorporativo,
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: AppBottomBar.verdeCorporativo
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.iconActive,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              // Ícono inactivo, apoyado sobre la barra blanca.
              Positioned(
                top: 44,
                child: Icon(
                  widget.iconInactive,
                  size: 26,
                  color: AppBottomBar.inactivoColor,
                ),
              ),

            // Etiqueta.
            Positioned(
              left: 2,
              right: 2,
              bottom: 12,
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? AppBottomBar.verdeCorporativo
                      : AppBottomBar.inactivoColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
