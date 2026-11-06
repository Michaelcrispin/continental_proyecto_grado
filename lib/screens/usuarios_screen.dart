import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/avatar_conductor.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);

/// Pantalla "Directorio": Gestión de la Mesa Directiva Sindical y Supervisores.
/// Permite designar democráticamente a los propios conductores de la flota como
/// miembros del Directorio (Secretario de Hacienda, Supervisor, etc.) asignándoles
/// los permisos correspondientes sin duplicar cuentas ni crearlas desde cero.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Map<String, dynamic>> _todosUsuarios = [];
  List<Map<String, dynamic>> _todosConductores = [];
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
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await DatabaseHelper.instance.usuariosDetalle(
        busqueda: _busqueda,
      );
      final conductores = await DatabaseHelper.instance.conductoresConAuto();
      if (mounted) {
        setState(() {
          _todosUsuarios = usuarios;
          _todosConductores = conductores;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lista exclusiva de miembros del Directorio (superadmin, admin, supervisor, tesorero)
  List<Map<String, dynamic>> get _directorio => _todosUsuarios.where((u) {
        final r = u['rol']?.toString().toLowerCase();
        return r == 'admin' ||
            r == 'superadmin' ||
            r == 'supervisor' ||
            r == 'tesorero';
      }).toList();

  String _etiquetaRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return 'SUPERADMIN';
      case 'admin':
        return 'SEC. GENERAL';
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
          'avatarIcon': const Color(0xFF7E22CE),
          'badgeBg': const Color(0xFFFAF5FF),
          'badgeText': const Color(0xFF7E22CE),
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
          'avatarBg': _kMintBg,
          'avatarIcon': _kVerdeOscuro,
          'badgeBg': const Color(0xFFF0FDFA),
          'badgeText': _kVerdeOscuro,
        };
      case 'admin':
      default:
        return {
          'avatarBg': const Color(0xFFDBEAFE),
          'avatarIcon': const Color(0xFF1E40AF),
          'badgeBg': const Color(0xFFEFF6FF),
          'badgeText': const Color(0xFF1E40AF),
        };
    }
  }

  // ===========================================================================
  // MODAL: DESIGNAR CONDUCTOR EXISTENTE AL DIRECTORIO
  // ===========================================================================
  void _mostrarModalDesignarConductor({Map<String, dynamic>? usuarioExistente}) {
    final esEdicion = usuarioExistente != null;
    final idUsuario = usuarioExistente?['id_usuario']?.toString();

    // Si es edición, preseleccionamos el rol actual
    String rolSeleccionado = usuarioExistente?['rol']?.toString() ?? 'tesorero';
    if (rolSeleccionado == 'conductor') rolSeleccionado = 'tesorero';

    // Conductor seleccionado (en modo nuevo o al editar)
    Map<String, dynamic>? conductorSeleccionado;
    if (esEdicion) {
      final idCond = usuarioExistente['id_conductor']?.toString();
      conductorSeleccionado = _todosConductores.firstWhere(
        (c) =>
            c['id_conductor']?.toString() == idCond ||
            c['id_usuario']?.toString() == idUsuario,
        orElse: () => usuarioExistente,
      );
    }

    final correoCtrl = TextEditingController(
      text: usuarioExistente?['gmail']?.toString() ?? '',
    );
    final passCtrl = TextEditingController();
    bool obscurePass = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Píldora superior
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),

                // Cabecera del modal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: _kMintBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.badge_rounded,
                              color: _kVerdeOscuro,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                esEdicion
                                    ? 'Modificar Cargo Directivo'
                                    : 'Designar al Directorio',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                esEdicion
                                    ? 'Actualiza el cargo y permisos del miembro'
                                    : 'Elige un conductor activo para asignarle cargo',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),

                // Contenido desplazable
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                    children: [
                      // PASO 1: SELECCIONAR CONDUCTOR
                      const Text(
                        '1. Conductor Sindical',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _kVerdeOscuro,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!esEdicion) ...[
                        InkWell(
                          onTap: () async {
                            final elegido = await _abrirSelectorConductor();
                            if (elegido != null) {
                              setSheetState(() {
                                conductorSeleccionado = elegido;
                                if (correoCtrl.text.isEmpty &&
                                    elegido['gmail'] != null) {
                                  correoCtrl.text =
                                      elegido['gmail'].toString();
                                }
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: conductorSeleccionado == null
                                  ? const Color(0xFFF8FAFC)
                                  : _kMintBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: conductorSeleccionado == null
                                    ? const Color(0xFFE2E8F0)
                                    : _kVerdeOscuro,
                                width: conductorSeleccionado == null ? 1 : 1.5,
                              ),
                            ),
                            child: conductorSeleccionado == null
                                ? const Row(
                                    children: [
                                      Icon(
                                        Icons.person_search_rounded,
                                        color: _kVerdeOscuro,
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Toca para seleccionar un conductor de la flota...',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      AvatarConductor(
                                        foto: conductorSeleccionado!['foto']
                                            ?.toString(),
                                        nombre:
                                            conductorSeleccionado!['nombre']
                                                    ?.toString() ??
                                                '',
                                        radio: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              conductorSeleccionado!['nombre']
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              'Auto: ${conductorSeleccionado!['numero_interno'] ?? conductorSeleccionado!['placa'] ?? 'S/N'} • CI: ${conductorSeleccionado!['ci'] ?? 'S/CI'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: _kVerdeOscuro),
                                        ),
                                        child: const Text(
                                          'Cambiar',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _kVerdeOscuro,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ] else ...[
                        // En modo edición mostramos el miembro actual
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              AvatarConductor(
                                foto: conductorSeleccionado?['foto']?.toString(),
                                nombre: conductorSeleccionado?['nombre']
                                        ?.toString() ??
                                    '',
                                radio: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  conductorSeleccionado?['nombre']
                                          ?.toString() ??
                                      'Miembro del Directorio',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // PASO 2: ASIGNAR CARGO / ROL EN EL DIRECTORIO
                      const Text(
                        '2. Cargo y Funciones en el Directorio',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _kVerdeOscuro,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildOpcionRol(
                        rol: 'tesorero',
                        titulo: 'Secretario de Hacienda (Tesorero)',
                        subtitulo:
                            'Control económico, recaudación de cuotas, balances y caja del día.',
                        icono: Icons.payments_rounded,
                        color: _kVerdeOscuro,
                        seleccionado: rolSeleccionado == 'tesorero',
                        onTap: () =>
                            setSheetState(() => rolSeleccionado = 'tesorero'),
                      ),
                      const SizedBox(height: 10),

                      _buildOpcionRol(
                        rol: 'supervisor',
                        titulo: 'Supervisor de Control y Ruta',
                        subtitulo:
                            'Control de salidas, fiscalización de vueltas, asistencia y multas.',
                        icono: Icons.verified_user_rounded,
                        color: const Color(0xFFD97706),
                        seleccionado: rolSeleccionado == 'supervisor',
                        onTap: () =>
                            setSheetState(() => rolSeleccionado = 'supervisor'),
                      ),
                      const SizedBox(height: 10),

                      _buildOpcionRol(
                        rol: 'admin',
                        titulo: 'Secretario General (Administrador)',
                        subtitulo:
                            'Representación del sindicato, altas de choferes y administración general.',
                        icono: Icons.shield_rounded,
                        color: const Color(0xFF1E40AF),
                        seleccionado: rolSeleccionado == 'admin',
                        onTap: () =>
                            setSheetState(() => rolSeleccionado = 'admin'),
                      ),

                      const SizedBox(height: 18),

                      // PASO 3: CREDENCIALES DE ACCESO
                      Row(
                        children: [
                          const Text(
                            '3. Credenciales de Acceso ',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _kVerdeOscuro,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Opcional',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conductorSeleccionado == null
                            ? 'El conductor ya está vinculado. Podrá ingresar con su CI y su contraseña de siempre.'
                            : '✓ ${conductorSeleccionado!['nombre']} ya puede ingresar con su CI (${conductorSeleccionado!['ci'] ?? 'S/CI'}). Solo llena esto si quieres cambiarle la contraseña o registrarle un correo.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico (opcional)',
                          hintText: 'ej. directiva@continental.com',
                          prefixIcon: const Icon(Icons.email_outlined,
                              size: 20, color: _kVerdeOscuro),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: passCtrl,
                        obscureText: obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña (opcional)',
                          hintText: 'Dejar en blanco para conservar su contraseña actual',
                          prefixIcon: const Icon(Icons.lock_outline,
                              size: 20, color: _kVerdeOscuro),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setSheetState(
                                () => obscurePass = !obscurePass),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BOTÓN GUARDAR DESIGNACIÓN
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kVerdeOscuro,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: () async {
                            if (conductorSeleccionado == null) {
                              AppSnackBar.error(context,
                                  'Por favor selecciona primero al conductor.');
                              return;
                            }

                            final idUsuarioFinal =
                                conductorSeleccionado!['id_usuario']
                                        ?.toString() ??
                                    idUsuario;

                            if (idUsuarioFinal == null ||
                                idUsuarioFinal.isEmpty) {
                              AppSnackBar.error(context,
                                  'No se pudo vincular la cuenta del conductor.');
                              return;
                            }

                            final correo = correoCtrl.text.trim();
                            final pass = passCtrl.text.trim();

                            try {
                              await DatabaseHelper.instance
                                  .designarConductorDirectorio(
                                idUsuario: idUsuarioFinal,
                                nuevoRol: rolSeleccionado,
                                gmail: correo.isNotEmpty ? correo : null,
                                password: pass.isNotEmpty ? pass : null,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                _cargarDatos();
                                AppSnackBar.exito(
                                  context,
                                  '¡${conductorSeleccionado!['nombre']} ha sido designado como ${_etiquetaRol(rolSeleccionado)} exitosamente!',
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                AppSnackBar.error(context,
                                    'Error al designar en el Directorio: $e');
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                esEdicion
                                    ? 'Actualizar Cargo Directivo'
                                    : 'Designar y Otorgar Permisos',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SELECTOR RÁPIDO DE CONDUCTORES DISPONIBLES
  // ===========================================================================
  Future<Map<String, dynamic>?> _abrirSelectorConductor() async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final lista = _todosConductores.where((c) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              final nom = (c['nombre'] ?? '').toString().toLowerCase();
              final ci = (c['ci'] ?? '').toString().toLowerCase();
              final auto = (c['numero_interno'] ?? '').toString();
              return nom.contains(q) || ci.contains(q) || auto.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Elegir Conductor de la Flota',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, CI o número de auto...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: _kVerdeOscuro),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onChanged: (val) => setModalState(() => query = val),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: lista.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = lista[i];
                        final nombre = c['nombre']?.toString() ?? 'Conductor';
                        final ci = c['ci']?.toString() ?? '';
                        final auto = c['numero_interno'] ?? c['placa'] ?? 'S/N';
                        final foto = c['foto']?.toString();

                        return InkWell(
                          onTap: () => Navigator.pop(ctx, c),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                AvatarConductor(
                                  foto: foto,
                                  nombre: nombre,
                                  radio: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Auto N° $auto • CI: $ci',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: _kVerdeOscuro,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // RELEVAR DE DIRECTORIO (CONSERVA ÍNTEGRO AL CONDUCTOR)
  // ===========================================================================
  void _confirmarRelevo(Map<String, dynamic> usuario) {
    final idUsuario = usuario['id_usuario']?.toString();
    final nombre = usuario['nombre'] ?? 'este miembro';
    final rolActual = usuario['rol']?.toString() ?? 'admin';

    if (idUsuario == null) return;

    if (rolActual == 'superadmin') {
      AppSnackBar.error(
        context,
        'La cuenta de Super Administrador principal no puede ser relevada.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_alt_rounded,
                  color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Relevo de Cargo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas relevar a "$nombre" de su cargo directivo (${_etiquetaRol(rolActual)})?\n\n'
          'Su cuenta volverá a tener el rol de Conductor de base. '
          'Todos sus datos de vehículo, asistencias, pagos e historial permanecerán 100% intactos.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeOscuro,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final eraConductor = await DatabaseHelper.instance
                    .relevarDeDirectorio(idUsuario);
                _cargarDatos();
                if (mounted) {
                  AppSnackBar.exito(
                    context,
                    eraConductor
                        ? 'Se relevó a "$nombre". Continúa como conductor activo en la flota.'
                        : 'Miembro "$nombre" retirado del Directorio.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppSnackBar.error(context, 'Error al relevar miembro: $e');
                }
              }
            },
            child: const Text(
              'Relevar del Directorio',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FICHA DE DETALLES Y PERMISOS DEL MIEMBRO
  // ===========================================================================
  void _mostrarFichaDetalle(Map<String, dynamic> u) {
    final nombre = u['nombre'] ?? 'Sin nombre';
    final rol = u['rol']?.toString() ?? 'admin';
    final correo = u['gmail'] ?? 'Sin correo registrado';
    final ci = u['ci'] ?? 'S/CI';
    final auto = u['numero_interno'] ?? u['placa'] ?? 'Sin auto asignado';
    final foto = u['foto']?.toString();
    final estilo = _estilosRol(rol);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarConductor(
                  foto: foto,
                  nombre: nombre,
                  radio: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: estilo['badgeBg'],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: estilo['avatarIcon']!.withOpacity(0.3)),
                        ),
                        child: Text(
                          _etiquetaRol(rol),
                          style: TextStyle(
                            color: estilo['badgeText'],
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFilaInfo(Icons.badge_outlined, 'Carnet de Identidad', ci),
            _buildFilaInfo(Icons.directions_car_outlined, 'Vehículo asignado', 'Auto N° $auto'),
            _buildFilaInfo(Icons.email_outlined, 'Correo de acceso', correo),
            _buildFilaInfo(
              Icons.check_circle_outline,
              'Estado sindical',
              u['estado'] == 'activo' ? 'Habilitado' : 'Inactivo',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar Ficha',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaInfo(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CONSTRUCCIÓN PRINCIPAL (UI EXCLUSIVA DE DIRECTORIO CORPORATIVO)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final cantDirectorio = _directorio.length;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. ENCABEZADO CURVO VERDE CORPORATIVO ADAPTADO
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _kVerdeOscuro,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Volver',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            tooltip: 'Recargar',
                            onPressed: _cargarDatos,
                          ),
                          const SizedBox(width: 8),
                          // Usuario activo en Squircle Blanco
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Tooltip(
                              message: SesionService.instance.nombre ??
                                  'Usuario actual',
                              child: const Icon(
                                Icons.person_rounded,
                                color: _kVerdeOscuro,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Directorio ($cantDirectorio)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Mesa directiva y supervisores del sindicato',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. BUSCADOR SUPERIOR MODERNO
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar miembro por nombre o cargo...',
                  hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _kVerdeOscuro),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Color(0xFF64748B)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _busqueda = '');
                            _cargarDatos();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() => _busqueda = val);
                  _cargarDatos();
                },
              ),
            ),
          ),

          // 3. LISTA DIRECTA DEL DIRECTORIO
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : _buildListaDirectorio(_directorio),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kVerdeOscuro,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Designar Conductor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _mostrarModalDesignarConductor(),
      ),
    );
  }

  // ===========================================================================
  // LISTA DIRECTORIO: GRID DE TARJETAS MODULARES
  // ===========================================================================
  Widget _buildListaDirectorio(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      return _buildVacio(
        icon: Icons.groups_rounded,
        titulo: 'No hay miembros del directorio registrados',
        subtitulo:
            'Presiona "+ Designar Conductor" para elegir un chofer de la flota y asignarle un cargo directivo.',
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
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, index) {
        final d = lista[index];
        final nombre = d['nombre'] ?? 'Sin nombre';
        final correo = d['gmail'] ?? 'Sin correo';
        final rol = d['rol']?.toString() ?? 'admin';
        final auto = d['numero_interno'] ?? d['placa'];
        final foto = d['foto']?.toString();
        final estado = d['estado']?.toString() ?? 'activo';
        final esActivo = estado == 'activo';
        final estilo = _estilosRol(rol);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Avatar + Badge de Rol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AvatarConductor(
                    foto: foto,
                    nombre: nombre,
                    radio: 20,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: estilo['badgeBg'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: estilo['avatarIcon']!.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      _etiquetaRol(rol),
                      style: TextStyle(
                        color: estilo['badgeText'],
                        fontWeight: FontWeight.w800,
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
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Si es conductor: Auto asignado
              if (auto != null) ...[
                Row(
                  children: [
                    const Icon(Icons.directions_car_rounded,
                        size: 13, color: _kVerdeOscuro),
                    const SizedBox(width: 4),
                    Text(
                      'Auto N° $auto',
                      style: const TextStyle(
                        color: _kVerdeOscuro,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],

              // Correo o CI
              Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      correo,
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Estado
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: esActivo
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    esActivo ? 'Habilitado' : 'Inactivo',
                    style: TextStyle(
                      color: esActivo
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Botones de acción inferiores
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Ver información (ojito)
                  InkWell(
                    onTap: () => _mostrarFichaDetalle(d),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.visibility_outlined,
                          size: 15, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Editar cargo
                  InkWell(
                    onTap: () =>
                        _mostrarModalDesignarConductor(usuarioExistente: d),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _kMintBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 15, color: _kVerdeOscuro),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Relevar del Directorio
                  InkWell(
                    onTap: () => _confirmarRelevo(d),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sync_alt_rounded,
                          size: 15, color: Color(0xFFEF4444)),
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

  Widget _buildOpcionRol({
    required String rol,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado ? _kMintBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? _kVerdeOscuro : const Color(0xFFE2E8F0),
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: seleccionado ? _kVerdeOscuro : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: seleccionado ? _kVerdeOscuro : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
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
                color: Color(0xFF0F172A),
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
