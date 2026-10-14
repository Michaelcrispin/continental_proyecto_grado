import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;

  const AppBackground({
    super.key, 
    required this.child,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = useSafeArea ? SafeArea(child: child) : child;

    return Stack(
      children: [
        // Fondo base
        Container(color: AppColors.background),
        
        // Marca de agua del globo (Logo gigante con baja opacidad)
        Positioned(
          left: -120,
          bottom: -80,
          child: Opacity(
            opacity: 0.04, // Transparencia muy sutil
            child: Image.asset(
              'assets/images/logo.png',
              width: 450,
              height: 450,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(), // Ignorar si no carga
            ),
          ),
        ),

        // Fondo decorativo con curvas
        Positioned.fill(
          child: CustomPaint(
            painter: _BackgroundPainter(),
          ),
        ),
        
        // Contenido de la pantalla
        content,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLightBlue = Paint()
      ..color = AppColors.waveLight.withOpacity(0.6)
      ..style = PaintingStyle.fill;
      
    final paintMidBlue = Paint()
      ..color = AppColors.waveMid.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final paintDarkBlue = Paint()
      ..color = AppColors.waveDark.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    // Top left curve
    final pathTop = Path();
    pathTop.moveTo(0, 0);
    pathTop.lineTo(size.width * 0.45, 0);
    pathTop.quadraticBezierTo(
      size.width * 0.2, size.height * 0.12,
      0, size.height * 0.22,
    );
    pathTop.close();
    canvas.drawPath(pathTop, paintLightBlue);

    // Bottom right curve 1 (Light blue base)
    final pathBottom1 = Path();
    pathBottom1.moveTo(size.width, size.height);
    pathBottom1.lineTo(size.width * 0.15, size.height);
    pathBottom1.quadraticBezierTo(
      size.width * 0.6, size.height * 0.85,
      size.width, size.height * 0.6,
    );
    pathBottom1.close();
    canvas.drawPath(pathBottom1, paintLightBlue);
    
    // Bottom right curve 2 (Mid blue)
    final pathBottom2 = Path();
    pathBottom2.moveTo(size.width, size.height);
    pathBottom2.lineTo(size.width * 0.35, size.height);
    pathBottom2.quadraticBezierTo(
      size.width * 0.75, size.height * 0.88,
      size.width, size.height * 0.75,
    );
    pathBottom2.close();
    canvas.drawPath(pathBottom2, paintMidBlue);
    
    // Bottom right curve 3 (Dark blue corner)
    final pathBottom3 = Path();
    pathBottom3.moveTo(size.width, size.height);
    pathBottom3.lineTo(size.width * 0.55, size.height);
    pathBottom3.quadraticBezierTo(
      size.width * 0.85, size.height * 0.95,
      size.width, size.height * 0.85,
    );
    pathBottom3.close();
    canvas.drawPath(pathBottom3, paintDarkBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
