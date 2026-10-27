import 'package:flutter/material.dart';
import '../../../widgets/avatar_conductor.dart';

/// Modal interactivo para seleccionar conductores activos con buscador en tiempo real,
/// casillas de verificación individuales y botones rápidos de selección total.
class SelectorConductoresSheet extends StatefulWidget {
  final List<Map<String, dynamic>> todosConductores;
  final Set<String> idsSeleccionadosIniciales;

  const SelectorConductoresSheet({
    super.key,
    required this.todosConductores,
    required this.idsSeleccionadosIniciales,
  });

  static Future<Set<String>?> mostrar(
    BuildContext context, {
    required List<Map<String, dynamic>> todosConductores,
    required Set<String> idsSeleccionados,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectorConductoresSheet(
        todosConductores: todosConductores,
        idsSeleccionadosIniciales: idsSeleccionados,
      ),
    );
  }

  @override
  State<SelectorConductoresSheet> createState() => _SelectorConductoresSheetState();
}

class _SelectorConductoresSheetState extends State<SelectorConductoresSheet> {
  late Set<String> _seleccionados;
  String _busqueda = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seleccionados = Set<String>.from(widget.idsSeleccionadosIniciales);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleTodos(bool? valor) {
    setState(() {
      if (valor == true) {
        for (final c in widget.todosConductores) {
          final id = c['id_conductor']?.toString();
          if (id != null) _seleccionados.add(id);
        }
      } else {
        _seleccionados.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.todosConductores.where((c) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      final nombre = (c['nombre'] ?? '').toString().toLowerCase();
      final ci = (c['ci'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || ci.contains(q);
    }).toList();

    final todosEstanSeleccionados = _seleccionados.length == widget.todosConductores.length &&
        widget.todosConductores.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Píldora superior decorativa
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

          // TÍTULO Y CERRAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conductores Activos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2B5B),
                      ),
                    ),
                    Text(
                      '${_seleccionados.length} de ${widget.todosConductores.length} seleccionados',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
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

          const SizedBox(height: 10),

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
                  hintText: 'Buscar conductor por nombre o CI...',
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

          const SizedBox(height: 8),

          // FILA RÁPIDA: SELECCIONAR TODOS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Checkbox(
                  value: todosEstanSeleccionados,
                  activeColor: const Color(0xFF0F2B5B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: _toggleTodos,
                ),
                GestureDetector(
                  onTap: () => _toggleTodos(!todosEstanSeleccionados),
                  child: const Text(
                    'Seleccionar todos los conductores activos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2B5B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // LISTA DE CONDUCTORES
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron conductores con ese criterio.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final c = filtrados[index];
                      final id = c['id_conductor']?.toString() ?? '';
                      final isSelected = _seleccionados.contains(id);
                      final nombre = c['nombre']?.toString() ?? 'Conductor';
                      final ci = c['ci']?.toString() ?? 'S/CI';
                      final foto = c['foto']?.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFBBF7D0) : const Color(0xFFF1F5F9),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          activeColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _seleccionados.add(id);
                              } else {
                                _seleccionados.remove(id);
                              }
                            });
                          },
                          secondary: AvatarConductor(
                            foto: foto,
                            nombre: nombre,
                            radio: 18,
                          ),
                          title: Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: const Color(0xFF0F2B5B),
                            ),
                          ),
                          subtitle: Text(
                            'CI: $ci',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // BOTÓN INFERIOR DE CONFIRMACIÓN
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2B5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context, _seleccionados),
                child: Text(
                  'Confirmar (${_seleccionados.length} seleccionados)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
