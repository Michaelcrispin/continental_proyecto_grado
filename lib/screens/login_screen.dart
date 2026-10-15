import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/app_background.dart';
import 'home_screen.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identificadorController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identificadorController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Evita doble toque concurrente
    if (_isLoading) return;

    final identificador = _identificadorController.text.trim();
    final pass = _passController.text.trim();

    // 1. Validar que ninguno esté vacío
    if (identificador.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Por favor, completa ambos campos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Consulta de credenciales en SQLite (soporta correo o CI de chofer)
      final usuarioMap = await DatabaseHelper.instance.login(identificador, pass);

      if (usuarioMap != null) {
        // 3. Guardar y persistir la sesión con SharedPreferences y resolver id_conductor si corresponde
        await SesionService.instance.iniciarSesion(usuarioMap);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Credenciales incorrectas o cuenta inactiva';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                  errorBuilder: (c, e, s) => const Icon(Icons.public, color: AppColors.primaryDark, size: 60),
                ),
              ),
              
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Hola de nuevo!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!, 
                                style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Campo único: CI o Correo
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        controller: _identificadorController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
                          hintText: 'CI o correo',
                          hintStyle: TextStyle(color: AppColors.textLight),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Ingresa tu CI (conductor) o correo institucional', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                    const SizedBox(height: 20),
                    
                    // Password Input con botón mostrar/ocultar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        controller: _passController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryBlue),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          hintText: 'Contraseña',
                          hintStyle: const TextStyle(color: AppColors.textLight),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Ingresa tu contraseña', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                    const SizedBox(height: 40),
                    
                    // Botón Iniciar Sesión con prevención de doble toque e indicador de carga
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Iniciar sesión', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Pie de página (Ubicación)
              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: AppColors.primaryBlue, size: 16),
                    SizedBox(width: 4),
                    Text('El Alto - La Paz', style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
