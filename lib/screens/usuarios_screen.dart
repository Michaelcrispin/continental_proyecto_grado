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
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;
  String _filtroRol = 'todos';
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _rolesFiltro = [
    'todos',
    'superadmin',
    'admin',
    'supervisor',
    'conductor'
  ];

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

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final lista = await DatabaseHelper.instance.usuariosDetalle(
        rol: _filtroRol == 'todos' ? null : _filtroRol,
        busqueda: _busqueda,
      );
      if (mounted) {
        setState(() {
          _usuarios = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _colorPorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFF8B5CF6);
      case 'admin':
        return AppColors.primaryBlue;
      case 'supervisor':
        return const Color(0xFFF59E0B);
      case 'conductor':
        return const Color(0xFF10B981);
      default:
        return AppColors.textGray;
    }
  }

  String _etiquetaRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return 'SUPERADMIN';
      case 'admin':
        return 'ADMIN';
      case 'supervisor':
        return 'SUPERVISOR';
      case 'conductor':
        return 'CONDUCTOR';
      default:
        return rol.toUpperCase();
    }
  }

  void _mostrarDialogoCrearOEditar({Map<String, dynamic>? usuarioExistente}) {
    final esEdicion = usuarioExistente != null;
    final idUsuario = usuarioExistente?['id_usuario']?.toString();

    String rolSeleccionado = usuarioExistente?['rol']?.toString() ?? 'admin';
    final nombreCtrl =
        TextEditingController(text: usuarioExistente?['nombre']?.toString() ?? '');
    final correoCtrl =
        TextEditingController(text: usuarioExistente?['gmail']?.toString() ?? '');
    final ciCtrl =
        TextEditingController(text: usuarioExistente?['ci']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final placaCtrl =
        TextEditingController(text: usuarioExistente?['placa']?.toString() ?? '');
    final licenciaCtrl =
        TextEditingController(text: usuarioExistente?['licencia']?.toString() ?? '');

    bool estadoActivo = (usuarioExistente?['estado']?.toString() ?? 'activo') == 'activo';
    bool obscurePass = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final esConductor = rolSeleccionado == 'conductor';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    esEdicion ? Icons.edit_note : Icons.person_add_alt_1,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    esEdicion ? 'Editar Usuario' : 'Nuevo Usuario',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rol asignado:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: rolSeleccionado,
                        items: const [
                          DropdownMenuItem(
                            value: 'superadmin',
                            child: Text('Superadmin'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'supervisor',
                            child: Text('Supervisor'),
                          ),
                          DropdownMenuItem(
                            value: 'conductor',
                            child: Text('Conductor'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => rolSeleccionado = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nombre Completo
                  TextField(
                    controller: nombreCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo *',
                      hintText: 'Ej. Juan Carlos Pérez',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Si es staff: correo obligatorio. Si es conductor: opcional
                  TextField(
                    controller: correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: esConductor ? 'Correo electrónico' : 'Correo electrónico *',
                      hintText: 'usuario@continental.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Si es conductor: CI obligatorio y campos adicionales
                  if (esConductor) ...[
                    TextField(
                      controller: ciCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cédula de Identidad *',
                        hintText: 'Ej. 8765432',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!esEdicion) ...[
                      TextField(
                        controller: placaCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Placa del vehículo',
                          hintText: 'Ej. 2045-ABC',
                          prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: licenciaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Licencia de conducir',
                        hintText: 'Ej. Cat. Profesional C',
                        prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Contraseña
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: esEdicion ? 'Nueva contraseña' : 'Contraseña de acceso *',
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

                  // Estado Activo / Inactivo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoActivo ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: estadoActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              estadoActivo ? Icons.check_circle : Icons.cancel,
                              color: estadoActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              estadoActivo ? 'Cuenta Activa' : 'Cuenta Inactiva',
                              style: TextStyle(
                                color: estadoActivo ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: estadoActivo,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) => setDialogState(() => estadoActivo = val),
                        ),
                      ],
                    ),
                  ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  final correo = correoCtrl.text.trim();
                  final ci = ciCtrl.text.trim();
                  final password = passCtrl.text.trim();
                  final estado = estadoActivo ? 'activo' : 'inactivo';

                  if (nombre.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El nombre es obligatorio.')),
                    );
                    return;
                  }

                  if (!esConductor && correo.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Los roles staff requieren correo electrónico para login.')),
                    );
                    return;
                  }

                  if (esConductor && ci.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El conductor requiere su número de CI para login.')),
                    );
                    return;
                  }

                  if (!esEdicion && password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debe asignar una contraseña al nuevo usuario.')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  try {
                    if (esEdicion && idUsuario != null) {
                      await DatabaseHelper.instance.actualizarUsuarioCompleto(
                        idUsuario: idUsuario,
                        nombre: nombre,
                        gmail: correo.isEmpty ? null : correo,
                        rol: rolSeleccionado,
                        estado: estado,
                        newPassword: password.isEmpty ? null : password,
                        ci: ci.isEmpty ? null : ci,
                        licencia: licenciaCtrl.text.trim().isEmpty ? null : licenciaCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario actualizado correctamente.')),
                        );
                      }
                    } else {
                      await DatabaseHelper.instance.crearUsuarioCompleto(
                        rol: rolSeleccionado,
                        nombre: nombre,
                        gmail: correo.isEmpty ? null : correo,
                        ci: ci.isEmpty ? null : ci,
                        password: password,
                        estado: estado,
                        placa: placaCtrl.text.trim().isEmpty ? null : placaCtrl.text.trim(),
                        licencia: licenciaCtrl.text.trim().isEmpty ? null : licenciaCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Usuario "$nombre" creado exitosamente. Ya puede iniciar sesión.'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    }
                    _cargarUsuarios();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar usuario: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: Text(
                  esEdicion ? 'Guardar Cambios' : 'Crear Usuario',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmarEliminar(Map<String, dynamic> usuario) {
    final id = usuario['id_usuario']?.toString();
    final nombre = usuario['nombre'] ?? 'este usuario';

    // Evitar eliminar al usuario que tiene la sesión activa
    if (id == SesionService.instance.idUsuario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar la cuenta con la que has iniciado sesión.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Usuario', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente a "$nombre"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              if (id != null) {
                await DatabaseHelper.instance.eliminarUsuarioCompleto(id);
                _cargarUsuarios();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario eliminado correctamente.')),
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

  @override
  Widget build(BuildContext context) {
    final totalActivos = _usuarios.where((u) => u['estado'] == 'activo').length;
    final totalInactivos = _usuarios.length - totalActivos;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
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
              // Buscador y Resumen
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, correo o CI...',
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
                    const SizedBox(height: 12),

                    // Contador de métricas rápidas
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people, color: AppColors.primaryBlue, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${_usuarios.length} registrados',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalActivos activos',
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (totalInactivos > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalInactivos inactivos',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Barra de Pestañas de Roles
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _rolesFiltro.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final rol = _rolesFiltro[index];
                    final seleccionado = _filtroRol == rol;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _filtroRol = rol);
                        _cargarUsuarios();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: seleccionado ? AppColors.primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: seleccionado ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          rol == 'todos' ? 'Todos' : _etiquetaRol(rol),
                          style: TextStyle(
                            color: seleccionado ? Colors.white : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Lista de Usuarios
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _usuarios.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off_outlined, size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('No se encontraron usuarios',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                            itemCount: _usuarios.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final u = _usuarios[index];
                              final id = u['id_usuario']?.toString() ?? '';
                              final nombre = u['nombre'] ?? 'Sin nombre';
                              final rol = u['rol']?.toString() ?? 'conductor';
                              final gmail = u['gmail']?.toString();
                              final ci = u['ci']?.toString();
                              final placa = u['placa']?.toString();
                              final estado = u['estado']?.toString() ?? 'activo';
                              final esActivo = estado == 'activo';
                              final colorRol = _colorPorRol(rol);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar con color de rol
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: colorRol.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        rol == 'conductor'
                                            ? Icons.directions_bus
                                            : rol == 'superadmin'
                                                ? Icons.admin_panel_settings
                                                : Icons.person,
                                        color: colorRol,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Datos de usuario
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  nombre,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1E3A8A),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: colorRol.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: colorRol.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  _etiquetaRol(rol),
                                                  style: TextStyle(
                                                    color: colorRol,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // Identificador (Correo o CI)
                                          if (gmail != null && gmail.isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(Icons.email_outlined, size: 13, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    gmail,
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (ci != null && ci.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'CI: $ci',
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                                  ),
                                                  if (placa != null && placa.isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '• Auto: $placa',
                                                      style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Switch Activar/Desactivar rápido
                                    Switch(
                                      value: esActivo,
                                      activeColor: const Color(0xFF10B981),
                                      inactiveThumbColor: const Color(0xFFEF4444),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) async {
                                        final nuevoEstado = val ? 'activo' : 'inactivo';
                                        await DatabaseHelper.instance.cambiarEstadoUsuario(id, nuevoEstado);
                                        _cargarUsuarios();
                                      },
                                    ),

                                    // Menú de opciones: Editar o Eliminar
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                                      onSelected: (accion) {
                                        if (accion == 'editar') {
                                          _mostrarDialogoCrearOEditar(usuarioExistente: u);
                                        } else if (accion == 'eliminar') {
                                          _confirmarEliminar(u);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'editar',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18),
                                              SizedBox(width: 8),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'eliminar',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Color(0xFFEF4444), size: 18),
                                              SizedBox(width: 8),
                                              Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      // Botón flotante para crear nuevo usuario
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Nuevo Usuario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _mostrarDialogoCrearOEditar(),
      ),
    );
  }
}
