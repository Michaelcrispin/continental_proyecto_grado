import 'package:flutter/material.dart';
import 'detalle_container_card.dart';

/// Pestaña con los detalles mecánicos y asignación de la Trufi / Minibus.
class TabTrufi extends StatelessWidget {
  final Map<String, dynamic> conductor;

  const TabTrufi({super.key, required this.conductor});

  @override
  Widget build(BuildContext context) {
    final placa = conductor['placa']?.toString() ?? 'Sin placa';
    final marca = conductor['marca']?.toString() ?? 'Toyota';
    final modelo = conductor['modelo']?.toString() ?? 'Hiace';
    final color = conductor['color']?.toString() ?? 'No registrado';
    final capacidad = conductor['capacidad']?.toString() ?? '14';
    final soat = conductor['soat']?.toString() ?? 'No registrado';
    final soatVence =
        conductor['fecha_vencimiento_soat']?.toString() ?? 'No registrado';
    final ruat = conductor['ruat']?.toString() ?? 'No registrado';

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/trufi_minibus.jpg',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                color: Colors.white,
                child: const Center(
                  child: Icon(
                    Icons.local_taxi_rounded,
                    size: 80,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DetalleContainerCard(
          icon: Icons.local_taxi_rounded,
          title: 'Ficha Técnica del Trufi',
          child: Column(
            children: [
              _buildFilaDato(
                'Placa de Control',
                placa.isNotEmpty ? placa : 'Sin placa asignada',
              ),
              _buildFilaDato(
                'Marca',
                marca.isNotEmpty ? marca : 'No registrado',
              ),
              _buildFilaDato(
                'Modelo',
                modelo.isNotEmpty ? modelo : 'No registrado',
              ),
              _buildFilaDato(
                'Color',
                color.isNotEmpty ? color : 'No registrado',
              ),
              _buildFilaDato('Capacidad', '$capacidad pasajeros sentados'),
              _buildFilaDato(
                'Póliza SOAT',
                soat.isNotEmpty ? soat : 'No registrado',
              ),
              _buildFilaDato(
                'Vencimiento SOAT',
                soatVence.isNotEmpty ? soatVence : 'No registrado',
              ),
              _buildFilaDato(
                'Registro RUAT',
                ruat.isNotEmpty ? ruat : 'No registrado',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilaDato(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
