import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Punto azul de ubicación estilo Google Maps.
///
/// Dibuja:
///  - un halo pulsante (opcional),
///  - un cono translúcido que apunta hacia donde mira el usuario,
///  - el punto azul con borde blanco y una flecha blanca en el rumbo actual.
///
/// [rumboGrados] es la dirección en grados respecto al norte (0 = norte,
/// 90 = este). Si [rumboValido] es `false` solo se muestra el punto.
class UbicacionAzul extends StatefulWidget {
  const UbicacionAzul({
    super.key,
    this.rumboGrados = 0,
    this.rumboListenable,
    this.tamano = 120,
    this.tamanoPunto = 22,
    this.rumboValido = true,
    this.mostrarCono = true,
    this.conPulso = true,
    this.color = const Color(0xFF1A73E8),
  });

  final double rumboGrados;

  /// Si se entrega, el widget escucha el rumbo sin reconstruir la pantalla
  /// completa (útil dentro de un mapa con brújula a ~50 Hz).
  final ValueListenable<double>? rumboListenable;

  final double tamano;
  final double tamanoPunto;
  final bool rumboValido;
  final bool mostrarCono;
  final bool conPulso;
  final Color color;

  @override
  State<UbicacionAzul> createState() => _UbicacionAzulState();
}

class _UbicacionAzulState extends State<UbicacionAzul>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.conPulso) _pulso.repeat();
  }

  @override
  void didUpdateWidget(covariant UbicacionAzul oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conPulso && !_pulso.isAnimating) {
      _pulso.repeat();
    } else if (!widget.conPulso && _pulso.isAnimating) {
      _pulso.stop();
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenable = widget.rumboListenable;
    if (listenable == null) return _construir(widget.rumboGrados);
    return ValueListenableBuilder<double>(
      valueListenable: listenable,
      builder: (context, rumbo, _) => _construir(rumbo),
    );
  }

  Widget _construir(double rumboGrados) {
    // Normaliza a 0..360 para que el giro no acumule vueltas.
    final rumbo = ((rumboGrados % 360) + 360) % 360;
    final radianes = rumbo * math.pi / 180;
    final tamano = widget.tamano;
    final diametro = math.max(widget.tamanoPunto, 32.0);

    return SizedBox(
      width: tamano,
      height: tamano,
      child: AnimatedBuilder(
        animation: _pulso,
        builder: (context, _) {
          final t = _pulso.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Halo pulsante.
              if (widget.conPulso)
                Container(
                  width: diametro + (tamano * 0.34) * t,
                  height: diametro + (tamano * 0.34) * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.18 * (1 - t)),
                  ),
                ),

              // Cono de dirección.
              if (widget.mostrarCono && widget.rumboValido)
                Transform.rotate(
                  angle: radianes,
                  child: CustomPaint(
                    size: Size.square(tamano),
                    painter: _ConoDireccionPainter(
                      color: widget.color,
                      radioInterior: diametro / 2,
                    ),
                  ),
                ),

              // Marcador de auto (trufi) con borde blanco y sombra.
              Container(
                width: diametro,
                height: diametro,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: Colors.white,
                    size: diametro * 0.60,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Cono translúcido que sale desde el punto azul hacia el rumbo actual.
class _ConoDireccionPainter extends CustomPainter {
  const _ConoDireccionPainter({
    required this.color,
    required this.radioInterior,
  });

  final Color color;
  final double radioInterior;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radioExterior = math.min(size.width, size.height) / 2 - 2;
    const apertura = 26 * math.pi / 180; // medio ángulo del cono

    final inicioArco = -math.pi / 2 - apertura;
    final finArco = -math.pi / 2 + apertura;

    final p1 =
        centro +
        Offset(math.cos(inicioArco), math.sin(inicioArco)) * radioExterior;
    final pi1 =
        centro +
        Offset(math.cos(inicioArco), math.sin(inicioArco)) * radioInterior;
    final pi2 =
        centro + Offset(math.cos(finArco), math.sin(finArco)) * radioInterior;

    final path = Path()
      ..moveTo(pi1.dx, pi1.dy)
      ..lineTo(p1.dx, p1.dy)
      ..arcTo(
        Rect.fromCircle(center: centro, radius: radioExterior),
        inicioArco,
        apertura * 2,
        false,
      )
      ..lineTo(pi2.dx, pi2.dy)
      ..arcTo(
        Rect.fromCircle(center: centro, radius: radioInterior),
        finArco,
        -apertura * 2,
        false,
      )
      ..close();

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        centro,
        radioExterior,
        [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.0),
        ],
        const [0.32, 0.72, 1.0],
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConoDireccionPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radioInterior != radioInterior;
  }
}
