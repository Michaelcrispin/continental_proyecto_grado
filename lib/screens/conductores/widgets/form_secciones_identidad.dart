import 'package:flutter/material.dart';
import '../../../core/normalizadores.dart';
import 'form_field_widgets.dart';

const Color _kVerdeOscuro = Color(0xFF02634C);
const Color _kMentaSuave = Color(0xFFE8F5EF);

/// Sección 1: Padrón Sindical Continental (Grupo 101/127)
class SeccionPadronSindical extends StatelessWidget {
  final String grupo;
  final TextEditingController numeroInternoCtrl;
  final ValueChanged<String> onGrupoChanged;

  const SeccionPadronSindical({
    super.key,
    required this.grupo,
    required this.numeroInternoCtrl,
    required this.onGrupoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.group_work_rounded,
      colorIcono: _kVerdeOscuro,
      bgIcono: _kMentaSuave,
      titulo: 'Padrón Sindical Continental',
      subtitulo: 'Asignación de grupo sindical (101 o 127)',
      contenido: [
        const Text(
          'Grupo Sindical *',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onGrupoChanged('101'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: grupo == '101' ? _kVerdeOscuro : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: grupo == '101' ? _kVerdeOscuro : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 20,
                        color: grupo == '101' ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grupo 101',
                        style: TextStyle(
                          color: grupo == '101' ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => onGrupoChanged('127'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: grupo == '127' ? _kVerdeOscuro : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: grupo == '127' ? _kVerdeOscuro : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 20,
                        color: grupo == '127' ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grupo 127',
                        style: TextStyle(
                          color: grupo == '127' ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sección 2: Cuenta y Acceso al Sistema
class SeccionCuentaAcceso extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final TextEditingController ciCtrl;
  final String extensionCi;
  final TextEditingController telefonoCtrl;
  final TextEditingController correoCtrl;
  final TextEditingController passCtrl;
  final bool esEdicion;
  final bool obscurePass;
  final VoidCallback onToggleObscure;
  final ValueChanged<String?> onExtensionChanged;
  final String? Function(String?)? validadorNombre;
  final String? Function(String?)? validadorCi;
  final String? Function(String?)? validadorTelefono;
  final String? Function(String?)? validadorCorreo;
  final String? Function(String?)? validadorPass;

  const SeccionCuentaAcceso({
    super.key,
    required this.nombreCtrl,
    required this.ciCtrl,
    required this.extensionCi,
    required this.telefonoCtrl,
    required this.correoCtrl,
    required this.passCtrl,
    required this.esEdicion,
    required this.obscurePass,
    required this.onToggleObscure,
    required this.onExtensionChanged,
    this.validadorNombre,
    this.validadorCi,
    this.validadorTelefono,
    this.validadorCorreo,
    this.validadorPass,
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.lock_person_rounded,
      colorIcono: _kVerdeOscuro,
      bgIcono: _kMentaSuave,
      titulo: 'Cuenta y Acceso al Sistema',
      subtitulo: 'Credenciales obligatorias para inicio de sesión del chofer',
      contenido: [
        FormTextField(
          controller: nombreCtrl,
          label: 'Nombre Completo *',
          hint: 'Ej. Juan Carlos Quispe Mamani',
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          validator: validadorNombre ??
              (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre completo es obligatorio'
                  : null,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: FormTextField(
                controller: ciCtrl,
                label: 'Cédula de Identidad (CI) *',
                hint: 'Ej. 8493021',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.text,
                validator: validadorCi ??
                    (v) => (v == null || v.trim().isEmpty)
                        ? 'El CI es obligatorio (Login)'
                        : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: FormDropdownField<String>(
                label: 'Extensión',
                value: extensionCi,
                items: Normalizadores.departamentosCi,
                icon: Icons.map_outlined,
                onChanged: onExtensionChanged,
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
                controller: telefonoCtrl,
                label: 'Teléfono / Celular *',
                hint: '76543210',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: validadorTelefono,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FormTextField(
                controller: correoCtrl,
                label: 'Correo (Opcional)',
                hint: 'ejemplo@gmail.com',
                icon: Icons.alternate_email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: validadorCorreo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FormTextField(
          controller: passCtrl,
          label: esEdicion
              ? 'Nueva Contraseña (dejar en blanco para no cambiar)'
              : 'Contraseña de Acceso *',
          hint: esEdicion ? 'Sin cambios' : 'Mínimo 4 caracteres',
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePass,
          validator: validadorPass,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePass
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF64748B),
            ),
            onPressed: onToggleObscure,
          ),
        ),
      ],
    );
  }
}

/// Sección 3: Información Personal y Domicilio
class SeccionInfoPersonal extends StatelessWidget {
  final TextEditingController fechaNacimientoCtrl;
  final String estadoCivil;
  final List<String> estadosCiviles;
  final TextEditingController direccionCtrl;
  final ValueChanged<String?> onEstadoCivilChanged;

  const SeccionInfoPersonal({
    super.key,
    required this.fechaNacimientoCtrl,
    required this.estadoCivil,
    required this.estadosCiviles,
    required this.direccionCtrl,
    required this.onEstadoCivilChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.home_work_rounded,
      colorIcono: _kVerdeOscuro,
      bgIcono: _kMentaSuave,
      titulo: 'Información Personal',
      subtitulo: 'Datos domiciliarios y personales del conductor',
      contenido: [
        Row(
          children: [
            Expanded(
              child: FormDateField(
                controller: fechaNacimientoCtrl,
                label: 'Fecha de Nacimiento',
                hint: 'AAAA-MM-DD',
                tituloPicker: 'Fecha de Nacimiento',
                firstDate: DateTime(1940),
                lastDate: DateTime.now(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FormDropdownField<String>(
                label: 'Estado Civil',
                value: estadoCivil,
                items: estadosCiviles,
                icon: Icons.family_restroom_outlined,
                onChanged: onEstadoCivilChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FormTextField(
          controller: direccionCtrl,
          label: 'Dirección de Domicilio',
          hint: 'Ej. Av. 6 de Marzo, Zona Villa Adela, N° 450',
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }
}
