import 'package:flutter/material.dart';

class SancionesScreen extends StatefulWidget {
  const SancionesScreen({super.key});

  @override
  State<SancionesScreen> createState() => _SancionesScreenState();
}

class _SancionesScreenState extends State<SancionesScreen> {
  int _selectedTab = 0; // 0: Todas, 1: Pendientes, 2: Pagadas

  final List<Map<String, dynamic>> _sanciones = [
    {'driver': 'Juan Pérez', 'ci': '12345678', 'unit': '115', 'status': 'Pendiente', 'date': '17/09/2026', 'reason': 'tardanza', 'time': '07:42', 'laps': 3},
    {'driver': 'Carlos López', 'ci': '87654321', 'unit': '108', 'status': 'En proceso', 'date': '16/09/2026', 'reason': 'falta a reunión', 'time': '10:15', 'laps': 1},
  ];

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
        title: const Text('Sanciones', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        actions: [
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                  hintText: 'Buscar conductor...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab('Todas', 0),
                _buildTab('Pendientes', 1),
                _buildTab('Pagadas', 2),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _sanciones.length,
              itemBuilder: (context, index) {
                final s = _sanciones[index];
                final isPending = s['status'] == 'Pendiente';
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.person, color: Color(0xFF3B82F6)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['driver'], style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('CI: ${s['ci']} • Trufi ${s['unit']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            const SizedBox(height: 8),
                            Text('Motivo: ${s['reason']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            Text('Hora: ${s['time']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            Text('Vueltas adicionales: ${s['laps']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(isPending ? Icons.warning_amber_rounded : Icons.access_time_filled, 
                                     color: isPending ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), size: 12),
                                const SizedBox(width: 4),
                                Text(s['status'], style: TextStyle(
                                  color: isPending ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                  fontSize: 10, fontWeight: FontWeight.bold
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(s['date'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Registrar sanción', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

