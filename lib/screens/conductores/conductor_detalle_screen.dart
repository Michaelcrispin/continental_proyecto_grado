import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../widgets/avatar_conductor.dart';
import 'conductor_form_screen.dart';
import 'widgets/detalle_header_banner.dart';
import 'widgets/dialogo_baja_conductor.dart';
import 'widgets/dialogo_reactivar_conductor.dart';
import 'widgets/tab_documentos.dart';
import 'widgets/tab_info_general.dart';

/// Pantalla completa de detalle/ficha técnica sindical del conductor.
class ConductorDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> conductor;

  const ConductorDetalleScreen({super.key, required this.conductor});

  @override
  State<ConductorDetalleScreen> createState() => _ConductorDetalleScreenState();
}

class _ConductorDetalleScreenState extends State<ConductorDetalleScreen> {
  late Map<String, dynamic> _c;
  int _tabSeleccionada = 0; // 0: Info general, 1: Documentos
  bool _fueModificado = false;

  @override
  void initState() {
    super.initState();
    _c = Map<String, dynamic>.from(widget.conductor);
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    final idConductor = _c['id_conductor']?.toString();
    try {
      if (idConductor != null && idConductor.isNotEmpty) {
        final ficha = await DatabaseHelper.instance.fichaConductor(idConductor);
        if (mounted && ficha != null) {
          setState(() {
            _c = Map<String, dynamic>.from(ficha);
          });
          return;
        }
      }
    } catch (_) {}
  }

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
  // BAJA LÓGICA Y REACTIVACIÓN DIRECTA DESDE LA FICHA
  // ---------------------------------------------------------------------------
  Future<void> _cambiarEstadoConductor(bool esActivo) async {
    final idUsuario = _c['id_usuario']?.toString();
    final nombre = _c['nombre']?.toString() ?? 'este conductor';
    if (idUsuario == null) return;

    if (esActivo) {
      final motivo = await mostrarDialogoBajaConductor(context, nombre: nombre);
      if (motivo != null) {
        try {
          await DatabaseHelper.instance.darDeBajaConductor(
            idUsuario,
            motivo: motivo.isEmpty ? null : motivo,
          );
          _fueModificado = true;
          await _cargarDetalles();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFEF4444),
                content: Text('Conductor "$nombre" dado de baja (Inactivo).'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } else {
      final confirmado =
          await mostrarDialogoReactivarConductor(context, nombre: nombre);
      if (confirmado) {
        try {
          await DatabaseHelper.instance.reactivarConductor(idUsuario);
          _fueModificado = true;
          await _cargarDetalles();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF10B981),
                content: Text('Conductor "$nombre" reactivado con éxito.'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
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
              DetalleHeaderBanner(
                conductor: _c,
                esActivo: esActivo,
                onVolver: () => Navigator.pop(context, _fueModificado),
                onEditar: _editarConductor,
                onCambiarFoto: _cambiarFotoPerfil,
              ),

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
  // BARRA DE SUB-PESTAÑAS
  // ---------------------------------------------------------------------------
  Widget _buildSubTabs() {
    final pestanas = [
      {'icon': Icons.person, 'label': 'Información general'},
      {'icon': Icons.description_outlined, 'label': 'Documentos'},
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
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFF02634C)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    p['icon'] as IconData,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF02634C)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF02634C)
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 14,
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
  // CONTENIDO SEGÚN LA PESTAÑA SELECCIONADA
  // ---------------------------------------------------------------------------
  Widget _buildContenidoTab(String nombre, String ci, bool esActivo) {
    switch (_tabSeleccionada) {
      case 1:
        return TabDocumentos(conductor: _c, ci: ci);
      case 0:
      default:
        return TabInfoGeneral(
          conductor: _c,
          ci: ci,
          nombre: nombre,
          esActivo: esActivo,
          onCambiarEstado: _cambiarEstadoConductor,
          onIrATab: (idx) => setState(() => _tabSeleccionada = idx),
        );
    }
  }
}
