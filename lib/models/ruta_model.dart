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

  factory Parada.fromMap(Map<String, dynamic> map) {
    return Parada(
      nombre: map['nombre']?.toString() ?? '',
      horarioPrevisto: map['horarioPrevisto']?.toString() ?? '',
      ubicacion: LatLng(
        (map['lat'] as num?)?.toDouble() ?? 0.0,
        (map['lng'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }
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

  factory Ruta.fromMap(Map<String, dynamic> map, {List<Parada> paradas = const []}) {
    return Ruta(
      id: map['id_punto']?.toString() ?? map['id']?.toString() ?? '',
      conductorNombre: map['conductor_nombre']?.toString() ?? '',
      numeroTrufi: map['placa']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'En ruta',
      velocidadActual: (map['velocidad'] as num?)?.toDouble() ?? 0.0,
      paradas: paradas,
    );
  }
}
