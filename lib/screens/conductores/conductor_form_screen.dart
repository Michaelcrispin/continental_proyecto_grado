import 'package:flutter/material.dart';
import '../../core/normalizadores.dart';
import '../../services/database_helper.dart';
import 'widgets/form_header_banner.dart';
import 'widgets/form_secciones_identidad.dart';
import 'widgets/form_secciones_operativas.dart';

/// Formulario para crear o editar un conductor del Sindicato Mixto de Transportes Continental.
class ConductorFormScreen extends StatefulWidget {
  final Map<String, dynamic>? conductor;
  final String? grupoInicial;

  const ConductorFormScreen({
    super.key,
    this.conductor,
    this.grupoInicial,
  });

  @override
  State<ConductorFormScreen> createState() => _ConductorFormScreenState();
}

class _ConductorFormScreenState extends State<ConductorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _esEdicion => widget.conductor != null;
  String? get _idUsuario => widget.conductor?['id_usuario']?.toString();
  String? get _idConductor => widget.conductor?['id_conductor']?.toString();

  // Registros existentes para validación en tiempo real de duplicados
  List<Map<String, dynamic>> _conductoresExistentes = [];
  List<Map<String, dynamic>> _usuariosExistentes = [];
  Map<String, String> _erroresDuplicadosDb = {};

  // Controladores - Cuenta y Acceso
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ciCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _correoCtrl;

  // Asignación Sindical y Padrón
  String _grupo = '101-127';
  String _extensionCi = 'LP';
  late final TextEditingController _numeroInternoCtrl;

  // Controladores - Información Personal
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _fechaNacimientoCtrl;
  late final TextEditingController _direccionCtrl;
  String _estadoCivil = 'Soltero(a)';

  // Controladores - Licencia
  late final TextEditingController _licenciaCtrl;
  String _licenciaCategoria = 'Categoría Profesional C';
  late final TextEditingController _licenciaEmisionCtrl;
  late final TextEditingController _licenciaVenceCtrl;

  // Controladores - Vehículo del conductor
  late final TextEditingController _placaCtrl;
  late final TextEditingController _soatCtrl;
  late final TextEditingController _soatVenceCtrl;
  late final TextEditingController _ruatCtrl;

  // Estado operativo y UI
  bool _estadoActivo = true;
  bool _obscurePass = true;
  bool _isSaving = false;

  final List<String> _categoriasLicencia = const [
    'Categoría Profesional C',
    'Categoría Profesional B',
    'Categoría Profesional A',
    'Particular P',
    'Especial E',
  ];

  final List<String> _estadosCiviles = const [
    'Soltero(a)',
    'Casado(a)',
    'Unión libre',
    'Divorciado(a)',
    'Viudo(a)',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.conductor;

    // Cuenta
    _nombreCtrl = TextEditingController(text: c?['nombre']?.toString() ?? '');
    _ciCtrl = TextEditingController(text: c?['ci']?.toString() ?? '');
    _passCtrl = TextEditingController();
    _correoCtrl = TextEditingController(text: c?['gmail']?.toString() ?? '');

    // Padrón Sindical
    _grupo = c?['grupo']?.toString() ?? widget.grupoInicial ?? '101';
    if (!Normalizadores.grupos.contains(_grupo)) _grupo = '101';
    _extensionCi = c?['extension_ci']?.toString() ?? 'LP';
    if (!Normalizadores.departamentosCi.contains(_extensionCi)) _extensionCi = 'LP';
    _numeroInternoCtrl = TextEditingController(
      text: c?['numero_interno']?.toString() ?? '',
    );

    // Personal
    _telefonoCtrl = TextEditingController(
      text: c?['telefono']?.toString() ?? '',
    );
    _fechaNacimientoCtrl = TextEditingController(
      text: c?['fecha_nacimiento']?.toString() ?? '',
    );
    _direccionCtrl = TextEditingController(
      text: c?['direccion']?.toString() ?? '',
    );
    final estCiv = c?['estado_civil']?.toString();
    if (estCiv != null && _estadosCiviles.contains(estCiv)) {
      _estadoCivil = estCiv;
    }

    // Licencia
    _licenciaCtrl = TextEditingController(
      text: c?['licencia']?.toString() ?? '',
    );
    final cat = c?['licencia_categoria']?.toString();
    if (cat != null && _categoriasLicencia.contains(cat)) {
      _licenciaCategoria = cat;
    }
    _licenciaEmisionCtrl = TextEditingController(
      text: c?['licencia_emision']?.toString() ?? '',
    );
    _licenciaVenceCtrl = TextEditingController(
      text: c?['licencia_vencimiento']?.toString() ?? '',
    );

    // Vehículo
    _placaCtrl = TextEditingController(text: c?['placa']?.toString() ?? '');
    _soatCtrl = TextEditingController(text: c?['soat']?.toString() ?? '');
    _soatVenceCtrl = TextEditingController(
      text: c?['fecha_vencimiento_soat']?.toString() ?? '',
    );
    _ruatCtrl = TextEditingController(text: c?['ruat']?.toString() ?? '');

    // Estado operativo
    final est = c?['estado']?.toString() ?? 'activo';
    _estadoActivo = est.toLowerCase() == 'activo';

    _cargarRegistrosParaValidacion();
  }

  Future<void> _cargarRegistrosParaValidacion() async {
    try {
      final conds = await DatabaseHelper.instance.conductoresConAuto();
      final usus = await DatabaseHelper.instance.listar('usuario');
      if (mounted) {
        setState(() {
          _conductoresExistentes = conds;
          _usuariosExistentes = usus;
        });
      }
    } catch (_) {}
  }

  bool _esMismoRegistro(Map<String, dynamic> row) {
    final idCond = row['id_conductor']?.toString();
    final idUsu = row['id_usuario']?.toString();
    if (_idConductor != null && idCond == _idConductor) return true;
    if (_idUsuario != null && idUsu == _idUsuario) return true;
    return false;
  }

  String? _validarNombre(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return 'El nombre completo es obligatorio';
    final partes = val.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (val.length < 5 || partes.length < 2) {
      return 'Ingresa nombre y apellido completos';
    }
    if (RegExp(r'[0-9]').hasMatch(val)) {
      return 'El nombre no debe contener números';
    }
    final norm = Normalizadores.normalizarNombre(val);
    for (final c in _conductoresExistentes) {
      if (_esMismoRegistro(c)) continue;
      final cNom = c['nombre']?.toString() ?? '';
      if (Normalizadores.normalizarNombre(cNom) == norm) {
        return 'El conductor "$cNom" ya está registrado';
      }
    }
    return _erroresDuplicadosDb['nombre'];
  }

  String? _validarCi(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return 'El CI es obligatorio';
    final ciNorm = Normalizadores.normalizarCi(val);
    final soloDigitos = ciNorm.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloDigitos.length < 5 || ciNorm.length > 12) {
      return 'CI inválido (mínimo 5 dígitos)';
    }
    for (final c in _conductoresExistentes) {
      if (_esMismoRegistro(c)) continue;
      final cCi = c['ci']?.toString() ?? '';
      final cCiNorm = (c['ci_normalizado']?.toString().isNotEmpty ?? false)
          ? c['ci_normalizado'].toString()
          : Normalizadores.normalizarCi(cCi);
      if (cCiNorm == ciNorm || cCi.trim().toUpperCase() == val.toUpperCase()) {
        final dueno = c['nombre']?.toString() ?? 'otro conductor';
        return 'Este CI ya pertenece a $dueno';
      }
    }
    return _erroresDuplicadosDb['ci'];
  }

  String? _validarTelefono(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return 'El teléfono/celular es obligatorio';
    final telNorm = Normalizadores.normalizarTelefono(val);
    if (telNorm.length < 7 || telNorm.length > 8) {
      return 'Ingresa un número válido de 7 u 8 dígitos';
    }
    for (final c in _conductoresExistentes) {
      if (_esMismoRegistro(c)) continue;
      final cTelNorm = Normalizadores.normalizarTelefono(
        c['telefono']?.toString(),
      );
      if (cTelNorm.isNotEmpty && cTelNorm == telNorm) {
        final dueno = c['nombre']?.toString() ?? 'otro conductor';
        return 'Este teléfono ya pertenece a $dueno';
      }
    }
    return _erroresDuplicadosDb['telefono'];
  }

  String? _validarCorreo(String? v) {
    final val = (v ?? '').trim().toLowerCase();
    if (val.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(val)) {
      return 'Ingresa un correo electrónico válido';
    }
    for (final u in _usuariosExistentes) {
      final idUsu = u['id_usuario']?.toString();
      if (_idUsuario != null && idUsu == _idUsuario) continue;
      final uGmail = (u['gmail']?.toString() ?? '').trim().toLowerCase();
      if (uGmail.isNotEmpty && uGmail == val) {
        final dueno = u['nombre']?.toString() ?? 'otro usuario';
        return 'Este correo ya pertenece a $dueno';
      }
    }
    return _erroresDuplicadosDb['correo'];
  }

  String? _validarPassword(String? v) {
    final val = (v ?? '').trim();
    if (!_esEdicion && val.isEmpty) {
      return 'La contraseña de acceso es obligatoria';
    }
    if (val.isNotEmpty && val.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }
    return null;
  }

  String? _validarLicencia(String? v) {
    final val = (v ?? '').trim();
    final efectivo = val.isEmpty ? _ciCtrl.text.trim() : val;
    if (efectivo.isEmpty) return null;
    final licNorm = Normalizadores.normalizarCodigo(efectivo);
    if (val.isNotEmpty && licNorm.length < 5) {
      return 'N° de licencia inválido (mín. 5 caracteres)';
    }
    for (final c in _conductoresExistentes) {
      if (_esMismoRegistro(c)) continue;
      final cLicNorm = Normalizadores.normalizarCodigo(
        c['licencia']?.toString(),
      );
      final cCiNorm = Normalizadores.normalizarCi(c['ci']?.toString());
      if ((cLicNorm.isNotEmpty && cLicNorm == licNorm) ||
          (cCiNorm.isNotEmpty && cCiNorm == licNorm)) {
        final dueno = c['nombre']?.toString() ?? 'otro conductor';
        return 'Esta licencia ya pertenece a $dueno';
      }
    }
    return _erroresDuplicadosDb['licencia'];
  }

  String? _validarPlaca(String? v) {
    final val = (v ?? '').trim().toUpperCase();
    if (val.isEmpty) return null;
    final placaNorm = Normalizadores.normalizarPlaca(val);
    if (placaNorm.length < 5 || placaNorm.length > 9) {
      return 'Placa inválida (ej. 1234ABC)';
    }
    for (final c in _conductoresExistentes) {
      if (_esMismoRegistro(c)) continue;
      final cPlacaNorm = Normalizadores.normalizarPlaca(
        c['placa']?.toString(),
      );
      if (cPlacaNorm.isNotEmpty && cPlacaNorm == placaNorm) {
        final dueno = c['nombre']?.toString() ?? 'otro conductor';
        return 'Esta placa ya pertenece a $dueno';
      }
    }
    return _erroresDuplicadosDb['placa'];
  }

  String? _validarRuat(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return null;
    final ruatNorm = Normalizadores.normalizarCodigo(val);
    if (ruatNorm.length < 4) {
      return 'N° de RUAT inválido';
    }
    for (final c in _conductoresExistentes) {
      if (_esMismoRegistro(c)) continue;
      final cRuatNorm = Normalizadores.normalizarCodigo(c['ruat']?.toString());
      if (cRuatNorm.isNotEmpty && cRuatNorm == ruatNorm) {
        final dueno = c['nombre']?.toString() ?? 'otro conductor';
        return 'Este RUAT ya pertenece a $dueno';
      }
    }
    return _erroresDuplicadosDb['ruat'];
  }

  String? _validarSoat(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return null;
    final soatNorm = Normalizadores.normalizarCodigo(val);
    if (soatNorm.length < 4) {
      return 'N° de póliza SOAT inválido';
    }
    for (final c in _conductoresExistentes) {
      if (_esMismoRegistro(c)) continue;
      final cSoatNorm = Normalizadores.normalizarCodigo(c['soat']?.toString());
      if (cSoatNorm.isNotEmpty && cSoatNorm == soatNorm) {
        final dueno = c['nombre']?.toString() ?? 'otro conductor';
        return 'Este SOAT ya pertenece a $dueno';
      }
    }
    return _erroresDuplicadosDb['soat'];
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciCtrl.dispose();
    _passCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _fechaNacimientoCtrl.dispose();
    _direccionCtrl.dispose();
    _licenciaCtrl.dispose();
    _licenciaEmisionCtrl.dispose();
    _licenciaVenceCtrl.dispose();
    _placaCtrl.dispose();
    _soatCtrl.dispose();
    _soatVenceCtrl.dispose();
    _ruatCtrl.dispose();
    _numeroInternoCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // GUARDAR CONDUCTOR (CREAR O ACTUALIZAR)
  // ---------------------------------------------------------------------------
  Future<void> _guardarConductor() async {
    if (_isSaving) return;

    setState(() => _erroresDuplicadosDb = {});

    final nombre = _nombreCtrl.text.trim();
    final ci = _ciCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();
    final nacimiento = _fechaNacimientoCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final licenciaNum = _licenciaCtrl.text.trim().isEmpty
        ? ci
        : _licenciaCtrl.text.trim();
    final licenciaEmision = _licenciaEmisionCtrl.text.trim();
    final licenciaVence = _licenciaVenceCtrl.text.trim();
    final placa = _placaCtrl.text.trim().toUpperCase();
    final soat = _soatCtrl.text.trim();
    final soatVence = _soatVenceCtrl.text.trim();
    final ruat = _ruatCtrl.text.trim();
    final estado = _estadoActivo ? 'activo' : 'inactivo';
    final numeroInterno = int.tryParse(_numeroInternoCtrl.text.trim());

    // Verificar duplicados directamente contra la base de datos antes de validar formulario
    final duplicados = await DatabaseHelper.instance.validarDuplicadosConductor(
      excluirIdUsuario: _idUsuario,
      excluirIdConductor: _idConductor,
      nombre: nombre,
      ci: ci,
      telefono: telefono,
      correo: correo.isEmpty ? null : correo,
      licencia: licenciaNum.isEmpty ? null : licenciaNum,
      placa: placa.isEmpty ? null : placa,
      ruat: ruat.isEmpty ? null : ruat,
      soat: soat.isEmpty ? null : soat,
    );

    if (!mounted) return;

    if (duplicados.isNotEmpty) {
      setState(() => _erroresDuplicadosDb = duplicados);
    }

    if (!_formKey.currentState!.validate() || duplicados.isNotEmpty) {
      final mensajeError = duplicados.isNotEmpty
          ? duplicados.values.first
          : 'Revisa los campos marcados en rojo antes de continuar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_esEdicion && _idUsuario != null) {
        await DatabaseHelper.instance.actualizarUsuarioCompleto(
          idUsuario: _idUsuario!,
          nombre: nombre,
          gmail: correo.isEmpty ? null : correo,
          rol: 'conductor',
          estado: estado,
          ci: ci,
          extensionCi: _extensionCi,
          grupo: _grupo,
          numeroInterno: numeroInterno,
          licencia: licenciaNum.isEmpty ? null : licenciaNum,
          newPassword: pass.isEmpty ? null : pass,
          telefono: telefono.isEmpty ? null : telefono,
          fechaNacimiento: nacimiento.isEmpty ? null : nacimiento,
          direccion: direccion.isEmpty ? null : direccion,
          estadoCivil: _estadoCivil,
          licenciaCategoria: _licenciaCategoria,
          licenciaEmision: licenciaEmision.isEmpty ? null : licenciaEmision,
          licenciaVencimiento: licenciaVence.isEmpty ? null : licenciaVence,
          placa: placa.isEmpty ? null : placa,
          soat: soat.isEmpty ? null : soat,
          fechaVencimientoSoat: soatVence.isEmpty ? null : soatVence,
          ruat: ruat.isEmpty ? null : ruat,
        );
      } else {
        await DatabaseHelper.instance.crearUsuarioCompleto(
          rol: 'conductor',
          nombre: nombre,
          gmail: correo.isEmpty ? null : correo,
          ci: ci,
          extensionCi: _extensionCi,
          grupo: _grupo,
          numeroInterno: numeroInterno,
          password: pass,
          estado: estado,
          licencia: licenciaNum.isEmpty ? null : licenciaNum,
          telefono: telefono.isEmpty ? null : telefono,
          fechaNacimiento: nacimiento.isEmpty ? null : nacimiento,
          direccion: direccion.isEmpty ? null : direccion,
          estadoCivil: _estadoCivil,
          licenciaCategoria: _licenciaCategoria,
          licenciaEmision: licenciaEmision.isEmpty ? null : licenciaEmision,
          licenciaVencimiento: licenciaVence.isEmpty ? null : licenciaVence,
          placa: placa.isEmpty ? null : placa,
          soat: soat.isEmpty ? null : soat,
          fechaVencimientoSoat: soatVence.isEmpty ? null : soatVence,
          ruat: ruat.isEmpty ? null : ruat,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF02634C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _esEdicion
                        ? '¡Conductor "$nombre" actualizado con éxito!'
                        : '¡Conductor "$nombre" registrado en el padrón!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // INTERFAZ DE USUARIO
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final titulo = _esEdicion ? 'Editar Conductor' : 'Registro de Conductores';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. BANNER HEADER CORPORATIVO CONTINENTAL
            FormHeaderBanner(
              titulo: titulo,
              onVolver: () => Navigator.pop(context),
            ),

            // 2. FORMULARIO SCROLLABLE CON TARJETAS MODULARES
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SECCIÓN 1: DATOS DE CUENTA Y ACCESO
                      SeccionCuentaAcceso(
                        nombreCtrl: _nombreCtrl,
                        ciCtrl: _ciCtrl,
                        extensionCi: _extensionCi,
                        telefonoCtrl: _telefonoCtrl,
                        correoCtrl: _correoCtrl,
                        passCtrl: _passCtrl,
                        esEdicion: _esEdicion,
                        obscurePass: _obscurePass,
                        validadorNombre: _validarNombre,
                        validadorCi: _validarCi,
                        validadorTelefono: _validarTelefono,
                        validadorCorreo: _validarCorreo,
                        validadorPass: _validarPassword,
                        onToggleObscure: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        onExtensionChanged: (val) {
                          if (val != null) setState(() => _extensionCi = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // SECCIÓN 3: INFORMACIÓN PERSONAL
                      SeccionInfoPersonal(
                        fechaNacimientoCtrl: _fechaNacimientoCtrl,
                        estadoCivil: _estadoCivil,
                        estadosCiviles: _estadosCiviles,
                        direccionCtrl: _direccionCtrl,
                        onEstadoCivilChanged: (val) {
                          if (val != null) setState(() => _estadoCivil = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // SECCIÓN 4: LICENCIA DE CONDUCIR
                      SeccionLicencia(
                        licenciaCtrl: _licenciaCtrl,
                        licenciaCategoria: _licenciaCategoria,
                        categoriasLicencia: _categoriasLicencia,
                        licenciaEmisionCtrl: _licenciaEmisionCtrl,
                        licenciaVenceCtrl: _licenciaVenceCtrl,
                        validadorLicencia: _validarLicencia,
                        onCategoriaChanged: (val) {
                          if (val != null) {
                            setState(() => _licenciaCategoria = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // SECCIÓN 5: VEHÍCULO DEL CONDUCTOR
                      SeccionVehiculo(
                        placaCtrl: _placaCtrl,
                        ruatCtrl: _ruatCtrl,
                        soatCtrl: _soatCtrl,
                        soatVenceCtrl: _soatVenceCtrl,
                        validadorPlaca: _validarPlaca,
                        validadorRuat: _validarRuat,
                        validadorSoat: _validarSoat,
                      ),
                      const SizedBox(height: 16),

                      // SECCIÓN 6: ESTADO OPERATIVO
                      SeccionEstadoOperativo(
                        estadoActivo: _estadoActivo,
                        onEstadoChanged: (val) =>
                            setState(() => _estadoActivo = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. BARRA INFERIOR DE ACCIONES (CANCELAR Y GUARDAR)
      bottomSheet: FormBarraAcciones(
        esEdicion: _esEdicion,
        isSaving: _isSaving,
        onCancelar: () => Navigator.pop(context),
        onGuardar: _guardarConductor,
      ),
    );
  }
}
