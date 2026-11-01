import 'package:flutter/material.dart';

class FiltroConductoresBar extends StatelessWidget {
  final String filtroActivo;
  final ValueChanged<String> onFiltroChanged;
  final int cantTotal;
  final int cantActivos;
  final int cantInactivos;
  final int cantAlertas;

  const FiltroConductoresBar({
    super.key,
    required this.filtroActivo,
    required this.onFiltroChanged,
    required this.cantTotal,
    required this.cantActivos,
    required this.cantInactivos,
    required this.cantAlertas,
  });

  Widget _buildChip(String key, String label, int count, {Color? color}) {
    final isSelected = filtroActivo == key;
    final chipColor = color ?? const Color(0xFF1E3A8A);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onFiltroChanged(key),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildChip('todos', 'Todos', cantTotal),
          _buildChip('activos', 'Activos', cantActivos,
              color: const Color(0xFF10B981)),
          if (cantInactivos > 0)
            _buildChip('inactivos', 'Inactivos', cantInactivos,
                color: const Color(0xFFEF4444)),
          if (cantAlertas > 0)
            _buildChip('alertas', 'Alertas Docs', cantAlertas,
                color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}
