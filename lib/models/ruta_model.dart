import 'package:latlong2/latlong.dart';

class Parada {
  final String nombre;
  final String horarioPrevisto;
  final LatLng ubicacion;

  Parada({
    required this.nombre,
    required this.horarioPrevisto,
    required this.ubicacion,
  });
}

class Ruta {
  final String id;
  final String conductorNombre;
  final String numeroTrufi;
  final String estado;
  final double velocidadActual;
  final List<Parada> paradas;

  Ruta({
    required this.id,
    required this.conductorNombre,
    required this.numeroTrufi,
    required this.estado,
    required this.velocidadActual,
    required this.paradas,
  });

  // Mock data para reemplazar el diseño de gps_screen
  static Ruta get currentRuta => Ruta(
        id: 'R001',
        conductorNombre: 'Juan Pérez',
        numeroTrufi: '115',
        estado: 'En ruta',
        velocidadActual: 32.0,
        paradas: [
          Parada(
            nombre: 'Cruce Viladela',
            horarioPrevisto: '07:00 - 07:30',
            ubicacion: const LatLng(-16.5100, -68.1550),
          ),
          Parada(
            nombre: 'Teleférico Amarillo',
            horarioPrevisto: '07:30 - 08:00',
            ubicacion: const LatLng(-16.4950, -68.1400),
          ),
        ],
      );
}
