import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/documentos_alerta.dart';
import '../services/database_helper.dart';
import 'gps_screen.dart';
import 'asistencia_screen.dart';
import 'conductor_form_screen.dart';
import '../widgets/avatar_conductor.dart';

class ConductorDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> conductor;

  const ConductorDetalleScreen({super.key, required this.conductor});

  @override
  State<ConductorDetalleScreen> createState() => _ConductorDetalleScreenState();
}

class _ConductorDetalleScreenState extends State<ConductorDetalleScreen> {
  late Map<String, dynamic> _c;
  int _tabSeleccionada =
      0; // 0: Info general, 1: Documentos, 2: Trufi, 3: Asistencias, 4: Observaciones

  List<Map<String, dynamic>> _asistencias = [];
  List<Map<String, dynamic>> _sanciones = [];
  bool _isLoadingDetalles = true;

  @override
  void initState() {
    super.initState();
    _c = Map<String, dynamic>.from(widget.conductor);
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    setState(() => _isLoadingDetalles = true);
    final idConductor = _c['id_conductor']?.toString();
    try {
      if (idConductor != null && idConductor.isNotEmpty) {
        final ficha = await DatabaseHelper.instance.fichaConductor(idConductor);
        final asists = await DatabaseHelper.instance.asistenciasDetalle(
          idConductor: idConductor,
        );
        final sancs = await DatabaseHelper.instance.sancionesDetalle(
          idConductor: idConductor,
        );
        if (mounted) {
          setState(() {
            if (ficha != null) {
              _c = Map<String, dynamic>.from(ficha);
            }
            _asistencias = asists;
            _sanciones = sancs;
            _isLoadingDetalles = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDetalles = false);
  }

  bool _fueModificado = false;

  Future<void> _editarConductor() async {
    final modificado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConductorFormScreen(conductor: _c)),
    );
    if (modificado == true) {
      _fueModificado = true;
      _cargarDetalles();
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    final fotoActual = _c['foto']?.toString();
    final nuevaRuta = await AvatarConductor.mostrarSelectorOrigen(
      context,
      puedeEliminar: fotoActual != null && fotoActual.isNotEmpty,
    );
    if (nuevaRuta == null) return;

    final idConductor = _c['id_conductor']?.toString();
    if (idConductor == null) return;

    try {
      await DatabaseHelper.instance.actualizarFotoConductor(idConductor, nuevaRuta);
      setState(() {
        _c['foto'] = nuevaRuta.isEmpty ? null : nuevaRuta;
        _fueModificado = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  nuevaRuta.isEmpty
                      ? 'Foto de perfil eliminada'
                      : '¡Foto de perfil actualizada con éxito!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error al actualizar foto: $e'),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final nombre = _c['nombre']?.toString() ?? 'Sin nombre';
    final ci = _c['ci']?.toString() ?? 'S/CI';
    final estado = _c['estado']?.toString() ?? 'activo';
    final esActivo = estado.toLowerCase() == 'activo';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. BANNER CABECERA AZUL MARINO CON FOTO Y ACCIONES
              _buildHeaderBanner(nombre, ci, esActivo),

              // 2. SUB-PESTAÑAS DE NAVEGACIÓN
              _buildSubTabs(),

              // 3. CONTENIDO PRINCIPAL SEGÚN PESTAÑA
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: _buildContenidoTab(nombre, ci, esActivo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. BANNER CABECERA
  // ---------------------------------------------------------------------------
  Widget _buildHeaderBanner(String nombre, String ci, bool esActivo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F265C), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Marca de agua sutil de trufi al fondo
          Positioned(
            right: -10,
            bottom: -15,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/trufi_minibus.jpg',
                width: 170,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.directions_bus,
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior: Volver atrás y botón Editar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          tooltip: 'Volver',
                          onPressed: () =>
                              Navigator.pop(context, _fueModificado),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ficha del Conductor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _editarConductor,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Datos del Conductor con Avatar
              Row(
                children: [
                  // Avatar circular dinámico con botón de cámara
                  AvatarConductor(
                    foto: _c['foto']?.toString(),
                    nombre: nombre,
                    radio: 41,
                    mostrarBotonCamara: true,
                    onTap: _cambiarFotoPerfil,
                    onTapCamara: _cambiarFotoPerfil,
                  ),

                  const SizedBox(width: 16),

                  // Nombre, Estado y Código
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: esActivo
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                esActivo ? 'Habilitado' : 'Inhabilitado',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Código: CON-${ci.length > 5 ? ci.substring(0, 5) : ci}',
                              style: const TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SUB-PESTAÑAS
  // ---------------------------------------------------------------------------
  Widget _buildSubTabs() {
    final pestanas = [
      {'icon': Icons.person, 'label': 'Información general'},
      {'icon': Icons.description_outlined, 'label': 'Documentos'},
      {'icon': Icons.directions_bus_outlined, 'label': 'Trufi asignada'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Asistencias'},
      {'icon': Icons.edit_note_outlined, 'label': 'Observaciones'},
    ];
    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pestanas.length,
        itemBuilder: (context, index) {
          final p = pestanas[index];
          final isSelected = _tabSeleccionada == index;

          return GestureDetector(
            onTap: () => setState(() => _tabSeleccionada = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    p['icon'] as IconData,
                    size: 17,
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CONTENIDO PRINCIPAL
  // ---------------------------------------------------------------------------
  Widget _buildContenidoTab(String nombre, String ci, bool esActivo) {
    if (_tabSeleccionada == 1) return _buildTabDocumentos(ci);
    if (_tabSeleccionada == 2) return _buildTabTrufi();
    if (_tabSeleccionada == 3) return _buildTabAsistencias();
    if (_tabSeleccionada == 4) return _buildTabObservaciones();

    final licVence = _c['licencia_vencimiento']?.toString();
    final soatVence = _c['fecha_vencimiento_soat']?.toString();
    final licEstado = DocumentosAlerta.estado(licVence);
    final soatEstado = DocumentosAlerta.estado(soatVence);
    final hayAlerta =
        licEstado == 'Vencida' ||
        licEstado == 'Por vencer' ||
        soatEstado == 'Vencida' ||
        soatEstado == 'Por vencer';
    // Pestaña 0: INFORMACIÓN GENERAL
    return Column(
      children: [
        if (hayAlerta) ...[
          _buildBannerAlertaVencimiento(licEstado, soatEstado),
          const SizedBox(height: 16),
        ],
        // Fila 1: Información Personal & Estado del Conductor
        _buildCardInformacionPersonal(ci, nombre),
        const SizedBox(height: 16),
        _buildCardEstadoConductor(esActivo),
        const SizedBox(height: 16),

        // Fila 2: Información de Licencia & Documentos
        _buildCardInformacionLicencia(ci),
        const SizedBox(height: 16),
        _buildCardDocumentosResumen(),
        const SizedBox(height: 16),

        // Fila 3: Vehículo Asignado (Trufi)
        _buildCardVehiculoAsignado(),
        const SizedBox(height: 16),

        // Fila 4: Actividad Reciente
        _buildCardActividadReciente(),
        const SizedBox(height: 20),

        // Mensaje de consulta
        const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Esta información es oficial de consulta sindical de la ficha del conductor.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBannerAlertaVencimiento(String licEstado, String soatEstado) {
    final esCritico = licEstado == 'Vencida' || soatEstado == 'Vencida';
    final color = esCritico ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final bg = esCritico ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final border = esCritico
        ? const Color(0xFFFECACA)
        : const Color(0xFFFDE68A);

    return InkWell(
      onTap: () => setState(() => _tabSeleccionada = 1),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esCritico
                        ? '¡Alerta de Documento Vencido!'
                        : 'Aviso: Documento por Vencer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esCritico
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF92400E),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Revisa los documentos del conductor. Toca aquí para ver detalles.',
                    style: TextStyle(
                      color: esCritico
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFFB45309),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 1: INFORMACIÓN PERSONAL
  // ---------------------------------------------------------------------------
  Widget _buildCardInformacionPersonal(String ci, String nombre) {
    final telefono = _c['telefono']?.toString();
    final fechaNac = _c['fecha_nacimiento']?.toString();
    final direccion = _c['direccion']?.toString();
    final estadoCivil = _c['estado_civil']?.toString();
    final gmail = _c['gmail']?.toString();

    return _buildContainerCard(
      icon: Icons.person,
      title: 'Información personal',
      subtitle: 'Datos básicos del conductor',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.badge_outlined,
                  label: 'Carnet de identidad',
                  value: ci,
                ),
              ),
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: (telefono != null && telefono.trim().isNotEmpty)
                      ? telefono
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha de nacimiento',
                  value: (fechaNac != null && fechaNac.trim().isNotEmpty)
                      ? fechaNac
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.email_outlined,
                  label: 'Correo electrónico',
                  value: (gmail != null && gmail.trim().isNotEmpty)
                      ? gmail
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  value: (direccion != null && direccion.trim().isNotEmpty)
                      ? direccion
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.person_outline,
                  label: 'Estado civil',
                  value: (estadoCivil != null && estadoCivil.trim().isNotEmpty)
                      ? estadoCivil
                      : 'No registrado',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 2: ESTADO DEL CONDUCTOR
  // ---------------------------------------------------------------------------
  Widget _buildCardEstadoConductor(bool esActivo) {
    final fechaReg =
        _c['fecha_incorporacion']?.toString() ??
        _c['created_at']?.toString() ??
        '10/06/2024';
    final fechaRegCorta = fechaReg.length >= 10
        ? fechaReg.substring(0, 10)
        : fechaReg;

    final fechaAct = _c['updated_at']?.toString() ?? '15/09/2026';
    final fechaActCorta = fechaAct.length >= 10
        ? fechaAct.substring(0, 10)
        : fechaAct;

    return _buildContainerCard(
      icon: Icons.verified_user_outlined,
      title: 'Estado del conductor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: esActivo
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              esActivo ? 'Habilitado' : 'Inhabilitado',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildDatoItem(
            icon: Icons.calendar_today_outlined,
            label: 'Registrado el',
            value: fechaRegCorta,
          ),
          const SizedBox(height: 10),
          _buildDatoItem(
            icon: Icons.access_time,
            label: 'Última actualización',
            value: fechaActCorta,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 3: INFORMACIÓN DE LICENCIA
  // ---------------------------------------------------------------------------
  Widget _buildCardInformacionLicencia(String ci) {
    final numLicencia = _c['licencia']?.toString();
    final fechaVence = _c['licencia_vencimiento']?.toString();
    final fechaEmision = _c['licencia_emision']?.toString();
    final categoria = _c['licencia_categoria']?.toString();
    final estadoLic = DocumentosAlerta.estado(fechaVence);
    final colorLic = DocumentosAlerta.color(estadoLic);

    return _buildContainerCard(
      icon: Icons.badge_outlined,
      title: 'Información de licencia',
      subtitle: 'Datos de la licencia de conducir',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.credit_card_outlined,
                  label: 'Número de licencia',
                  value: (numLicencia != null && numLicencia.trim().isNotEmpty)
                      ? numLicencia
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.event_available_outlined,
                  label: 'Fecha de vencimiento',
                  value: (fechaVence != null && fechaVence.trim().isNotEmpty)
                      ? fechaVence
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.drive_eta_outlined,
                  label: 'Categoría',
                  value: (categoria != null && categoria.trim().isNotEmpty)
                      ? categoria
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha de emisión',
                  value:
                      (fechaEmision != null && fechaEmision.trim().isNotEmpty)
                      ? fechaEmision
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de la licencia',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          estadoLic == 'Vigente'
                              ? Icons.check_circle_rounded
                              : (estadoLic == 'Por vencer'
                                    ? Icons.access_time_filled
                                    : Icons.cancel),
                          color: colorLic,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estadoLic,
                          style: TextStyle(
                            color: colorLic,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 4: DOCUMENTOS RESUMEN
  // ---------------------------------------------------------------------------
  Widget _buildCardDocumentosResumen() {
    return _buildContainerCard(
      icon: Icons.description_outlined,
      title: 'Documentos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todos los documentos del conductor se encuentran registrados y validados en el sistema sindical.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => setState(() => _tabSeleccionada = 1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'Ver documentos del conductor',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 5: VEHÍCULO ASIGNADO (TRUFI)
  // ---------------------------------------------------------------------------
  Widget _buildCardVehiculoAsignado() {
    final placa = _c['placa']?.toString() ?? '1234-ABC';

    return _buildContainerCard(
      icon: Icons.directions_bus_outlined,
      title: 'Vehículo asignado',
      subtitle: 'Trufi y datos del vehículo',
      child: Column(
        children: [
          Row(
            children: [
              // Ilustración / foto de Trufi boliviano Toyota Hiace
              Container(
                width: 130,
                height: 85,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/trufi_minibus.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(
                        Icons.directions_bus,
                        size: 48,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Datos del Vehículo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trufi N°',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    const Text(
                      '101',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Placa',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        placa.isNotEmpty ? placa : 'Sin placa',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.drive_file_rename_outline,
                  label: 'Marca / Modelo',
                  value:
                      ((_c['marca']?.toString() ?? '').isNotEmpty ||
                          (_c['modelo']?.toString() ?? '').isNotEmpty)
                      ? '${_c['marca'] ?? ''} ${_c['modelo'] ?? ''}'.trim()
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: _buildDatoItem(
                  icon: Icons.palette_outlined,
                  label: 'Color',
                  value: (_c['color']?.toString().isNotEmpty == true)
                      ? _c['color'].toString()
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDatoItem(
            icon: Icons.people_outline,
            label: 'Capacidad',
            value: _c['capacidad'] != null
                ? '${_c['capacidad']} pasajeros'
                : 'No registrado',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 6: ACTIVIDAD RECIENTE
  // ---------------------------------------------------------------------------
  Widget _buildCardActividadReciente() {
    return _buildContainerCard(
      icon: Icons.access_time,
      title: 'Actividad reciente',
      subtitle: 'Accesos y registros del conductor',
      child: Column(
        children: [
          _buildAccionEnlace(
            icon: Icons.calendar_today,
            colorIcon: const Color(0xFF10B981),
            titulo: 'Asistencias',
            subtitulo: 'Consultar registros de asistencias del conductor',
            onTap: () => setState(() => _tabSeleccionada = 3),
          ),
          const SizedBox(height: 10),
          _buildAccionEnlace(
            icon: Icons.receipt_long_outlined,
            colorIcon: const Color(0xFF3B82F6),
            titulo: 'Historial de observaciones',
            subtitulo: 'Consultar registros de observaciones y sanciones',
            onTap: () => setState(() => _tabSeleccionada = 4),
          ),
          const SizedBox(height: 10),
          _buildAccionEnlace(
            icon: Icons.location_on,
            colorIcon: const Color(0xFF8B5CF6),
            titulo: 'Ubicación en tiempo real',
            subtitulo: 'Ver ubicación actual de la trufi (asignada)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GpsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionEnlace({
    required IconData icon,
    required Color colorIcon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorIcon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorIcon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DOCUMENTOS DETALLE
  // ---------------------------------------------------------------------------
  Widget _buildTabDocumentos(String ci) {
    final licVence = _c['licencia_vencimiento']?.toString();
    final licEstado = DocumentosAlerta.estado(licVence);
    final licColor = DocumentosAlerta.color(licEstado);
    final licDias = DocumentosAlerta.diasRestantes(licVence);

    final soatVence = _c['fecha_vencimiento_soat']?.toString();
    final soatEstado = DocumentosAlerta.estado(soatVence);
    final soatColor = DocumentosAlerta.color(soatEstado);
    final soatDias = DocumentosAlerta.diasRestantes(soatVence);

    final ruat = _c['ruat']?.toString();
    final soatNum = _c['soat']?.toString();

    final docs = [
      {
        'nombre': 'Cédula de Identidad (CI)',
        'estado': 'Registrado',
        'color': const Color(0xFF10B981),
        'detalle': 'CI: $ci',
        'icono': Icons.badge,
      },
      {
        'nombre': 'Licencia de Conducir',
        'estado': licEstado,
        'color': licColor,
        'detalle': (licVence != null && licVence.isNotEmpty)
            ? 'Vence: $licVence ${licDias != null ? (licDias < 0 ? '• Vencida hace ${-licDias} días' : '• Quedan $licDias días') : ''}'
            : 'Fecha de vencimiento no registrada',
        'icono': Icons.credit_card,
      },
      {
        'nombre': 'SOAT Vehicular',
        'estado': soatEstado,
        'color': soatColor,
        'detalle': (soatVence != null && soatVence.isNotEmpty)
            ? 'Vence: $soatVence ${soatDias != null ? (soatDias < 0 ? '• Vencido hace ${-soatDias} días' : '• Quedan $soatDias días') : ''}'
            : (soatNum != null && soatNum.isNotEmpty
                  ? 'Póliza: $soatNum (Sin fecha)'
                  : 'No registrado'),
        'icono': Icons.security,
      },
      {
        'nombre': 'RUAT / Registro de Vehículo',
        'estado': (ruat != null && ruat.isNotEmpty)
            ? 'Registrado'
            : 'No registrado',
        'color': (ruat != null && ruat.isNotEmpty)
            ? const Color(0xFF10B981)
            : const Color(0xFF94A3B8),
        'detalle': (ruat != null && ruat.isNotEmpty)
            ? 'N° RUAT: $ruat'
            : 'Documento pendiente de registro',
        'icono': Icons.description,
      },
    ];

    return Column(
      children: docs.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  d['icono'] as IconData,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['nombre'] as String,
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['detalle'] as String,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (d['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  d['estado'] as String,
                  style: TextStyle(
                    color: d['color'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: TRUFI ASIGNADA
  // ---------------------------------------------------------------------------
  Widget _buildTabTrufi() {
    final placa = _c['placa']?.toString() ?? 'Sin placa';
    final marca = _c['marca']?.toString() ?? 'Toyota';
    final modelo = _c['modelo']?.toString() ?? 'Hiace';
    final color = _c['color']?.toString() ?? 'No registrado';
    final capacidad = _c['capacidad']?.toString() ?? '14';
    final soat = _c['soat']?.toString() ?? 'No registrado';
    final soatVence =
        _c['fecha_vencimiento_soat']?.toString() ?? 'No registrado';
    final ruat = _c['ruat']?.toString() ?? 'No registrado';

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/trufi_minibus.jpg',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                color: Colors.white,
                child: const Center(
                  child: Icon(
                    Icons.directions_bus,
                    size: 80,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildContainerCard(
          icon: Icons.directions_bus,
          title: 'Ficha Técnica del Minibus Trufi',
          child: Column(
            children: [
              _buildFilaDato(
                'Placa de Control',
                placa.isNotEmpty ? placa : 'Sin placa asignada',
              ),
              _buildFilaDato(
                'Marca',
                marca.isNotEmpty ? marca : 'No registrado',
              ),
              _buildFilaDato(
                'Modelo',
                modelo.isNotEmpty ? modelo : 'No registrado',
              ),
              _buildFilaDato(
                'Color',
                color.isNotEmpty ? color : 'No registrado',
              ),
              _buildFilaDato('Capacidad', '$capacidad pasajeros sentados'),
              _buildFilaDato(
                'Póliza SOAT',
                soat.isNotEmpty ? soat : 'No registrado',
              ),
              _buildFilaDato(
                'Vencimiento SOAT',
                soatVence.isNotEmpty ? soatVence : 'No registrado',
              ),
              _buildFilaDato(
                'Registro RUAT',
                ruat.isNotEmpty ? ruat : 'No registrado',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilaDato(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: ASISTENCIAS
  // ---------------------------------------------------------------------------
  Widget _buildTabAsistencias() {
    if (_isLoadingDetalles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_asistencias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 54,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin asistencias registradas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Las llegadas a Cruce Villadela y Teleférico se mostrarán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Registrar Asistencia',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _asistencias.map((a) {
        final punto = a['punto_nombre'] ?? 'Punto de Control';
        final fecha = a['fecha'] ?? '';
        final hora = a['hora_llegada'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      punto.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '$fecha • $hora',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'REGISTRADO',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: OBSERVACIONES Y SANCIONES
  // ---------------------------------------------------------------------------
  Widget _buildTabObservaciones() {
    if (_isLoadingDetalles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_sanciones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 54,
              color: Color(0xFF10B981),
            ),
            SizedBox(height: 12),
            Text(
              'Conductor sin sanciones ni observaciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Este chofer mantiene un récord limpio en el grupo sindical.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _sanciones.map((s) {
        final motivo = s['motivo'] ?? 'Observación';
        final monto = s['monto']?.toString() ?? '0';
        final estado = s['estado'] ?? 'pendiente';
        final esPagado = estado.toString().toLowerCase() == 'pagada';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: esPagado
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: esPagado
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motivo.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Monto: Bs. $monto',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: esPagado
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estado.toString().toUpperCase(),
                  style: TextStyle(
                    color: esPagado
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS REUTILIZABLES
  // ---------------------------------------------------------------------------
  Widget _buildContainerCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDatoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
