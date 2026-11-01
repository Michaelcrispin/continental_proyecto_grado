import 'package:flutter/material.dart';
import '../../../core/documentos_alerta.dart';

/// Tarjeta seccional para agrupar campos del formulario.
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
    required this.colorIcono,
    required this.bgIcono,
    required this.titulo,
    required this.subtitulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
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
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Selector de fecha con DatePicker estilizado.
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
      controller.text = str;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _seleccionarFecha(context),
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
