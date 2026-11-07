import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/gps_tracking_service.dart';
import '../services/sesion_service.dart';
import 'home_screen.dart';

// Paleta extraída fielmente del diseño
const _kVerdeOscuro = Color(0xFF02634C);
const _kVerdeFondoCirculo = Color(0xFF01382A);
const _kMentaTexto = Color(0xFF7DE3B5);
const _kMentaInput = Color(0xFFE8F5EF);
const _kMentaOla = Color(0xFFA8E6C8);
const _kMentaNeon = Color(0xFF34D399);
const _kOroCorona = Color(0xFFFFB800);
const _kGrisTexto = Color(0xFF6B7280);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identificadorController =
      TextEditingController();
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

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final identificador = _identificadorController.text.trim();
    final pass = _passController.text.trim();

    if (identificador.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Por favor, completa ambos campos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuarioMap =
          await DatabaseHelper.instance.login(identificador, pass);

      if (usuarioMap != null) {
        await SesionService.instance.iniciarSesion(usuarioMap);

        // Arranca el conteo automático de vueltas A→B→A en segundo plano
        // (fuera de las pantallas, sobrevive cambios de vista y bloqueo del teclado)
        final idConductor = SesionService.instance.idConductor;
        GpsTrackingService.instance
            .iniciar(idConductor: idConductor)
            .catchError((_) {});

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Credenciales incorrectas o cuenta inactiva';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  void _mostrarRecuperarPass() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: _kVerdeOscuro),
            SizedBox(width: 8),
            Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kVerdeOscuro,
              ),
            ),
          ],
        ),
        content: const Text(
          'Para restablecer tu contraseña o verificar tu cuenta de conductor, '
          'por favor comunícate con la administración del Sindicato Continental Trufi.',
          style: TextStyle(color: Color(0xFF334155), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: _kVerdeOscuro,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarCrearCuenta() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: _kVerdeOscuro),
            SizedBox(width: 8),
            Text(
              'Crear una cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kVerdeOscuro,
              ),
            ),
          ],
        ),
        content: const Text(
          'El registro de nuevos conductores y vehículos es gestionado directamente '
          'por el comité de control del Sindicato Continental.\n\n'
          'Presenta tu cédula y licencia en oficinas para habilitar tu usuario.',
          style: TextStyle(color: Color(0xFF334155), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: _kVerdeOscuro,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: size.height,
          ),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                // 1. Fondo Superior Verde con ondas orgánicas y Corona
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.36,
                  child: Stack(
                    children: [
                      // Fondo verde con onda suave
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FondoSuperiorPainter(),
                        ),
                      ),
                      // Contenido del Header: Botón atrás, Corona, Título y Subtítulo
                      Positioned(
                        top: padding.top + 8,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            // Fila con flecha atrás
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),

                            // Corona Dorada
                            CustomPaint(
                              size: const Size(42, 30),
                              painter: _CoronaPainter(),
                            ),
                            const SizedBox(height: 14),

                            // Título: "¡Bienvenido otra vez!"
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '¡Bienvenido ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'otra vez!',
                                      style: TextStyle(
                                        color: _kMentaTexto,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtítulo
                            const Text(
                              'Inicia sesión para continuar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Ondas del Footer (Fondo Inferior limpio sin texto)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.28,
                  child: Stack(
                    children: [
                      // Ondas orgánicas
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FondoInferiorPainter(),
                        ),
                      ),
                      // Barra Home Indicator en el fondo
                      Positioned(
                        bottom: 8,
                        left: size.width * 0.35,
                        right: size.width * 0.35,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Formulario Central (Inputs, Botones, Enlaces)
                Positioned(
                  top: size.height * 0.32,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mensaje de Error si existe
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFFCA5A5), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Input 1: CI o Correo electrónico
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _kMentaInput,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextField(
                            controller: _identificadorController,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  Icons.badge_outlined,
                                  color: _kVerdeOscuro,
                                  size: 24,
                                ),
                              ),
                              prefixIconConstraints: BoxConstraints(
                                minWidth: 50,
                                minHeight: 24,
                              ),
                              hintText: 'CI o Correo electrónico',
                              hintStyle: TextStyle(
                                color: _kGrisTexto,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Input 2: Contraseña
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _kMentaInput,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextField(
                            controller: _passController,
                            obscureText: _obscureText,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: _kVerdeOscuro,
                                  size: 24,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 50,
                                minHeight: 24,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _kGrisTexto,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                              hintText: 'Contraseña',
                              hintStyle: const TextStyle(
                                color: _kGrisTexto,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Botón Primario: "Iniciar Sesión →"
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kVerdeOscuro,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Línea divisora con "¿Olvidaste tu contraseña?"
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFCBD5E1),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: InkWell(
                                onTap: _mostrarRecuperarPass,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: _kVerdeOscuro,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFCBD5E1),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Botón Secundario: "Crear una cuenta" (Outlined pill)
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _mostrarCrearCuenta,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: _kVerdeOscuro,
                                width: 1.6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Crear una cuenta',
                              style: TextStyle(
                                color: _kVerdeOscuro,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja la corona dorada minimalista idéntica al diseño
class _CoronaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kOroCorona
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final path = Path();

    // Base inferior curva convexa
    path.moveTo(w * 0.14, h * 0.88);
    // Lado izquierdo sube a la punta izquierda
    path.lineTo(w * 0.05, h * 0.18);
    // Baja al primer valle
    path.lineTo(w * 0.35, h * 0.52);
    // Sube a la punta central (más alta)
    path.lineTo(w * 0.50, h * 0.02);
    // Baja al segundo valle
    path.lineTo(w * 0.65, h * 0.52);
    // Sube a la punta derecha
    path.lineTo(w * 0.95, h * 0.18);
    // Baja al lado derecho inferior
    path.lineTo(w * 0.86, h * 0.88);
    // Base inferior suave
    path.quadraticBezierTo(w * 0.50, h * 1.05, w * 0.14, h * 0.88);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dibuja el fondo verde superior con las formas circulares orgánicas y la curva
class _FondoSuperiorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Capa verde sólida principal
    final bgPaint = Paint()
      ..color = _kVerdeOscuro
      ..style = PaintingStyle.fill;

    // Ruta de la cabecera verde con curva orgánica asimétrica abajo
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h * 0.76);
    // Curva ondulada hacia la izquierda (sube con estilo en la izquierda)
    path.cubicTo(
      w * 0.65,
      h * 0.78,
      w * 0.30,
      h * 0.96,
      0,
      h * 0.82,
    );
    path.close();

    canvas.drawPath(path, bgPaint);

    // 2. Círculos abstractos decorativos (fondo sutil)
    final blobPaint = Paint()
      ..color = _kVerdeFondoCirculo.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Círculo orgánico superior derecho
    canvas.drawCircle(Offset(w * 0.92, h * 0.16), w * 0.32, blobPaint);

    // Círculo orgánico medio izquierdo
    final blobPaint2 = Paint()
      ..color = const Color(0xFF025843).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-w * 0.08, h * 0.46), w * 0.28, blobPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dibuja las ondas inferiores con la transición menta -> verde oscuro y líneas de acento
class _FondoInferiorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Onda trasera color menta pastel
    final mentaPaint = Paint()
      ..color = _kMentaOla.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final mentaPath = Path();
    mentaPath.moveTo(0, h * 0.45);
    mentaPath.cubicTo(
      w * 0.22,
      h * 0.25,
      w * 0.45,
      h * 0.60,
      w,
      h * 0.15,
    );
    mentaPath.lineTo(w, h);
    mentaPath.lineTo(0, h);
    mentaPath.close();

    canvas.drawPath(mentaPath, mentaPaint);

    // 2. Onda frontal verde oscuro principal
    final verdePaint = Paint()
      ..color = _kVerdeOscuro
      ..style = PaintingStyle.fill;

    final verdePath = Path();
    verdePath.moveTo(0, h * 0.92);
    verdePath.cubicTo(
      w * 0.25,
      h * 0.82,
      w * 0.40,
      h * 0.42,
      w,
      h * 0.30,
    );
    verdePath.lineTo(w, h);
    verdePath.lineTo(0, h);
    verdePath.close();

    canvas.drawPath(verdePath, verdePaint);

    // 3. Líneas de acento / estela neón menta
    final neonPaint = Paint()
      ..color = _kMentaNeon.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final neonPath = Path();
    neonPath.moveTo(w * 0.08, h * 0.88);
    neonPath.cubicTo(
      w * 0.28,
      h * 0.78,
      w * 0.42,
      h * 0.95,
      w * 0.75,
      h * 0.88,
    );
    canvas.drawPath(neonPath, neonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
