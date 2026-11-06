import 'package:flutter/material.dart';
import '../../../core/documentos_alerta.dart';

const Color kVerdeCorporativo = Color(0xFF02634C);
const Color kMentaSuave = Color(0xFFE8F5EF);
const Color kBordeCampos = Color(0xFFE2E8F0);
const Color kFondoCampos = Color(0xFFF8FAFC);
const Color kTextoPrincipal = Color(0xFF1E293B);
const Color kTextoSecundario = Color(0xFF64748B);

/// Tarjeta seccional para agrupar campos del formulario, con diseño coincidente con el mockup.
class FormCardSeccion extends StatelessWidget {
  final IconData icono;
  final Color colorIcono;
  final Color bgIcono;
  final String titulo;
  final String subtitulo;
  final List<Widget> contenido;

  const FormCardSeccion({
    super.key,
    required this.icono,
    this.colorIcono = kVerdeCorporativo,
    this.bgIcono = kMentaSuave,
    required this.titulo,
    required this.subtitulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBordeCampos, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgIcono,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: colorIcono, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: kTextoPrincipal,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: kTextoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...contenido,
        ],
      ),
    );
  }
}

/// Campo de texto personalizado y estilizado para el formulario de conductor.
class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const FormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        fontSize: 13.5,
        color: kTextoPrincipal,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextoSecundario, fontSize: 12.5),
        floatingLabelStyle: const TextStyle(
          color: kVerdeCorporativo,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
        errorMaxLines: 2,
        errorStyle: const TextStyle(
          color: Color(0xFFDC2626),
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: kTextoSecundario, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kFondoCampos,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBordeCampos, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBordeCampos, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kVerdeCorporativo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
}

/// Selector de fecha con DatePicker estilizado y sufijo desplegable.
class FormDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String tituloPicker;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const FormDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.tituloPicker,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _seleccionarFecha(BuildContext context) async {
    DateTime inicial = DateTime.now();
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
      helpText: tituloPicker.toUpperCase(),
      confirmText: 'ACEPTAR',
      cancelText: 'CANCELAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kVerdeCorporativo,
              onPrimary: Colors.white,
              onSurface: kTextoPrincipal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final str =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      controller.text = str;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _seleccionarFecha(context),
      borderRadius: BorderRadius.circular(16),
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(
            fontSize: 13.5,
            color: kTextoPrincipal,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: kTextoSecundario, fontSize: 12.5),
            floatingLabelStyle: const TextStyle(
              color: kVerdeCorporativo,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
            prefixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: kTextoSecundario,
              size: 19,
            ),
            suffixIcon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: kTextoSecundario,
              size: 24,
            ),
            filled: true,
            fillColor: kFondoCampos,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kBordeCampos, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kBordeCampos, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kVerdeCorporativo, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector desplegable personalizado con diseño coherente.
class FormDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T?> onChanged;

  const FormDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(
        Icons.arrow_drop_down_rounded,
        color: kTextoSecundario,
        size: 24,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextoSecundario, fontSize: 12.5),
        floatingLabelStyle: const TextStyle(
          color: kVerdeCorporativo,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: kTextoSecundario, size: 20),
        filled: true,
        fillColor: kFondoCampos,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBordeCampos, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBordeCampos, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kVerdeCorporativo, width: 1.5),
        ),
      ),
      style: const TextStyle(
        fontSize: 13,
        color: kTextoPrincipal,
        fontWeight: FontWeight.w500,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            item.toString(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

/// Badge en tiempo real que indica si la licencia o el SOAT están vigentes o por vencer.
class FormBadgeVigencia extends StatelessWidget {
  final String fechaIso;
  final String docNombre;

  const FormBadgeVigencia({
    super.key,
    required this.fechaIso,
    required this.docNombre,
  });

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: color.withOpacity(0.3)),
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
