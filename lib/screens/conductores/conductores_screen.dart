import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/database_helper.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import '../../core/documentos_alerta.dart';
import 'conductor_detalle_screen.dart';
import 'conductor_form_screen.dart';
import 'widgets/conductor_card.dart';
import 'widgets/dialogo_baja_conductor.dart';
import 'widgets/dialogo_reactivar_conductor.dart';
import 'widgets/filtro_conductores_bar.dart';

class ConductoresScreen extends StatefulWidget {
  final String grupo;

  const ConductoresScreen({super.key, this.grupo = '101'});

  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _conductoresFiltrados = [];
  bool _isLoading = true;
  String _busqueda = '';
  String _filtroActivo = 'todos'; // 'todos', 'activos', 'inactivos', 'alertas'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(
          context, SesionService.instance.rol, Permisos.moduloConductores)) {
        return;
      }
    });
    _cargarConductores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    setState(() => _isLoading = true);
    try {
      final lista = await DatabaseHelper.instance.conductoresConAuto();
      if (mounted) {
        setState(() {
          _conductores = lista;
          _aplicarFiltros();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filtrar(String query) {
    _busqueda = query;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final q = _busqueda.toLowerCase().trim();
    setState(() {
      _conductoresFiltrados = _conductores.where((c) {
        // 1. Filtrar estrictamente por el grupo de esta pantalla ('101' o '127')
        final grupo = (c['grupo'] ?? '101').toString();
        if (grupo != widget.grupo) return false;

        // 2. Filtrar por búsqueda de nombre, CI o placa
        final nombre = (c['nombre'] ?? '').toString().toLowerCase();
        final ci = (c['ci'] ?? '').toString().toLowerCase();
        final placa = (c['placa'] ?? '').toString().toLowerCase();
        final coincideBusqueda = q.isEmpty ||
            nombre.contains(q) ||
            ci.contains(q) ||
            placa.contains(q);
        if (!coincideBusqueda) return false;

        // 3. Sub-filtro de estado y alertas dentro del grupo
        final estado = (c['estado'] ?? 'activo').toString().toLowerCase();
        switch (_filtroActivo) {
          case 'activos':
            return estado == 'activo';
          case 'inactivos':
            return estado != 'activo';
          case 'alertas':
            final estadoLic = DocumentosAlerta.estado(
              c['licencia_vencimiento']?.toString(),
            );
            final estadoSoat = DocumentosAlerta.estado(
              c['fecha_vencimiento_soat']?.toString(),
            );
            return estadoLic == 'Vencida' ||
                estadoLic == 'Por vencer' ||
                estadoSoat == 'Vencida';
          default:
            return true;
        }
      }).toList();
    });
  }

  void _abrirFormularioConductor({Map<String, dynamic>? conductorExistente}) async {
    final modificado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConductorFormScreen(
          conductor: conductorExistente,
          grupoInicial: widget.grupo,
        ),
      ),
    );
    if (modificado == true) {
      _cargarConductores();
    }
  }

  void _mostrarFichaDetalleConductor(Map<String, dynamic> c) async {
    final modificado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConductorDetalleScreen(conductor: c),
      ),
    );
    if (modificado == true) {
      _cargarConductores();
    }
  }

  // ---------------------------------------------------------------------------
  // BAJA LÓGICA (NO DESTRUCTIVA - PRESERVA 100% HISTORIAL)
  // ---------------------------------------------------------------------------
  Future<void> _confirmarBajaConductor(Map<String, dynamic> c) async {
    final idUsuario = c['id_usuario']?.toString();
    final nombre = c['nombre'] ?? 'este conductor';
    if (idUsuario == null) return;

    final motivo = await mostrarDialogoBajaConductor(context, nombre: nombre);
    if (motivo != null) {
      try {
        await DatabaseHelper.instance.darDeBajaConductor(
          idUsuario,
          motivo: motivo.isEmpty ? null : motivo,
        );
        _cargarConductores();
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
  }

  Future<void> _confirmarReactivacionConductor(Map<String, dynamic> c) async {
    final idUsuario = c['id_usuario']?.toString();
    final nombre = c['nombre'] ?? 'este conductor';
    if (idUsuario == null) return;

    final confirmado =
        await mostrarDialogoReactivarConductor(context, nombre: nombre);
    if (confirmado) {
      try {
        await DatabaseHelper.instance.reactivarConductor(idUsuario);
        _cargarConductores();
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

  // ---------------------------------------------------------------------------
  // CONSTRUCCIÓN PRINCIPAL (GRID CON COMPONENTES MODULARES)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cantConductores = _conductoresFiltrados.length;

    // Métricas del grupo asignado a esta pantalla (101 o 127)
    final conductoresDelGrupo = _conductores
        .where((c) => (c['grupo'] ?? '101').toString() == widget.grupo)
        .toList();
    final cantTotalGrupo = conductoresDelGrupo.length;
    final cantActivosGrupo = conductoresDelGrupo
        .where((c) =>
            (c['estado'] ?? 'activo').toString().toLowerCase() == 'activo')
        .length;
    final cantInactivosGrupo = conductoresDelGrupo
        .where((c) =>
            (c['estado'] ?? 'activo').toString().toLowerCase() != 'activo')
        .length;
    final cantAlertasGrupo = conductoresDelGrupo.where((c) {
      final estadoLic =
          DocumentosAlerta.estado(c['licencia_vencimiento']?.toString());
      final estadoSoat =
          DocumentosAlerta.estado(c['fecha_vencimiento_soat']?.toString());
      return estadoLic == 'Vencida' ||
          estadoLic == 'Por vencer' ||
          estadoSoat == 'Vencida';
    }).length;

    final colorPrimario = widget.grupo == '127'
        ? const Color(0xFF0D9488)
        : const Color(0xFF1E3A8A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorPrimario),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Grupo Continental ${widget.grupo} ($cantConductores)',
          style: TextStyle(
            color: colorPrimario,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorPrimario),
            tooltip: 'Recargar',
            onPressed: _cargarConductores,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (c, e, s) =>
                  Icon(Icons.local_taxi_rounded, color: colorPrimario),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Buscador superior
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, CI o placa...',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF10B981)),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _filtrar('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: _filtrar,
                ),
              ),

              // 2. Sub-filtros rápidos dentro del grupo (Todos, Activos, Inactivos, Alertas)
              FiltroConductoresBar(
                filtroActivo: _filtroActivo,
                onFiltroChanged: (nuevoFiltro) {
                  setState(() {
                    _filtroActivo = nuevoFiltro;
                    _aplicarFiltros();
                  });
                },
                cantTotal: cantTotalGrupo,
                cantActivos: cantActivosGrupo,
                cantInactivos: cantInactivosGrupo,
                cantAlertas: cantAlertasGrupo,
              ),

              const SizedBox(height: 8),

              // 3. GRIDVIEW CON TARJETAS MODULARIZADAS
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _conductoresFiltrados.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_taxi_outlined,
                                      size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No hay conductores encontrados',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Intenta con otro filtro de búsqueda o registra uno nuevo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarConductores,
                            child: GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 90),
                              itemCount: _conductoresFiltrados.length,
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.76,
                              ),
                              itemBuilder: (context, index) {
                                final c = _conductoresFiltrados[index];
                                final esActivo = (c['estado'] ?? 'activo')
                                        .toString()
                                        .toLowerCase() ==
                                    'activo';

                                return ConductorCard(
                                  conductor: c,
                                  onTap: () => _mostrarFichaDetalleConductor(c),
                                  onTapVer: () =>
                                      _mostrarFichaDetalleConductor(c),
                                  onTapEditar: () => _abrirFormularioConductor(
                                      conductorExistente: c),
                                  onTapCambiarEstado: () => esActivo
                                      ? _confirmarBajaConductor(c)
                                      : _confirmarReactivacionConductor(c),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Nuevo Conductor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _abrirFormularioConductor(),
      ),
    );
  }
}
