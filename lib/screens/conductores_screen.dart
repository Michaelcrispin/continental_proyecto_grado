import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';

class ConductoresScreen extends StatefulWidget {
  const ConductoresScreen({super.key});

  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _conductoresFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(context, SesionService.instance.rol, Permisos.moduloConductores)) {
        return;
      }
    });
    _cargarConductores();
  }

  Future<void> _cargarConductores() async {
    setState(() => _isLoading = true);
    try {
      final lista = await DatabaseHelper.instance.conductoresConAuto();
      if (mounted) {
        setState(() {
          _conductores = lista;
          _conductoresFiltrados = lista;
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
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _conductoresFiltrados = _conductores;
      } else {
        _conductoresFiltrados = _conductores.where((c) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final ci = (c['ci'] ?? '').toString().toLowerCase();
          final placa = (c['placa'] ?? '').toString().toLowerCase();
          return nombre.contains(q) || ci.contains(q) || placa.contains(q);
        }).toList();
      }
    });
  }

  void _mostrarDialogoNuevoConductor() {
    final nombreCtrl = TextEditingController();
    final ciCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final licenciaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuevo Conductor', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo', hintText: 'Ej. Juan Pérez'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ciCtrl,
                decoration: const InputDecoration(labelText: 'Cédula de Identidad (CI)', hintText: 'Ej. 1234567'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña de acceso', hintText: 'Mínimo 4 caracteres'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: licenciaCtrl,
                decoration: const InputDecoration(labelText: 'Licencia (opcional)', hintText: 'Ej. Cat. C'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              final ci = ciCtrl.text.trim();
              final pass = passCtrl.text.trim();
              if (nombre.isEmpty || ci.isEmpty || pass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor llena nombre, CI y contraseña')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await DatabaseHelper.instance.registrarConductor(
                  nombre: nombre,
                  password: pass,
                  ci: ci,
                  licencia: licenciaCtrl.text.trim().isEmpty ? null : licenciaCtrl.text.trim(),
                  fechaIncorporacion: DateTime.now().toIso8601String().substring(0, 10),
                );
                _cargarConductores();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conductor registrado con éxito')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al registrar: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Conductores', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _cargarConductores,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filtrar,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                  hintText: 'Buscar conductor por nombre, CI o placa...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conductoresFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No hay conductores registrados en la base de datos',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Usa el botón "Agregar conductor" para registrar el primero.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarConductores,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _conductoresFiltrados.length,
                          itemBuilder: (context, index) {
                            final c = _conductoresFiltrados[index];
                            final nombre = c['nombre'] ?? 'Sin nombre';
                            final ci = c['ci'] ?? 'S/CI';
                            final placa = c['placa'] ?? 'Sin auto asignado';
                            final estado = c['estado'] ?? 'activo';
                            final esActivo = estado.toString().toLowerCase() == 'activo';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFEFF6FF),
                                    child: Icon(Icons.person, color: Color(0xFF3B82F6)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(nombre, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text('CI: $ci • Auto: $placa', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: esActivo ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          esActivo ? Icons.check_circle_outline : Icons.cancel_outlined, 
                                          color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
                                          size: 14
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          estado.toString().toUpperCase(), 
                                          style: TextStyle(
                                            color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
                                            fontSize: 11, 
                                            fontWeight: FontWeight.bold
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _mostrarDialogoNuevoConductor,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar conductor', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
