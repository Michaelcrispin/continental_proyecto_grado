import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';
import '../widgets/app_background.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Map<String, dynamic>> _todosUsuarios = [];
  bool _isLoading = true;
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(
          context, SesionService.instance.rol, Permisos.moduloUsuarios)) {
        return;
      }
    });
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final lista = await DatabaseHelper.instance.usuariosDetalle(
        busqueda: _busqueda,
      );
      if (mounted) {
        setState(() {
          _todosUsuarios = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lista exclusiva de miembros del Directorio (Directiva sindical, administradores, tesoreros y supervisores)
  List<Map<String, dynamic>> get _directorio => _todosUsuarios.where((u) {
        final r = u['rol']?.toString().toLowerCase();
        return r == 'admin' || r == 'superadmin' || r == 'supervisor' || r == 'tesorero';
      }).toList();

  Color _colorPorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFF8B5CF6);
      case 'admin':
        return AppColors.primaryBlue;
      case 'supervisor':
        return const Color(0xFFF59E0B);
      case 'tesorero':
        return const Color(0xFF0D9488);
      default:
        return AppColors.textGray;
    }
  }

  String _etiquetaRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return 'SUPERADMIN';
      case 'admin':
        return 'ADMINISTRADOR';
      case 'supervisor':
        return 'SUPERVISOR';
      case 'tesorero':
        return 'SEC. DE HACIENDA';
      default:
        return rol.toUpperCase();
    }
  }

  Map<String, Color> _estilosRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return {
          'avatarBg': const Color(0xFFF3E8FF),
          'avatarIcon': const Color(0xFF9333EA),
          'badgeBg': const Color(0xFFFAF5FF),
          'badgeText': const Color(0xFF9333EA),
        };
      case 'supervisor':
        return {
          'avatarBg': const Color(0xFFFEF3C7),
          'avatarIcon': const Color(0xFFD97706),
          'badgeBg': const Color(0xFFFFFBEB),
          'badgeText': const Color(0xFFD97706),
        };
      case 'tesorero':
        return {
          'avatarBg': const Color(0xFFCCFBF1),
          'avatarIcon': const Color(0xFF0F766E),
          'badgeBg': const Color(0xFFF0FDFA),
          'badgeText': const Color(0xFF0F766E),
        };
      case 'admin':
      default:
        return {
          'avatarBg': const Color(0xFFDBEAFE),
          'avatarIcon': const Color(0xFF2563EB),
          'badgeBg': const Color(0xFFEFF6FF),
          'badgeText': const Color(0xFF2563EB),
        };
    }
  }

  // ---------------------------------------------------------------------------
  // MODAL DE ÉXITO
  // ---------------------------------------------------------------------------
  void _mostrarModalExito({
    required String titulo,
    required String nombre,
    required String rol,
    String? identificador,
    bool esEdicion = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                esEdicion
                    ? 'Los datos fueron actualizados correctamente en la base de datos.'
                    : 'El registro se guardó correctamente. La cuenta del directorio ya se encuentra habilitada.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        const Text(
                          'Nombre: ',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        const Text(
                          'Cargo: ',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _colorPorRol(rol).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _etiquetaRol(rol),
                            style: TextStyle(
                              color: _colorPorRol(rol),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (identificador != null && identificador.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          const Text(
                            'Correo de acceso: ',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          Expanded(
                            child: Text(
                              identificador,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORMULARIO: DIRECTORIO (Directiva, Administradores y Supervisores)
  // ---------------------------------------------------------------------------
  void _mostrarDialogoDirectorio({Map<String, dynamic>? usuarioExistente}) {
    final esEdicion = usuarioExistente != null;
    final idUsuario = usuarioExistente?['id_usuario']?.toString();

    String rolDirectorio = usuarioExistente?['rol']?.toString() ?? 'admin';
    final nombreCtrl = TextEditingController(text: usuarioExistente?['nombre']?.toString() ?? '');
    final correoCtrl = TextEditingController(text: usuarioExistente?['gmail']?.toString() ?? '');
    final passCtrl = TextEditingController();

    bool estadoActivo = (usuarioExistente?['estado']?.toString() ?? 'activo') == 'activo';
    bool obscurePass = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF1E3A8A), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esEdicion ? 'Editar Directorio' : 'Nuevo Miembro del Directorio',
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const Text(
                        'Directiva sindical, administradores y supervisores',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cargo directivo / Rol de acceso:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: rolDirectorio,
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador / Mesa Directiva'),
                          ),
                          DropdownMenuItem(
                            value: 'tesorero',
                            child: Text('Secretario de Hacienda / Tesorero'),
                          ),
                          DropdownMenuItem(
                            value: 'supervisor',
                            child: Text('Supervisor de Control / Ruta'),
                          ),
                          DropdownMenuItem(
                            value: 'superadmin',
                            child: Text('Super Administrador'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => rolDirectorio = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre y Apellidos *',
                      hintText: 'Ej. Fernando Quispe',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico de acceso *',
                      hintText: 'directiva@continental.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: esEdicion ? 'Nueva contraseña (opcional)' : 'Contraseña de acceso *',
                      hintText: esEdicion ? 'Sin cambios' : 'Mínimo 4 caracteres',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchEstado(estadoActivo, (val) => setDialogState(() => estadoActivo = val)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  final correo = correoCtrl.text.trim();
                  final password = passCtrl.text.trim();
                  final estado = estadoActivo ? 'activo' : 'inactivo';

                  if (nombre.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El nombre es obligatorio.')),
                    );
                    return;
                  }
                  if (correo.isEmpty || !correo.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingrese un correo institucional válido.')),
                    );
                    return;
                  }
                  if (!esEdicion && password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debe asignar una contraseña.')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    if (esEdicion && idUsuario != null) {
                      await DatabaseHelper.instance.actualizarUsuarioCompleto(
                        idUsuario: idUsuario,
                        nombre: nombre,
                        gmail: correo,
                        rol: rolDirectorio,
                        estado: estado,
                        newPassword: password.isEmpty ? null : password,
                      );
                      _cargarUsuarios();
                      if (mounted) {
                        _mostrarModalExito(
                          titulo: '¡Directorio Actualizado!',
                          nombre: nombre,
                          rol: rolDirectorio,
                          identificador: correo,
                          esEdicion: true,
                        );
                      }
                    } else {
                      await DatabaseHelper.instance.crearUsuarioCompleto(
                        rol: rolDirectorio,
                        nombre: nombre,
                        gmail: correo,
                        password: password,
                        estado: estado,
                      );
                      _cargarUsuarios();
                      if (mounted) {
                        _mostrarModalExito(
                          titulo: '¡Miembro Registrado!',
                          nombre: nombre,
                          rol: rolDirectorio,
                          identificador: correo,
                          esEdicion: false,
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: Text(
                  esEdicion ? 'Guardar Cambios' : 'Registrar en Directorio',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchEstado(bool estadoActivo, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: estadoActivo ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estadoActivo ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                estadoActivo ? Icons.check_circle_outline : Icons.block,
                color: estadoActivo ? const Color(0xFF059669) : const Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                estadoActivo ? 'Estado: HABILITADO' : 'Estado: INHABILITADO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: estadoActivo ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          Switch(
            value: estadoActivo,
            activeColor: const Color(0xFF059669),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _mostrarFichaDetalle(Map<String, dynamic> d) {
    final nombre = d['nombre'] ?? 'Sin nombre';
    final correo = d['gmail'] ?? 'Sin correo';
    final rol = d['rol']?.toString() ?? 'admin';
    final estado = d['estado']?.toString() ?? 'activo';
    final esActivo = estado == 'activo';
    final estilo = _estilosRol(rol);
    final fechaCreacion = d['fecha_creacion']?.toString() ?? d['created_at']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: estilo['avatarBg'],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: estilo['avatarIcon'], size: 40),
              ),
              const SizedBox(height: 14),
              Text(
                nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estilo['badgeBg'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _etiquetaRol(rol),
                  style: TextStyle(
                    color: estilo['badgeText'],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        const Text('Correo: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        Expanded(
                          child: Text(
                            correo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        const Text('Estado: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        Text(
                          esActivo ? 'Habilitado' : 'Inhabilitado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    if (fechaCreacion != null && fechaCreacion.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          const Text('Registrado: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          Text(
                            fechaCreacion.length >= 10 ? fechaCreacion.substring(0, 10) : fechaCreacion,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En el futuro aquí podrás ver el historial completo y documentación.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(Map<String, dynamic> usuario) {
    final idUsuario = usuario['id_usuario'];
    final nombre = usuario['nombre'] ?? 'este usuario';

    if (idUsuario == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar baja'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "$nombre" del Directorio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DatabaseHelper.instance.eliminarUsuarioCompleto(idUsuario.toString());
                _cargarUsuarios();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Miembro "$nombre" eliminado.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONSTRUCCIÓN PRINCIPAL (UI EXCLUSIVA DE DIRECTORIO)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cantDirectorio = _directorio.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Directorio ($cantDirectorio)',
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            tooltip: 'Recargar',
            onPressed: _cargarUsuarios,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Buscador superior
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar miembro por nombre o correo...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _busqueda = '');
                              _cargarUsuarios();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _busqueda = val);
                    _cargarUsuarios();
                  },
                ),
              ),

              // LISTA DIRECTA DEL DIRECTORIO (SIN TABS)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildListaDirectorio(_directorio),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Nuevo Directorio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _mostrarDialogoDirectorio(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LISTA DIRECTORIO: TIPO CUADRADOS (GRID 2 COLUMNAS)
  // ---------------------------------------------------------------------------
  Widget _buildListaDirectorio(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      return _buildVacio(
        icon: Icons.admin_panel_settings_outlined,
        titulo: 'No hay miembros del directorio registrados',
        subtitulo: 'Toca "+ Nuevo Directorio" para registrar directivos, administradores o supervisores.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: lista.length,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final d = lista[index];
        final nombre = d['nombre'] ?? 'Sin nombre';
        final correo = d['gmail'] ?? 'Sin correo';
        final rol = d['rol']?.toString() ?? 'admin';
        final estado = d['estado']?.toString() ?? 'activo';
        final esActivo = estado == 'activo';
        final estilo = _estilosRol(rol);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Avatar circular + Badge de Rol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: estilo['avatarBg'],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: estilo['avatarIcon'], size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estilo['badgeBg'],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _etiquetaRol(rol),
                      style: TextStyle(
                        color: estilo['badgeText'],
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Nombre
              Text(
                nombre,
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Correo
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      correo,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Estado con círculo
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    esActivo ? 'Estado: Habilitado' : 'Estado: Inhabilitado',
                    style: TextStyle(
                      color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Botones de acción: Ver información (Ojito), Editar y Eliminar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF475569)),
                      tooltip: 'Ver información',
                      onPressed: () => _mostrarFichaDetalle(d),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit, size: 15, color: Color(0xFF3B82F6)),
                      tooltip: 'Editar',
                      onPressed: () => _mostrarDialogoDirectorio(usuarioExistente: d),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF4444)),
                      tooltip: 'Eliminar',
                      onPressed: () => _confirmarEliminar(d),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVacio({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
