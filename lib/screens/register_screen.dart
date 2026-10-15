import 'package:flutter/material.dart';
import '../widgets/wave_header.dart';
import '../services/database_helper.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _pass1Controller = TextEditingController();
  final TextEditingController _pass2Controller = TextEditingController();

  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _acceptTerms = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _handleRegister() async {
    final nombre = _nombreController.text.trim();
    final ci = _ciController.text.trim();
    final pass1 = _pass1Controller.text.trim();
    final pass2 = _pass2Controller.text.trim();

    if (nombre.isEmpty || ci.isEmpty || pass1.isEmpty || pass2.isEmpty) {
      setState(() => _errorMessage = 'Por favor, completa todos los campos.');
      return;
    }

    if (pass1 != pass2) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
      return;
    }

    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Debes aceptar los términos y condiciones.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DatabaseHelper.instance.registrarConductor(
        nombre: nombre,
        ci: ci,
        password: pass1,
        fechaIncorporacion: DateTime.now().toIso8601String().substring(0, 10),
      );

      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta registrada exitosamente en la base de datos. Inicia sesión.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al registrar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const WaveHeader(height: 220),
            const SizedBox(height: 10),
            const Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completa tus datos para registrarte',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildTextField(
                    controller: _nombreController,
                    hint: 'Nombre completo',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _ciController,
                    hint: 'Cédula de Identidad (CI)',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(
                    controller: _pass1Controller,
                    hint: 'Contraseña',
                    icon: Icons.lock,
                    obscure: _obscurePassword1,
                    onToggle: () {
                      setState(() {
                        _obscurePassword1 = !_obscurePassword1;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(
                    controller: _pass2Controller,
                    hint: 'Confirmar contraseña',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword2,
                    onToggle: () {
                      setState(() {
                        _obscurePassword2 = !_obscurePassword2;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  
                  // Acepto términos
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: (val) {
                            setState(() {
                              _acceptTerms = val ?? true;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          activeColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Acepto los ',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const Text(
                        'términos y condiciones',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Botón Registrarse
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Texto Iniciar Sesión
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes una cuenta? ',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
