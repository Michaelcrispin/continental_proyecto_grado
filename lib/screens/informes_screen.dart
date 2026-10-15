import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';

class InformesScreen extends StatefulWidget {
  const InformesScreen({super.key});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  DateTime _fecha = DateTime.now();
  bool _isLoading = true;
  int _asistenciasTotal = 0;
  int _vueltasTotal = 0;
  int _sancionesTotal = 0;
  double _cuotasMonto = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(context, SesionService.instance.rol, Permisos.moduloInformes)) {
        return;
      }
    });
    _generarInforme();
  }

  String get _fechaString => _fecha.toIso8601String().substring(0, 10);

  Future<void> _generarInforme() async {
    setState(() => _isLoading = true);
    try {
      final asistencias = await DatabaseHelper.instance.asistenciasDetalle(fecha: _fechaString);
      final vueltas = await DatabaseHelper.instance.vueltasDetalle(fecha: _fechaString);
      final sanciones = await DatabaseHelper.instance.listar('sancion', where: 'fecha = ?', whereArgs: [_fechaString]);
      final cuotas = await DatabaseHelper.instance.listar('cuota', where: 'fecha = ?', whereArgs: [_fechaString]);

      double totalCuotas = 0.0;
      for (final c in cuotas) {
        totalCuotas += (c['monto'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _asistenciasTotal = asistencias.length;
          _vueltasTotal = vueltas.length;
          _sancionesTotal = sanciones.length;
          _cuotasMonto = totalCuotas;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _fecha) {
      setState(() => _fecha = picked);
      _generarInforme();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaLabel = '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Informes', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _generarInforme,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona una fecha para el informe', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(fechaLabel, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500))),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generarInforme,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Actualizar informe', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Resumen del día seleccionado', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildSummaryItem(
                      Icons.groups, 
                      const Color(0xFF3B82F6), 
                      'Asistencia', 
                      '$_asistenciasTotal registros de asistencia'
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 50),
                    _buildSummaryItem(
                      Icons.route, 
                      const Color(0xFF10B981), 
                      'Vueltas', 
                      '$_vueltasTotal vueltas registradas'
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 50),
                    _buildSummaryItem(
                      Icons.warning_amber_rounded, 
                      const Color(0xFFEF4444), 
                      'Sanciones', 
                      '$_sancionesTotal sanciones registradas'
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 50),
                    _buildSummaryItem(
                      Icons.account_balance_wallet_outlined, 
                      const Color(0xFF3B82F6), 
                      'Cuotas / Aportes', 
                      'Bs. ${_cuotasMonto.toStringAsFixed(2)}'
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, Color iconColor, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
    );
  }
}
