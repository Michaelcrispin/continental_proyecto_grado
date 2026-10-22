import 'package:flutter/material.dart';
import '../core/documentos_alerta.dart';
import '../services/database_helper.dart';

class ConductorFormScreen extends StatefulWidget {
  final Map<String, dynamic>? conductor;

  const ConductorFormScreen({super.key, this.conductor});

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

  // Controladores - Vehículo (Trufi)
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
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SELECTOR DE FECHAS
  // ---------------------------------------------------------------------------
  Future<void> _seleccionarFecha({
    required BuildContext context,
    required TextEditingController controller,
    required String titulo,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    DateTime inicial = initialDate ?? DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        inicial = DateTime.parse(controller.text.trim());
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: firstDate ?? DateTime(1940),
      lastDate: lastDate ?? DateTime(2045),
      helpText: titulo.toUpperCase(),
      confirmText: 'ACEPTAR',
      cancelText: 'CANCELAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final str =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        controller.text = str;
      });
    }
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

    try {
      if (_esEdicion && _idUsuario != null) {
        await DatabaseHelper.instance.actualizarUsuarioCompleto(
          idUsuario: _idUsuario!,
          nombre: nombre,
          gmail: correo.isEmpty ? null : correo,
          rol: 'conductor',
          estado: estado,
          ci: ci,
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
            // 1. HEADER BANNER AZUL MARINO ELEGANTE
            _buildHeader(titulo, subtitulo),

            // 2. FORMULARIO SCROLLABLE CON TARJETAS
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
                      _buildCardSeccion(
                        icono: Icons.lock_person_outlined,
                        colorIcono: const Color(0xFF2563EB),
                        bgIcono: const Color(0xFFEFF6FF),
                        titulo: 'Cuenta y Acceso al Sistema',
                        subtitulo:
                            'Credenciales obligatorias para inicio de sesión del chofer',
                        contenido: [
                          _buildTextField(
                            controller: _nombreCtrl,
                            label: 'Nombre Completo *',
                            hint: 'Ej. Juan Carlos Quispe Mamani',
                            icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'El nombre completo es obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildTextField(
                                  controller: _ciCtrl,
                                  label: 'Cédula de Identidad (CI) *',
                                  hint: 'Ej. 8493021 LP',
                                  icon: Icons.badge_outlined,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'El CI es obligatorio (Login)'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 5,
                                child: _buildTextField(
                                  controller: _telefonoCtrl,
                                  label: 'Teléfono / Celular',
                                  hint: '76543210',
                                  icon: Icons.phone_android_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _passCtrl,
                            label: _esEdicion
                                ? 'Nueva Contraseña (dejar en blanco para no cambiar)'
                                : 'Contraseña de Acceso *',
                            hint: _esEdicion
                                ? 'Sin cambios'
                                : 'Mínimo 4 caracteres',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePass,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _correoCtrl,
                            label: 'Correo Electrónico (Opcional)',
                            hint: 'ejemplo@gmail.com',
                            icon: Icons.alternate_email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECCIÓN 2: INFORMACIÓN PERSONAL
                      _buildCardSeccion(
                        icono: Icons.home_work_outlined,
                        colorIcono: const Color(0xFF0D9488),
                        bgIcono: const Color(0xFFCCFBF1),
                        titulo: 'Información Personal',
                        subtitulo:
                            'Datos domiciliarios y personales del conductor',
                        contenido: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  controller: _fechaNacimientoCtrl,
                                  label: 'Fecha de Nacimiento',
                                  hint: 'AAAA-MM-DD',
                                  tituloPicker: 'Fecha de Nacimiento',
                                  firstDate: DateTime(1940),
                                  lastDate: DateTime.now(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdownField<String>(
                                  label: 'Estado Civil',
                                  value: _estadoCivil,
                                  items: _estadosCiviles,
                                  icon: Icons.family_restroom_outlined,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _estadoCivil = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _direccionCtrl,
                            label: 'Dirección de Domicilio',
                            hint:
                                'Ej. Av. 6 de Marzo, Zona Villa Adela, N° 450',
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECCIÓN 3: LICENCIA DE CONDUCIR
                      _buildCardSeccion(
                        icono: Icons.drive_eta_outlined,
                        colorIcono: const Color(0xFFF59E0B),
                        bgIcono: const Color(0xFFFEF3C7),
                        titulo: 'Licencia de Conducir',
                        subtitulo:
                            'Número, categoría profesional y vigencia para control',
                        contenido: [
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildTextField(
                                  controller: _licenciaCtrl,
                                  label: 'N° de Licencia',
                                  hint: 'Ej. 8493021 (Opcional, usa CI)',
                                  icon: Icons.credit_card_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 6,
                                child: _buildDropdownField<String>(
                                  label: 'Categoría',
                                  value: _licenciaCategoria,
                                  items: _categoriasLicencia,
                                  icon: Icons.card_membership_outlined,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _licenciaCategoria = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  controller: _licenciaEmisionCtrl,
                                  label: 'Fecha de Emisión',
                                  hint: 'AAAA-MM-DD',
                                  tituloPicker: 'Emisión de Licencia',
                                  firstDate: DateTime(1980),
                                  lastDate: DateTime.now(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDateField(
                                      controller: _licenciaVenceCtrl,
                                      label: 'Fecha de Vencimiento',
                                      hint: 'AAAA-MM-DD',
                                      tituloPicker: 'Vencimiento de Licencia',
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2045),
                                    ),
                                    _buildBadgeVigencia(
                                      _licenciaVenceCtrl.text,
                                      docNombre: 'Licencia',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECCIÓN 4: VEHÍCULO ASIGNADO (TRUFI)
                      _buildCardSeccion(
                        icono: Icons.directions_bus_outlined,
                        colorIcono: const Color(0xFF10B981),
                        bgIcono: const Color(0xFFECFDF5),
                        titulo: 'Unidad de Transporte (Trufi)',
                        subtitulo: 'Datos del vehículo asignado, SOAT y RUAT',
                        contenido: [
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildTextField(
                                  controller: _placaCtrl,
                                  label: 'Placa del Vehículo',
                                  hint: 'Ej. 2849-ABC',
                                  icon: Icons.directions_car_outlined,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 5,
                                child: _buildTextField(
                                  controller: _ruatCtrl,
                                  label: 'N° de RUAT',
                                  hint: 'Ej. 859302',
                                  icon: Icons.description_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _marcaCtrl,
                                  label: 'Marca',
                                  hint: 'Toyota',
                                  icon: Icons.branding_watermark_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  controller: _modeloCtrl,
                                  label: 'Modelo',
                                  hint: 'Hiace',
                                  icon: Icons.airport_shuttle_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildTextField(
                                  controller: _colorCtrl,
                                  label: 'Color de la Unidad',
                                  hint: 'Blanco / Azul',
                                  icon: Icons.palette_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: _buildTextField(
                                  controller: _capacidadCtrl,
                                  label: 'Capacidad',
                                  hint: '14 pax',
                                  icon: Icons
                                      .airline_seat_recline_normal_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _soatCtrl,
                                  label: 'N° de Póliza SOAT',
                                  hint: 'Ej. SOAT-2026-948',
                                  icon: Icons.security_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDateField(
                                      controller: _soatVenceCtrl,
                                      label: 'Vencimiento SOAT',
                                      hint: 'AAAA-MM-DD',
                                      tituloPicker: 'Vencimiento de SOAT',
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    ),
                                    _buildBadgeVigencia(
                                      _soatVenceCtrl.text,
                                      docNombre: 'SOAT',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECCIÓN 5: ESTADO OPERATIVO
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _estadoActivo
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFECACA),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _estadoActivo
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _estadoActivo
                                    ? Icons.check_circle_outline
                                    : Icons.block_outlined,
                                color: _estadoActivo
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _estadoActivo
                                        ? 'Estado: HABILITADO'
                                        : 'Estado: INHABILITADO',
                                    style: TextStyle(
                                      color: _estadoActivo
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _estadoActivo
                                        ? 'El conductor puede iniciar sesión, marcar asistencias y ser despachado.'
                                        : 'Conductor bloqueado operativamente en el sistema.',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _estadoActivo,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) =>
                                  setState(() => _estadoActivo = val),
                            ),
                          ],
                        ),
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
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 7,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _guardarConductor,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _esEdicion
                                  ? 'Guardar Cambios'
                                  : 'Registrar Conductor',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER BANNER AZUL MARINO
  // ---------------------------------------------------------------------------
  Widget _buildHeader(String titulo, String subtitulo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F265C), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Volver',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/logo.png',
                height: 34,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.directions_bus, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECCIÓN EN TARJETA BLANCA CON ÍCONO
  // ---------------------------------------------------------------------------
  Widget _buildCardSeccion({
    required IconData icono,
    required Color colorIcono,
    required Color bgIcono,
    required String titulo,
    required String subtitulo,
    required List<Widget> contenido,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgIcono,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: colorIcono, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          ...contenido,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT DE TEXTO GENERAL
  // ---------------------------------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 19),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT DE FECHA CON DATE PICKER
  // ---------------------------------------------------------------------------
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String tituloPicker,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return InkWell(
      onTap: () => _seleccionarFecha(
        context: context,
        controller: controller,
        titulo: tituloPicker,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
      borderRadius: BorderRadius.circular(14),
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            prefixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF64748B),
              size: 18,
            ),
            suffixIcon: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF64748B),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF10B981),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DROPDOWN PERSONALIZADO
  // ---------------------------------------------------------------------------
  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            item.toString(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ---------------------------------------------------------------------------
  // BADGE DE VIGENCIA EN TIEMPO REAL
  // ---------------------------------------------------------------------------
  Widget _buildBadgeVigencia(String fechaIso, {required String docNombre}) {
    if (fechaIso.trim().isEmpty) return const SizedBox.shrink();
    final estado = DocumentosAlerta.estado(fechaIso);
    final dias = DocumentosAlerta.diasRestantes(fechaIso);
    final color = DocumentosAlerta.color(estado);
    final bg = DocumentosAlerta.colorFondo(estado);

    String mensaje = estado;
    if (dias != null) {
      if (dias < 0) {
        mensaje = 'Vencida hace ${-dias} días';
      } else if (dias == 0) {
        mensaje = 'Vence hoy';
      } else if (dias <= 30) {
        mensaje = 'Vence pronto en $dias días';
      } else {
        mensaje = 'Vigente ($dias días restantes)';
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estado == 'Vencida'
                ? Icons.cancel_outlined
                : (estado == 'Por vencer'
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline),
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$docNombre: $mensaje',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
