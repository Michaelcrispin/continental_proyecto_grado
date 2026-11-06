import 'package:flutter/material.dart';
import '../../core/normalizadores.dart';
import '../../core/permisos.dart';
import '../../services/database_helper.dart';
import '../../services/sesion_service.dart';
import '../../core/documentos_alerta.dart';
import 'conductor_detalle_screen.dart';
import 'conductor_form_screen.dart';
import 'widgets/conductor_card.dart';
import 'widgets/dialogo_baja_conductor.dart';
import 'widgets/dialogo_reactivar_conductor.dart';
import 'widgets/filtro_conductores_bar.dart';

const _kVerdeOscuro = Color(0xFF02634C);

class ConductoresScreen extends StatefulWidget {
  final String grupo;

  const ConductoresScreen({super.key, this.grupo = '101-127'});

  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _conductoresFiltrados = [];
  bool _isLoading = true;
  String _busqueda = '';
  String _filtroActivo = 'todos'; // 'todos', 'activos', 'inactivos', 'alertas'
  bool _esVistaCuadricula = false; // Inicia en columnas (lista) al entrar
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
      final filtrados = _conductores.where((c) {
        // Flota unificada: si widget.grupo es '101-127', muestra a todos los conductores
        final grupo = (c['grupo'] ?? '101-127').toString();
        if (widget.grupo != '101-127' && grupo != widget.grupo) return false;

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

      // Orden alfabético estricto según el apellido paterno
      filtrados.sort((a, b) {
        final estadoA = (a['estado'] ?? 'activo').toString().toLowerCase() == 'activo' ? 0 : 1;
        final estadoB = (b['estado'] ?? 'activo').toString().toLowerCase() == 'activo' ? 0 : 1;
        if (estadoA != estadoB) return estadoA.compareTo(estadoB);

        final apA = Normalizadores.extraerApellidoPaterno(a['nombre']?.toString()).toLowerCase();
        final apB = Normalizadores.extraerApellidoPaterno(b['nombre']?.toString()).toLowerCase();
        final comp = apA.compareTo(apB);
        if (comp != 0) return comp;

        return (a['nombre'] ?? '').toString().toLowerCase().compareTo((b['nombre'] ?? '').toString().toLowerCase());
      });

      _conductoresFiltrados = filtrados;
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
  // BOTÓN PARA ALTERNAR MODO DE VISTA (COLUMNAS <-> CUADRADOS)
  // ---------------------------------------------------------------------------
  Widget _buildBotonAlternarVista() {
    return Tooltip(
      message: _esVistaCuadricula
          ? 'Ver en columnas (lista)'
          : 'Ver en cuadrados (cuadrícula)',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              _esVistaCuadricula = !_esVistaCuadricula;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: Icon(
                _esVistaCuadricula
                    ? Icons.format_list_bulleted_rounded
                    : Icons.tune_rounded,
                key: ValueKey<bool>(_esVistaCuadricula),
                size: 22,
                color: _kVerdeOscuro,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Encabezado verde curvo corporativo con título del grupo, logo,
  /// buscador y botón de alternar vista integrados (estilo Our Services).
  Widget _buildHeader(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Volver',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                // Título dinámico según el grupo que estamos (e.g. Grupo Continental 101 o 127)
                Expanded(
                  child: Text(
                    'Grupo Continental ${widget.grupo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                // Logo Continental en círculo blanco como en la imagen
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_taxi_rounded,
                        color: _kVerdeOscuro,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Buscador y botón de alternar vista DENTRO del encabezado verde
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, CI o placa...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filtrar('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _filtrar,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildBotonAlternarVista(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONSTRUCCIÓN PRINCIPAL (COLUMNAS / CUADRADOS CON COMPONENTES MODULARES)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Métricas del grupo asignado a esta pantalla (101-127)
    final conductoresDelGrupo = widget.grupo == '101-127'
        ? _conductores
        : _conductores
            .where((c) => (c['grupo'] ?? '101-127').toString() == widget.grupo)
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Encabezado verde curvo corporativo con título y buscador integrado
          _buildHeader(context),

          const SizedBox(height: 12),

          // 2. Sub-filtros rápidos dentro del grupo (Todos, Activos, Alertas)
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

          const SizedBox(height: 10),

          // 4. VISTA EN COLUMNAS (LISTA) O EN CUADRADOS (GRID) CON NÚMERO DE LISTA
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : _conductoresFiltrados.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_taxi_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
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
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: _kVerdeOscuro,
                        onRefresh: _cargarConductores,
                        child: _esVistaCuadricula
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  90,
                                ),
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
                                    numeroLista: index + 1,
                                    modoLista: false,
                                    onTap: () =>
                                        _mostrarFichaDetalleConductor(c),
                                    onTapVer: () =>
                                        _mostrarFichaDetalleConductor(c),
                                    onTapEditar: () =>
                                        _abrirFormularioConductor(
                                      conductorExistente: c,
                                    ),
                                    onTapCambiarEstado: () => esActivo
                                        ? _confirmarBajaConductor(c)
                                        : _confirmarReactivacionConductor(c),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  90,
                                ),
                                itemCount: _conductoresFiltrados.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final c = _conductoresFiltrados[index];
                                  final esActivo = (c['estado'] ?? 'activo')
                                          .toString()
                                          .toLowerCase() ==
                                      'activo';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ConductorCard(
                                      conductor: c,
                                      numeroLista: index + 1,
                                      modoLista: true,
                                      onTap: () =>
                                          _mostrarFichaDetalleConductor(c),
                                      onTapVer: () =>
                                          _mostrarFichaDetalleConductor(c),
                                      onTapEditar: () =>
                                          _abrirFormularioConductor(
                                        conductorExistente: c,
                                      ),
                                      onTapCambiarEstado: () => esActivo
                                          ? _confirmarBajaConductor(c)
                                          : _confirmarReactivacionConductor(c),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kVerdeOscuro,
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
