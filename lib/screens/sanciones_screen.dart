import 'package:flutter/material.dart';

import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';
import '../widgets/informe_sanciones_whatsapp_dialog.dart';
import 'cuotas/widgets/dialogo_informe_whatsapp.dart';

import 'home_screen.dart';

// ---------- Paleta Corporativa Sindicato Continental ----------
const _kVerdeContinental = Color(0xFF02634C);
const _kVerdeClaro = Color(0xFFE6F4F0);
const _kVerdeActivo = Color(0xFF10B981);
const _kAmbar = Color(0xFFD97706);
const _kAmbarClaro = Color(0xFFFEF3C7);
const _kRojo = Color(0xFFEF4444);
const _kSlate = Color(0xFF64748B);
const _kTexto = Color(0xFF0F172A);
const _kFondo = Color(0xFFF8FAFC);
const _kBorde = Color(0xFFE2E8F0);

/// Control de Sanciones Automáticas por Tardanza (HU05 | RF11-RF12).
///
/// Todo se alimenta de SQLite:
/// - `sancion` + `conductor` + `asistencia` + `punto_de_control` + `automovil`.
/// - El rol `conductor` solo ve sus propias sanciones.
/// - Admin / superadmin / supervisor pueden registrar vueltas de castigo.
/// - Al completar las vueltas asignadas la sanción se cierra automáticamente.
class SancionesScreen extends StatefulWidget {
  const SancionesScreen({super.key});

  @override
  State<SancionesScreen> createState() => _SancionesScreenState();
}

class _SancionesScreenState extends State<SancionesScreen> {
  List<Map<String, dynamic>> _sanciones = [];
  String _filtro = 'todas'; // 'todas' | 'en_curso' | 'cumplidas'
  String? _horaLimite;
  String? _error;
  bool _cargando = true;
  bool _puedeEditar = false;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloSanciones,
    );
    _cargar();
  }

  // ---------------------------------------------------------------------------
  // Datos
  // ---------------------------------------------------------------------------
  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final sesion = SesionService.instance;
      final idPropio = sesion.esConductor ? sesion.idConductor : null;

      if (sesion.esConductor && (idPropio == null || idPropio.isEmpty)) {
        if (!mounted) return;
        setState(() {
          _sanciones = [];
          _horaLimite = null;
          _cargando = false;
        });
        return;
      }

      await DatabaseHelper.instance.sincronizarHorariosSanciones();
      final lista = await DatabaseHelper.instance.sancionesDetalle(
        idConductor: idPropio,
      );
      final horario = await DatabaseHelper.instance.obtenerHorarioActivo();

      if (!mounted) return;
      setState(() {
        _sanciones = lista;
        _horaLimite = horario == null ? null : _formatearLimite(horario);
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las sanciones.\n$e';
      });
    }
  }

  String _formatearLimite(Map<String, dynamic> horario) {
    final entrada = horario['hora_entrada']?.toString() ?? '07:30';
    final tolerancia = (horario['tolerancia_min'] as num?)?.toInt() ?? 30;
    final partes = entrada.split(':');
    final hora = int.tryParse(partes.first) ?? 7;
    final minuto = int.tryParse(partes.length > 1 ? partes[1] : '0') ?? 0;
    final total = (hora * 60 + minuto + tolerancia) % (24 * 60);
    final hh = total ~/ 60;
    final mm = total % 60;
    final sufijo = hh >= 12 ? 'PM' : 'AM';
    final h12 = hh % 12 == 0 ? 12 : hh % 12;
    return '${h12.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')} $sufijo';
  }

  bool _esCumplida(Map<String, dynamic> s) {
    if (s['estado']?.toString().toLowerCase() == 'cumplida') return true;
    final asignadas = (s['vueltas_asignadas'] as num?)?.toInt() ?? 0;
    final cumplidas = (s['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
    return asignadas > 0 && cumplidas >= asignadas;
  }

  List<Map<String, dynamic>> get _filtradas {
    switch (_filtro) {
      case 'en_curso':
        return _sanciones.where((s) => !_esCumplida(s)).toList();
      case 'cumplidas':
        return _sanciones.where(_esCumplida).toList();
      default:
        final lista = List<Map<String, dynamic>>.from(_sanciones);
        lista.sort((a, b) {
          final aCumplida = _esCumplida(a);
          final bCumplida = _esCumplida(b);
          if (aCumplida != bCumplida) {
            return aCumplida ? 1 : -1;
          }
          return 0;
        });
        return lista;
    }
  }

  int get _enCurso => _sanciones.where((s) => !_esCumplida(s)).length;
  int get _cumplidas => _sanciones.where(_esCumplida).length;

  Future<void> _registrarVuelta(Map<String, dynamic> sancion) async {
    if (_registrando || !_puedeEditar) return;

    final asignadas = (sancion['vueltas_asignadas'] as num?)?.toInt() ?? 0;
    final cumplidas = (sancion['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
    final nombre = sancion['conductor_nombre']?.toString() ?? 'el conductor';
    final faltan = asignadas - cumplidas;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: _kVerdeContinental),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Registrar vuelta de castigo',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Confirmas que $nombre completó 1 vuelta de sanción?\n\n'
          'Progreso actual: $cumplidas de $asignadas. '
          '${faltan <= 1 ? 'Esta vuelta cerraría la sanción.' : 'Quedarían ${faltan - 1} pendientes.'}',
          style: const TextStyle(color: _kSlate, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _kSlate, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Sí, registrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeContinental,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _registrando = true);
    try {
      final actualizada = await DatabaseHelper.instance.registrarVueltaSancion(
        sancion['id_sancion'].toString(),
      );
      await _cargar();
      if (!mounted) return;

      final cerrada = actualizada['estado']?.toString() == 'cumplida';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cerrada ? _kVerdeContinental : const Color(0xFF0F172A),
          content: Row(
            children: [
              Icon(
                cerrada ? Icons.verified_rounded : Icons.add_task_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cerrada
                      ? 'Sanción cerrada: $nombre completó las $asignadas vueltas.'
                      : 'Vuelta registrada para $nombre.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kRojo,
          content: Text('No se pudo registrar la vuelta: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Interfaz
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: _kVerdeContinental,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          children: [
            _encabezado(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kpis(),
                  const SizedBox(height: 14),
                  _botonWhatsappDirectiva(),
                  const SizedBox(height: 14),
                  _filtros(),
                  const SizedBox(height: 14),
                  _contenido(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeContinental,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3302634C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Volver',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Control de Sanciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Color(0xFFE6F4F0),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _horaLimite == null
                              ? 'Llegadas > 08:00 AM generan +2 vueltas'
                              : 'Llegadas > $_horaLimite generan +2 vueltas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _cargando ? null : _cargar,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: _kVerdeContinental,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpis() {
    return Row(
      children: [
        _kpiCard(
          icono: Icons.gavel_rounded,
          color: _kVerdeContinental,
          fondo: _kVerdeClaro,
          valor: '${_sanciones.length}',
          etiqueta: 'Registradas',
          tipo: 'todas',
        ),
        const SizedBox(width: 8),
        _kpiCard(
          icono: Icons.access_time_filled_rounded,
          color: _kAmbar,
          fondo: _kAmbarClaro,
          valor: '$_enCurso',
          etiqueta: 'En curso',
          tipo: 'en_curso',
        ),
        const SizedBox(width: 8),
        _kpiCard(
          icono: Icons.check_circle_rounded,
          color: _kVerdeActivo,
          fondo: const Color(0xFFD1FAE5),
          valor: '$_cumplidas',
          etiqueta: 'Cumplidas',
          tipo: 'cumplidas',
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icono,
    required Color color,
    required Color fondo,
    required String valor,
    required String etiqueta,
    required String tipo,
  }) {
    final isSelected = _filtro == tipo;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filtro = _filtro == tipo ? 'todas' : tipo;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: fondo.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.25),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                valor,
                style: const TextStyle(
                  color: _kTexto,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                etiqueta,
                style: TextStyle(
                  color: isSelected ? color : _kSlate,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonWhatsappDirectiva() {
    final limite = _horaLimite ?? '08:00 AM';
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => InformeSancionesWhatsappDialog.mostrar(
              context,
              sanciones: _sanciones,
              horaLimite: limite,
            ),
            icon: const Icon(Icons.chat_rounded, size: 17, color: Colors.white),
            label: const Text(
              'Informe Directiva WhatsApp',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final msg = InformeSancionesWhatsappDialog.construirTextoInforme(
              sanciones: _sanciones,
              horaLimite: limite,
            );
            await DialogoInformeWhatsapp.lanzarWhatsappDirecto(
              context,
              texto: msg,
            );
          },
          icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF16A34A)),
          label: const Text(
            'Enviar',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF16A34A), width: 1.3),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filtros() {
    final filtros = <(String, String, int)>[
      ('todas', 'Todas', _sanciones.length),
      ('en_curso', 'En curso', _enCurso),
      ('cumplidas', 'Cumplidas', _cumplidas),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final (clave, etiqueta, cantidad) in filtros) ...[
            _chipFiltro(clave, '$etiqueta ($cantidad)'),
            if (clave != filtros.last.$1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chipFiltro(String clave, String etiqueta) {
    final activo = _filtro == clave;
    return GestureDetector(
      onTap: () => setState(() => _filtro = clave),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? _kVerdeContinental : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? _kVerdeContinental : _kBorde,
            width: activo ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: activo
                  ? const Color(0x3302634C)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            color: activo ? Colors.white : _kTexto,
            fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: _kVerdeContinental),
        ),
      );
    }
    if (_error != null) {
      return _estadoError();
    }
    final lista = _filtradas;
    if (lista.isEmpty) {
      return _estadoVacio();
    }
    return Column(
      children: [for (final s in lista) _tarjetaSancion(s)],
    );
  }

  Widget _estadoError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: _kRojo, size: 38),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kSlate, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kVerdeContinental,
              side: const BorderSide(color: _kVerdeContinental),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoVacio() {
    final mensaje = switch (_filtro) {
      'en_curso' => 'No hay sanciones pendientes de cumplir.',
      'cumplidas' => 'Todavía no se cerró ninguna sanción.',
      _ => 'No hay sanciones registradas.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorde),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: _kVerdeClaro,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: _kVerdeContinental,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kTexto,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Las sanciones aparecen aquí en cuanto un conductor marca '
            'asistencia después de la hora límite.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kSlate, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaSancion(Map<String, dynamic> s) {
    final asignadas = (s['vueltas_asignadas'] as num?)?.toInt() ?? 0;
    final cumplidas = (s['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
    final faltan = (asignadas - cumplidas).clamp(0, asignadas);
    final cumplida = _esCumplida(s);
    final progreso = asignadas <= 0
        ? 0.0
        : (cumplidas / asignadas).clamp(0.0, 1.0).toDouble();

    final nombre = s['conductor_nombre']?.toString() ?? 'Conductor';
    final foto = s['conductor_foto']?.toString();
    final unidad = s['numero_interno']?.toString();
    final punto = s['punto_nombre']?.toString();
    final motivo = s['motivo']?.toString() ?? '';
    final llegada = (s['hora_llegada'] ?? s['hora'] ?? '--:--').toString();
    final retraso = (s['minutos_retraso'] as num?)?.toInt() ?? 0;
    final fecha = _fechaBonita(s['fecha']?.toString());

    final subtitulo = <String>[
      if (unidad != null && unidad.isNotEmpty) 'Unidad $unidad',
      if (punto != null && punto.isNotEmpty) punto,
    ].join('  •  ');

    if (cumplida) {
      final resumenCompacto = <String>[
        if (unidad != null && unidad.isNotEmpty) 'Unidad $unidad',
        'Llegó: $llegada',
        '$cumplidas/$asignadas vueltas',
      ].join('  •  ');

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 3, color: _kVerdeActivo),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    AvatarConductor(
                      foto: foto,
                      nombre: nombre,
                      radio: 19,
                      fontSize: 11,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTexto,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            resumenCompacto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kSlate,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF02634C),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'CUMPLIDA',
                            style: TextStyle(
                              color: Color(0xFF02634C),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final colorEstado = cumplida ? _kVerdeActivo : _kRojo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(height: 3.5, color: colorEstado),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarConductor(
                        foto: foto,
                        nombre: nombre,
                        radio: 23,
                        fontSize: 12.5,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kTexto,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                            if (subtitulo.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _kSlate,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _chipEstado(cumplida),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _cajaHorarios(llegada: llegada, retraso: retraso),
                  if (motivo.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 15, color: _kSlate),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            motivo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kSlate,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Progreso de la sanción',
                        style: TextStyle(
                          color: _kTexto,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$cumplidas de $asignadas vueltas',
                        style: TextStyle(
                          color: cumplida ? _kVerdeContinental : _kAmbar,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEEF2F7),
                      color: cumplida ? _kVerdeActivo : _kVerdeContinental,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        cumplida
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_bottom_rounded,
                        size: 14,
                        color: cumplida ? _kVerdeActivo : _kAmbar,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          cumplida
                              ? 'Sanción cerrada • meta completada'
                              : 'Cierre bloqueado • faltan $faltan vuelta(s)',
                          style: TextStyle(
                            color: cumplida
                                ? const Color(0xFF065F46)
                                : const Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _miniChip(fecha, _kSlate),
                      const SizedBox(width: 6),
                      _miniChip(
                        _etiquetaOrigen(s['origen']?.toString()),
                        _kSlate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _accion(s, cumplida: cumplida, faltan: faltan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipEstado(bool cumplida) {
    final color = cumplida ? const Color(0xFF02634C) : const Color(0xFFDC2626);
    final bg = cumplida ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final border = cumplida ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        cumplida ? 'CUMPLIDA' : 'EN CURSO',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _cajaHorarios({required String llegada, required int retraso}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorde),
      ),
      child: Row(
        children: [
          Expanded(
            child: _datoHorario(
              icono: Icons.alarm_rounded,
              etiqueta: 'Límite',
              valor: _horaLimite ?? '08:00 AM',
              color: _kSlate,
            ),
          ),
          Container(width: 1, height: 30, color: _kBorde),
          Expanded(
            child: _datoHorario(
              icono: Icons.schedule_rounded,
              etiqueta: 'Llegó:',
              valor: retraso > 0 ? '$llegada  (+$retraso min)' : llegada,
              color: retraso > 0 ? _kRojo : _kVerdeActivo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoHorario({
    required IconData icono,
    required String etiqueta,
    required String valor,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              etiqueta,
              style: const TextStyle(
                color: _kSlate,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _miniChip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _accion(
    Map<String, dynamic> sancion, {
    required bool cumplida,
    required int faltan,
  }) {
    if (cumplida) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF02634C), size: 19),
            SizedBox(width: 7),
            Text(
              'Sanción cumplida y cerrada',
              style: TextStyle(
                color: Color(0xFF02634C),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    if (!_puedeEditar) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFB45309), size: 18),
            const SizedBox(width: 7),
            Text(
              'Debes completar $faltan vuelta(s) de castigo',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _registrando ? null : () => _registrarVuelta(sancion),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kVerdeContinental,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kSlate,
          disabledForegroundColor: Colors.white70,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_registrando)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.add_task_rounded,
                size: 18,
                color: Colors.white,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Registrar vuelta (faltan $faltan)',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: _kVerdeContinental,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _etiquetaOrigen(String? origen) {
    switch (origen) {
      case 'tardanza_auto':
        return 'Automática';
      case 'manual':
        return 'Manual';
      case 'demo_castigo':
      case 'simulado':
        return 'Simulación';
      default:
        return 'Origen desconocido';
    }
  }

  String _fechaBonita(String? iso) {
    if (iso == null || iso.isEmpty) return '--/--/----';
    final partes = iso.split('-');
    if (partes.length != 3) return iso;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }
}
