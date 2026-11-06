import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sesion_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Paleta verde corporativa (coherente con Login)
const _kVerdeOscuro = Color(0xFF02634C);
const _kVerdeTeal = Color(0xFF0D7C66);
const _kGrisSubtitulo = Color(0xFF64748B);
const _kGrisBorde = Color(0xFFE2E8F0);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    _comprobarSesion();
  }

  Future<void> _comprobarSesion() async {
    // Breve pausa para mostrar la identidad corporativa
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Verificar si existe sesión persistida válida en SQLite
    final haySesion = await SesionService.instance.cargarSesion();

    if (!mounted) return;

    if (haySesion) {
      // Si ya tiene sesión activa, redirigir directamente al Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() {
        _verificando = false;
      });
    }
  }

  void _irALogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Contenido desplazable para evitar desbordes en pantallas pequeñas
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - padding.top - 28,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // 1. Tarjeta con el Logo Oficial
                          Container(
                            width: 220,
                            height: 110,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _kGrisBorde,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.directions_bus_rounded,
                                  color: _kVerdeOscuro,
                                  size: 54,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 2. Título Principal
                          Text(
                            'CONTINENTAL',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.russoOne(
                              fontSize: 26,
                              color: _kVerdeOscuro,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 3. Subtítulo: TRUFI 101 - 127
                          const Text(
                            'TRUFI 101 - 127',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _kVerdeTeal,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 4. Descripción institucional
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Control y gestión del servicio de transporte del Grupo Continental',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _kGrisSubtitulo,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // 5. Botón Iniciar sesión →
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _verificando ? null : _irALogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kVerdeOscuro,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: _kVerdeOscuro.withOpacity(0.25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _verificando
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Iniciar sesión',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 6. Enlace secundario: Acceder al sistema
                          TextButton(
                            onPressed: _verificando ? null : _irALogin,
                            style: TextButton.styleFrom(
                              foregroundColor: _kVerdeTeal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 20,
                              ),
                            ),
                            child: const Text(
                              'Acceder al sistema',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // 7. Ícono de minibús / trufi y ciudad
                          const Icon(
                            Icons.directions_bus_rounded,
                            color: _kVerdeTeal,
                            size: 34,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'El Alto - La Paz',
                            style: TextStyle(
                              color: _kGrisSubtitulo,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),

                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 8. Barra inferior verde
            Container(
              width: double.infinity,
              height: 28 + (padding.bottom > 0 ? padding.bottom : 6),
              color: _kVerdeOscuro,
            ),
          ],
        ),
      ),
    );
  }
}
