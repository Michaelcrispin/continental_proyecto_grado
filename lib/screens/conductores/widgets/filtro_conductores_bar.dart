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
    const verdeMarca = Color(0xFF02634C);
    final chipColor = color ?? verdeMarca;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onFiltroChanged(key),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? chipColor : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildChip('todos', 'Todos', cantTotal),
          _buildChip('activos', 'Activos', cantActivos),
          _buildChip('alertas', 'Alertas', cantAlertas),
          if (cantInactivos > 0)
            _buildChip('inactivos', 'Inactivos', cantInactivos,
                color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }
}
