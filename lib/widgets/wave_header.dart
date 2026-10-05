import 'package:flutter/material.dart';

class WaveHeader extends StatelessWidget {
  final double height;
  const WaveHeader({super.key, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Secondary wave (darker/cyan, peeking from behind)
        ClipPath(
          clipper: SecondaryWaveClipper(),
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              color: Color(0xFF4AC2F6), // Cyan-ish blue
            ),
          ),
        ),
        // Primary wave (light blue gradient)
        ClipPath(
          clipper: PrimaryWaveClipper(),
          child: Container(
            height: height - 15,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFCBEAFB), Color(0xFF90D5FB)], // Light blue gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Logo
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 140, // Increased size as requested
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.public, size: 100, color: Colors.blueAccent);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class PrimaryWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 40);
    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 60);
    path.quadraticBezierTo(
        secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SecondaryWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height - 80);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height + 20);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
        secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
