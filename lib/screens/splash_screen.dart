import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/app_background.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80), // Lo bajamos un poco (intermedio entre 40 y 120)
                    // Logo principal
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 180, // Lo hacemos un poco más grande
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.public, color: AppColors.primaryDark, size: 100);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Títulos
                    Text(
                      'CONTINENTAL',
                      style: GoogleFonts.russoOne(
                        fontSize: 34,
                        color: AppColors.primaryDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TRUFI 101 - 127',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                        letterSpacing: 1.0,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Container(
                      width: 45,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF93C5FD), // Un poco más claro y fino
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Descripción
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'Control y gestión del servicio\nde transporte del Grupo Continental',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 15, // Restaurado al tamaño original
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botones y pie de página
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  // Botón Principal
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Iniciar sesión', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Acceso Secundario
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: const Text(
                      'Acceder al sistema',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Ícono de auto con líneas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 40, height: 1, color: const Color(0xFFBFDBFE)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Image.asset(
                          'assets/images/icono_auto_al_frente.png',
                          height: 40, // Ícono ahora sí más grande
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Container(width: 40, height: 1, color: const Color(0xFFBFDBFE)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ubicación
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: AppColors.primaryBlue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'El Alto · La Paz',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
