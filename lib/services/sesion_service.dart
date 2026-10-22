import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import '../screens/login_screen.dart';
import 'database_helper.dart';

/// Servicio Singleton para la gestión y persistencia de la sesión de usuario.
///
/// Guarda en memoria y en SharedPreferences los datos esenciales del usuario autenticado:
/// - [idUsuario]
/// - [rol] ('superadmin', 'admin', 'supervisor', 'conductor')
/// - [nombre]
/// - [idConductor] (si el rol es conductor, obtenido de la tabla 'conductor')
class SesionService {
  SesionService._internal();
  static final SesionService instance = SesionService._internal();

  // Claves de SharedPreferences
  static const _kSesionActiva = 'sesion_activa';
  static const _kIdUsuario = 'sesion_id_usuario';
  static const _kRol = 'sesion_rol';
  static const _kNombre = 'sesion_nombre';
  static const _kGmail = 'sesion_gmail';
  static const _kIdConductor = 'sesion_id_conductor';
  static const _kCi = 'sesion_ci';

  // Datos en memoria de la sesión activa
  String? _idUsuario;
  String? _rol;
  String? _nombre;
  String? _gmail;
  String? _idConductor;
  String? _ci;

  // Getters públicos
  String? get idUsuario => _idUsuario;
  String? get rol => _rol;
  String? get nombre => _nombre;
  String? get gmail => _gmail;
  String? get idConductor => _idConductor;
  String? get ci => _ci;

  bool get estaAutenticado => _idUsuario != null;
  bool get esSuperadmin => _rol == 'superadmin';
  bool get esAdmin => _rol == 'admin';
  bool get esSupervisor => _rol == 'supervisor';
  bool get esConductor => _rol == 'conductor';
  bool get esTesorero => _rol == 'tesorero';

  /// Guarda la sesión del usuario al iniciar sesión exitosamente.
  Future<void> iniciarSesion(Map<String, dynamic> usuarioMap) async {
    _idUsuario = usuarioMap['id_usuario']?.toString();
    _rol = usuarioMap['rol']?.toString();
    _nombre = usuarioMap['nombre']?.toString();
    _gmail = usuarioMap['gmail']?.toString();
    _idConductor = null;
    _ci = null;

    // Si el rol es conductor, obtenemos su ficha de conductor asociada
    if (_rol == 'conductor' && _idUsuario != null) {
      final conductor = await DatabaseHelper.instance.conductorDeUsuario(_idUsuario!);
      if (conductor != null) {
        _idConductor = conductor['id_conductor']?.toString();
        _ci = conductor['ci']?.toString();
      }
    }

    // Mantenemos sincronizado el modelo Usuario existente
    Usuario.currentUser = Usuario.fromMap({
      ...usuarioMap,
      'ci': _ci,
      'id_conductor': _idConductor,
    });

    // Persistir en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSesionActiva, true);
    await prefs.setString(_kIdUsuario, _idUsuario ?? '');
    await prefs.setString(_kRol, _rol ?? '');
    await prefs.setString(_kNombre, _nombre ?? '');
    await prefs.setString(_kGmail, _gmail ?? '');
    await prefs.setString(_kIdConductor, _idConductor ?? '');
    await prefs.setString(_kCi, _ci ?? '');
  }

  /// Carga la sesión persistida desde SharedPreferences al abrir la app.
  /// Valida en la base de datos local SQLite que la cuenta siga existiendo y activa.
  /// Devuelve true si la sesión es válida y se restauró; false en caso contrario.
  Future<bool> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final tieneSesion = prefs.getBool(_kSesionActiva) ?? false;

    if (!tieneSesion) return false;

    final id = prefs.getString(_kIdUsuario);
    if (id == null || id.isEmpty) return false;

    // Verificar en SQLite si la cuenta aún existe y está activa
    final usuario = await DatabaseHelper.instance.obtener('usuario', id);
    if (usuario == null || usuario['estado'] != 'activo') {
      await cerrarSesion();
      return false;
    }

    // Restaurar datos en memoria
    _idUsuario = usuario['id_usuario']?.toString();
    _rol = usuario['rol']?.toString();
    _nombre = usuario['nombre']?.toString();
    _gmail = usuario['gmail']?.toString();
    _idConductor = null;
    _ci = null;

    if (_rol == 'conductor' && _idUsuario != null) {
      final conductor = await DatabaseHelper.instance.conductorDeUsuario(_idUsuario!);
      if (conductor != null) {
        _idConductor = conductor['id_conductor']?.toString();
        _ci = conductor['ci']?.toString();
      }
    }

    // Sincronizar modelo global
    Usuario.currentUser = Usuario.fromMap({
      ...usuario,
      'ci': _ci,
      'id_conductor': _idConductor,
    });

    return true;
  }

  /// Cierra la sesión activa, borra la persistencia y opcionalmente redirige al login.
  Future<void> cerrarSesion([BuildContext? context]) async {
    _idUsuario = null;
    _rol = null;
    _nombre = null;
    _gmail = null;
    _idConductor = null;
    _ci = null;
    Usuario.currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context != null && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
