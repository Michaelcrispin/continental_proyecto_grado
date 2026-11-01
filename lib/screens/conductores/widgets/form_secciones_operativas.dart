import 'package:flutter/material.dart';
import 'form_field_widgets.dart';

/// Sección 4: Licencia de Conducir
class SeccionLicencia extends StatelessWidget {
  final TextEditingController licenciaCtrl;
  final String licenciaCategoria;
  final List<String> categoriasLicencia;
  final TextEditingController licenciaEmisionCtrl;
  final TextEditingController licenciaVenceCtrl;
  final ValueChanged<String?> onCategoriaChanged;

  const SeccionLicencia({
    super.key,
    required this.licenciaCtrl,
    required this.licenciaCategoria,
    required this.categoriasLicencia,
    required this.licenciaEmisionCtrl,
    required this.licenciaVenceCtrl,
    required this.onCategoriaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.drive_eta_outlined,
      colorIcono: const Color(0xFFF59E0B),
      bgIcono: const Color(0xFFFEF3C7),
      titulo: 'Licencia de Conducir',
      subtitulo: 'Número, categoría profesional y vigencia para control',
      contenido: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: FormTextField(
                controller: licenciaCtrl,
                label: 'N° de Licencia',
                hint: 'Ej. 8493021 (Opcional, usa CI)',
                icon: Icons.credit_card_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: FormDropdownField<String>(
                label: 'Categoría',
                value: licenciaCategoria,
                items: categoriasLicencia,
                icon: Icons.card_membership_outlined,
                onChanged: onCategoriaChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormDateField(
                controller: licenciaEmisionCtrl,
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
                  FormDateField(
                    controller: licenciaVenceCtrl,
                    label: 'Fecha de Vencimiento',
                    hint: 'AAAA-MM-DD',
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

/// Sección 5: Vehículo Propio del Conductor
class SeccionVehiculo extends StatelessWidget {
  final TextEditingController placaCtrl;
  final TextEditingController ruatCtrl;
  final TextEditingController marcaCtrl;
  final TextEditingController modeloCtrl;
  final TextEditingController colorCtrl;
  final TextEditingController capacidadCtrl;
  final TextEditingController soatCtrl;
  final TextEditingController soatVenceCtrl;

  const SeccionVehiculo({
    super.key,
    required this.placaCtrl,
    required this.ruatCtrl,
    required this.marcaCtrl,
    required this.modeloCtrl,
    required this.colorCtrl,
    required this.capacidadCtrl,
    required this.soatCtrl,
    required this.soatVenceCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.local_taxi_outlined,
      colorIcono: const Color(0xFF10B981),
      bgIcono: const Color(0xFFECFDF5),
      titulo: 'Datos del Vehículo',
      subtitulo: 'Placa, RUAT, características y SOAT',
      contenido: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: FormTextField(
                controller: placaCtrl,
                label: 'Placa del Vehículo',
                hint: 'Ej. 2849-ABC',
                icon: Icons.directions_car_outlined,
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: FormTextField(
                controller: ruatCtrl,
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
              child: FormTextField(
                controller: marcaCtrl,
                label: 'Marca',
                hint: 'Toyota',
                icon: Icons.branding_watermark_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FormTextField(
                controller: modeloCtrl,
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
              child: FormTextField(
                controller: colorCtrl,
                label: 'Color de la Unidad',
                hint: 'Blanco / Azul',
                icon: Icons.palette_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: FormTextField(
                controller: capacidadCtrl,
                label: 'Capacidad',
                hint: '14 pax',
                icon: Icons.airline_seat_recline_normal_outlined,
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
              child: FormTextField(
                controller: soatCtrl,
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
                  FormDateField(
                    controller: soatVenceCtrl,
                    label: 'Vencimiento SOAT',
                    hint: 'AAAA-MM-DD',
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

/// Sección 6: Estado Operativo (Habilitado / Inhabilitado)
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: estadoActivo
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
              color: estadoActivo
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              estadoActivo
                  ? Icons.check_circle_outline
                  : Icons.block_outlined,
              color: estadoActivo
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
                  estadoActivo
                      ? 'Estado: HABILITADO'
                      : 'Estado: INHABILITADO',
                  style: TextStyle(
                    color: estadoActivo
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estadoActivo
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
            value: estadoActivo,
            activeColor: const Color(0xFF10B981),
            onChanged: onEstadoChanged,
          ),
        ],
      ),
    );
  }
}

/// Barra inferior flotante de acciones: Cancelar y Guardar
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
                onPressed: isSaving ? null : onCancelar,
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
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            esEdicion
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
    );
  }
}
