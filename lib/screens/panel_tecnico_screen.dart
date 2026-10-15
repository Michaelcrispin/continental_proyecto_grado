import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class PanelTecnicoScreen extends StatefulWidget {
  const PanelTecnicoScreen({super.key});

  @override
  State<PanelTecnicoScreen> createState() => _PanelTecnicoScreenState();
}

class _PanelTecnicoScreenState extends State<PanelTecnicoScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;
  String _filtroRol = 'todos';

  @override
  void initState() {
    super.initState();
    // Protección de ruta directa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(context, SesionService.instance.rol, Permisos.moduloPanelTecnico)) {
        return;
      }
    });
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await DatabaseHelper.instance.listar('usuario', orderBy: 'fecha_creacion DESC');
      if (mounted) {
        setState(() {
          _usuarios = usuarios;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoNuevoStaff() {
    String rolSeleccionado = 'admin';
    final nombreCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Crear Usuario Staff', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rol a asignar:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: rolSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                  ],
                  onChanged: (val) => setDialogState(() => rolSeleccionado = val ?? 'admin'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo', hintText: 'Ej. Carlos Sánchez'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', hintText: 'ejemplo@continental.com'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña de acceso', hintText: 'Mínimo 6 caracteres'),
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
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();
                final correo = correoCtrl.text.trim();
                final pass = passCtrl.text.trim();

                if (nombre.isEmpty || correo.isEmpty || pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor completa todos los campos.')),
                  );
                  return;
                }

                if (!correo.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa un correo electrónico válido.')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  await DatabaseHelper.instance.crearUsuarioStaff(
                    rol: rolSeleccionado,
                    nombre: nombre,
                    gmail: correo,
                    password: pass,
                  );
                  _cargarUsuarios();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Usuario $rolSeleccionado creado con éxito.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear usuario: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarEstadoUsuario(Map<String, dynamic> usuario) async {
    final idUsuario = usuario['id_usuario']?.toString();
    final estadoActual = usuario['estado']?.toString() ?? 'activo';
    final nuevoEstado = estadoActual == 'activo' ? 'inactivo' : 'activo';

    // Evitar que el superadmin se auto-bloquee
    if (idUsuario == SesionService.instance.idUsuario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes desactivar tu propia cuenta en sesión.')),
      );
      return;
    }

    await DatabaseHelper.instance.actualizar('usuario', idUsuario!, {'estado': nuevoEstado});
    _cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    final usuariosFiltrados = _usuarios.where((u) {
      if (_filtroRol == 'todos') return true;
      return (u['rol']?.toString().toLowerCase() ?? '') == _filtroRol;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Panel Técnico (Superadmin)', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _cargarUsuarios,
          ),
        ],
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Filtro por rol
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChipFiltro('Todos', 'todos'),
                    const SizedBox(width: 8),
                    _buildChipFiltro('Superadmin', 'superadmin'),
                    const SizedBox(width: 8),
                    _buildChipFiltro('Admin', 'admin'),
                    const SizedBox(width: 8),
                    _buildChipFiltro('Supervisor', 'supervisor'),
                    const SizedBox(width: 8),
                    _buildChipFiltro('Conductor', 'conductor'),
                  ],
                ),
              ),
            ),

            // Lista de usuarios en SQLite
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : usuariosFiltrados.isEmpty
                      ? const Center(
                          child: Text('No hay usuarios registrados con este rol.', style: TextStyle(color: Color(0xFF64748B))),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarUsuarios,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: usuariosFiltrados.length,
                            itemBuilder: (context, index) {
                              final u = usuariosFiltrados[index];
                              final nombre = u['nombre'] ?? 'Sin nombre';
                              final rol = u['rol']?.toString().toUpperCase() ?? 'STAFF';
                              final correo = u['gmail'] ?? 'Sin correo (Conductor)';
                              final estado = u['estado']?.toString() ?? 'activo';
                              final esActivo = estado == 'activo';

                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _obtenerColorRol(rol).withValues(alpha: 0.1),
                                      child: Icon(Icons.badge, color: _obtenerColorRol(rol)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(nombre, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text('$rol • $correo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        esActivo ? Icons.lock_open : Icons.lock,
                                        color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                      tooltip: esActivo ? 'Bloquear cuenta' : 'Activar cuenta',
                                      onPressed: () => _cambiarEstadoUsuario(u),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _mostrarDialogoNuevoStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Crear Admin / Supervisor', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipFiltro(String label, String valor) {
    final seleccionado = _filtroRol == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroRol = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: seleccionado ? AppColors.primaryBlue : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? Colors.white : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _obtenerColorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'SUPERADMIN':
        return const Color(0xFF8B5CF6);
      case 'ADMIN':
        return const Color(0xFF3B82F6);
      case 'SUPERVISOR':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
