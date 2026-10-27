import 'package:flutter/material.dart';
import '../../../widgets/avatar_conductor.dart';

/// Modal interactivo para seleccionar al conductor beneficiario de una ayuda económica.
/// Ofrece buscador en tiempo real por nombre o CI, diseño visual pulido y selección rápida.
class SelectorBeneficiarioSheet extends StatefulWidget {
  final List<Map<String, dynamic>> conductores;
  final String? idSeleccionadoActual;

  const SelectorBeneficiarioSheet({
    super.key,
    required this.conductores,
    this.idSeleccionadoActual,
  });

  static Future<Map<String, dynamic>?> mostrar(
    BuildContext context, {
    required List<Map<String, dynamic>> conductores,
    String? idSeleccionadoActual,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectorBeneficiarioSheet(
        conductores: conductores,
        idSeleccionadoActual: idSeleccionadoActual,
      ),
    );
  }

  @override
  State<SelectorBeneficiarioSheet> createState() => _SelectorBeneficiarioSheetState();
}

class _SelectorBeneficiarioSheetState extends State<SelectorBeneficiarioSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.conductores.where((c) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      final nombre = (c['nombre'] ?? '').toString().toLowerCase();
      final ci = (c['ci'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || ci.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Píldora superior
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // TÍTULO Y BOTÓN CERRAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conductor Beneficiario',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2B5B),
                          ),
                        ),
                        Text(
                          'Selecciona al compañero que recibirá la ayuda',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // BUSCADOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _busqueda = v.trim()),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o carnet (CI)...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _busqueda = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // LISTADO DE CONDUCTORES
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontró ningún conductor con ese dato.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final c = filtrados[index];
                      final id = c['id_conductor']?.toString() ?? '';
                      final esSeleccionado = id == widget.idSeleccionadoActual;
                      final nombre = c['nombre']?.toString() ?? 'Conductor';
                      final ci = c['ci']?.toString() ?? 'S/CI';
                      final telefono = c['telefono']?.toString();
                      final foto = c['foto']?.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: esSeleccionado ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: esSeleccionado ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                            width: esSeleccionado ? 1.5 : 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x050F2B5B),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          onTap: () => Navigator.pop(context, c),
                          leading: AvatarConductor(
                            foto: foto,
                            nombre: nombre,
                            radio: 20,
                          ),
                          title: Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.w600,
                              color: const Color(0xFF0F2B5B),
                            ),
                          ),
                          subtitle: Text(
                            'CI: $ci${(telefono != null && telefono.isNotEmpty) ? ' · Cel: $telefono' : ''}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: esSeleccionado
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                                )
                              : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
