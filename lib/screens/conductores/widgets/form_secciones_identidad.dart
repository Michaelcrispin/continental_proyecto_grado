import 'package:flutter/material.dart';
import '../../../core/normalizadores.dart';
import 'form_field_widgets.dart';

/// Sección 1: Padrón Sindical Continental (Grupo 101/127 y N.º Interno Móvil)
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
      icono: Icons.groups_outlined,
      colorIcono: const Color(0xFF1E3A8A),
      bgIcono: const Color(0xFFEFF6FF),
      titulo: 'Padrón Sindical Continental',
      subtitulo: 'Asignación de grupo y número de móvil interno',
      contenido: [
        const Text(
          'Grupo Sindical *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onGrupoChanged('101'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: grupo == '101'
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: grupo == '101'
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFCBD5E1),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 18,
                        color: grupo == '101'
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grupo 101',
                        style: TextStyle(
                          color: grupo == '101'
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => onGrupoChanged('127'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: grupo == '127'
                        ? const Color(0xFF0D9488)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: grupo == '127'
                          ? const Color(0xFF0D9488)
                          : const Color(0xFFCBD5E1),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 18,
                        color: grupo == '127'
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grupo 127',
                        style: TextStyle(
                          color: grupo == '127'
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FormTextField(
          controller: numeroInternoCtrl,
          label: 'N.º Interno (Móvil)',
          hint: 'Ej. 1, 14, 25 (según orden de lista)',
          icon: Icons.tag,
          keyboardType: TextInputType.number,
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
  });

  @override
  Widget build(BuildContext context) {
    return FormCardSeccion(
      icono: Icons.lock_person_outlined,
      colorIcono: const Color(0xFF2563EB),
      bgIcono: const Color(0xFFEFF6FF),
      titulo: 'Cuenta y Acceso al Sistema',
      subtitulo: 'Credenciales obligatorias para inicio de sesión del chofer',
      contenido: [
        FormTextField(
          controller: nombreCtrl,
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
              child: FormTextField(
                controller: ciCtrl,
                label: 'Cédula de Identidad (CI) *',
                hint: 'Ej. 8493021',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.text,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El CI es obligatorio (Login)'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FormTextField(
                controller: telefonoCtrl,
                label: 'Teléfono / Celular',
                hint: '76543210',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FormTextField(
          controller: passCtrl,
          label: esEdicion
              ? 'Nueva Contraseña (dejar en blanco para no cambiar)'
              : 'Contraseña de Acceso *',
          hint: esEdicion ? 'Sin cambios' : 'Mínimo 4 caracteres',
          icon: Icons.lock_outline,
          obscureText: obscurePass,
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
      icono: Icons.home_work_outlined,
      colorIcono: const Color(0xFF0D9488),
      bgIcono: const Color(0xFFCCFBF1),
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
        const SizedBox(height: 12),
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
