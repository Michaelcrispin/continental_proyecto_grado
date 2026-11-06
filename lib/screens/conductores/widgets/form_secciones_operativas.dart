import 'package:flutter/material.dart';
import 'form_field_widgets.dart';

const Color _kVerdeOscuro = Color(0xFF02634C);
const Color _kMentaSuave = Color(0xFFE8F5EF);

/// Sección 4: Licencia de Conducir con estética corporativa Continental.
class SeccionLicencia extends StatelessWidget {
  final TextEditingController licenciaCtrl;
  final String licenciaCategoria;
  final List<String> categoriasLicencia;
  final TextEditingController licenciaEmisionCtrl;
  final TextEditingController licenciaVenceCtrl;
  final ValueChanged<String?> onCategoriaChanged;
  final String? Function(String?)? validadorLicencia;

  const SeccionLicencia({
    super.key,
    required this.licenciaCtrl,
    required this.licenciaCategoria,
    required this.categoriasLicencia,
    required this.licenciaEmisionCtrl,
    required this.licenciaVenceCtrl,
    required this.onCategoriaChanged,
    this.validadorLicencia,
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.credit_card_rounded,
      colorIcono: _kVerdeOscuro,
      bgIcono: _kMentaSuave,
      titulo: 'Licencia de Conducir',
      subtitulo: 'Número, categoría profesional y vigencia para control',
      contenido: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: FormTextField(
                controller: licenciaCtrl,
                label: 'N° de Licencia',
                hint: 'N° de Licencia',
                icon: Icons.credit_card_outlined,
                validator: validadorLicencia,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: FormDropdownField<String>(
                label: 'Categoría',
                value: licenciaCategoria,
                items: categoriasLicencia,
                icon: Icons.badge_outlined,
                onChanged: onCategoriaChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormDateField(
                controller: licenciaEmisionCtrl,
                label: 'Fecha de Emisión',
                hint: 'Fecha de ...',
                tituloPicker: 'Emisión de Licencia',
                firstDate: DateTime(1980),
                lastDate: DateTime.now(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDateField(
                    controller: licenciaVenceCtrl,
                    label: 'Fecha de Vencimiento',
                    hint: 'Fecha de ...',
                    tituloPicker: 'Vencimiento de Licencia',
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2045),
                  ),
                  FormBadgeVigencia(
                    fechaIso: licenciaVenceCtrl.text,
                    docNombre: 'Licencia',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sección 5: Vehículo Propio del Conductor con estética corporativa Continental.
class SeccionVehiculo extends StatelessWidget {
  final TextEditingController placaCtrl;
  final TextEditingController ruatCtrl;
  final TextEditingController soatCtrl;
  final TextEditingController soatVenceCtrl;
  final String? Function(String?)? validadorPlaca;
  final String? Function(String?)? validadorRuat;
  final String? Function(String?)? validadorSoat;

  const SeccionVehiculo({
    super.key,
    required this.placaCtrl,
    required this.ruatCtrl,
    required this.soatCtrl,
    required this.soatVenceCtrl,
    this.validadorPlaca,
    this.validadorRuat,
    this.validadorSoat,
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.directions_car_rounded,
      colorIcono: _kVerdeOscuro,
      bgIcono: _kMentaSuave,
      titulo: 'Datos del Vehículo',
      subtitulo: 'Placa, RUAT y seguro obligatorio SOAT',
      contenido: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormTextField(
                controller: placaCtrl,
                label: 'Placa del Vehículo',
                hint: 'Placa del Vehículo',
                icon: Icons.directions_car_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: validadorPlaca,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormTextField(
                controller: ruatCtrl,
                label: 'N° de RUAT',
                hint: 'N° de RUAT',
                icon: Icons.description_outlined,
                validator: validadorRuat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormTextField(
                controller: soatCtrl,
                label: 'N° de Póliza SOAT',
                hint: 'N° de Póliza SOAT',
                icon: Icons.shield_outlined,
                validator: validadorSoat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDateField(
                    controller: soatVenceCtrl,
                    label: 'Vencimiento',
                    hint: 'Vencimiento',
                    tituloPicker: 'Vencimiento de SOAT',
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  ),
                  FormBadgeVigencia(
                    fechaIso: soatVenceCtrl.text,
                    docNombre: 'SOAT',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sección 6: Estado Operativo (Habilitado / Inhabilitado) idéntico al mockup.
class SeccionEstadoOperativo extends StatelessWidget {
  final bool estadoActivo;
  final ValueChanged<bool> onEstadoChanged;

  const SeccionEstadoOperativo({
    super.key,
    required this.estadoActivo,
    required this.onEstadoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
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
              color: estadoActivo ? _kMentaSuave : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              estadoActivo
                  ? Icons.check_circle_outline_rounded
                  : Icons.block_rounded,
              color: estadoActivo ? _kVerdeOscuro : const Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estadoActivo
                      ? 'Estado: HABILITADO'
                      : 'Estado: INHABILITADO',
                  style: TextStyle(
                    color: estadoActivo
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estadoActivo
                      ? 'El conductor puede iniciar sesión, marcar asistencias y ser despachado.'
                      : 'Conductor bloqueado operativamente en el sistema.',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: estadoActivo,
            activeColor: Colors.white,
            activeTrackColor: _kVerdeOscuro,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onEstadoChanged,
          ),
        ],
      ),
    );
  }
}

/// Barra inferior de acciones (Cancelar y Guardar / Registrar) coincidente con el mockup.
class FormBarraAcciones extends StatelessWidget {
  final bool esEdicion;
  final bool isSaving;
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  const FormBarraAcciones({
    super.key,
    required this.esEdicion,
    required this.isSaving,
    required this.onCancelar,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
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
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                ),
                onPressed: isSaving ? null : onCancelar,
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 7,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: isSaving ? null : onGuardar,
                child: isSaving
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
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            esEdicion
                                ? 'Guardar Cambios'
                                : 'Registrar Conductor',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
