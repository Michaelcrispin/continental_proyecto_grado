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

  // Controladores - Cuenta y Acceso
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ciCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _correoCtrl;

  // Asignación Sindical y Padrón
  String _grupo = '101';
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
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _capacidadCtrl;
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
    _marcaCtrl = TextEditingController(
      text: c?['marca']?.toString() ?? 'Toyota',
    );
    _modeloCtrl = TextEditingController(
      text: c?['modelo']?.toString() ?? 'Hiace',
    );
    _colorCtrl = TextEditingController(
      text: c?['color']?.toString() ?? 'Blanco / Azul',
    );
    _capacidadCtrl = TextEditingController(
      text: c?['capacidad'] != null ? c!['capacidad'].toString() : '14',
    );
    _soatCtrl = TextEditingController(text: c?['soat']?.toString() ?? '');
    _soatVenceCtrl = TextEditingController(
      text: c?['fecha_vencimiento_soat']?.toString() ?? '',
    );
    _ruatCtrl = TextEditingController(text: c?['ruat']?.toString() ?? '');

    // Estado operativo
    final est = c?['estado']?.toString() ?? 'activo';
    _estadoActivo = est.toLowerCase() == 'activo';
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
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _colorCtrl.dispose();
    _capacidadCtrl.dispose();
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor completa los campos obligatorios marcados con *',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final nombre = _nombreCtrl.text.trim();
    final ci = _ciCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (!_esEdicion && pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes asignar una contraseña para el acceso del conductor',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

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
    final marca = _marcaCtrl.text.trim();
    final modelo = _modeloCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final capacidad = int.tryParse(_capacidadCtrl.text.trim()) ?? 14;
    final soat = _soatCtrl.text.trim();
    final soatVence = _soatVenceCtrl.text.trim();
    final ruat = _ruatCtrl.text.trim();
    final estado = _estadoActivo ? 'activo' : 'inactivo';
    final numeroInterno = int.tryParse(_numeroInternoCtrl.text.trim());

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
          marca: marca.isEmpty ? null : marca,
          modelo: modelo.isEmpty ? null : modelo,
          color: color.isEmpty ? null : color,
          capacidad: capacidad,
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
          marca: marca.isEmpty ? null : marca,
          modelo: modelo.isEmpty ? null : modelo,
          color: color.isEmpty ? null : color,
          capacidad: capacidad,
          soat: soat.isEmpty ? null : soat,
          fechaVencimientoSoat: soatVence.isEmpty ? null : soatVence,
          ruat: ruat.isEmpty ? null : ruat,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
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
    final titulo = _esEdicion ? 'Editar Conductor' : 'Nuevo Conductor';
    final subtitulo = _esEdicion
        ? 'Actualizar datos de padrón, documentos y unidad'
        : 'Registro de chofer, credenciales, licencia y vehículo';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. HEADER BANNER AZUL MARINO
            FormHeaderBanner(
              titulo: titulo,
              subtitulo: subtitulo,
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
                      // SECCIÓN 1: ASIGNACIÓN SINDICAL Y GRUPO
                      SeccionPadronSindical(
                        grupo: _grupo,
                        numeroInternoCtrl: _numeroInternoCtrl,
                        onGrupoChanged: (val) => setState(() => _grupo = val),
                      ),
                      const SizedBox(height: 16),

                      // SECCIÓN 2: DATOS DE CUENTA Y ACCESO
                      SeccionCuentaAcceso(
                        nombreCtrl: _nombreCtrl,
                        ciCtrl: _ciCtrl,
                        extensionCi: _extensionCi,
                        telefonoCtrl: _telefonoCtrl,
                        correoCtrl: _correoCtrl,
                        passCtrl: _passCtrl,
                        esEdicion: _esEdicion,
                        obscurePass: _obscurePass,
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
                        marcaCtrl: _marcaCtrl,
                        modeloCtrl: _modeloCtrl,
                        colorCtrl: _colorCtrl,
                        capacidadCtrl: _capacidadCtrl,
                        soatCtrl: _soatCtrl,
                        soatVenceCtrl: _soatVenceCtrl,
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
