import 'package:flutter/material.dart';
import 'asistencia_screen.dart';
import 'vueltas_screen.dart';
import 'sanciones_screen.dart';
import 'conductores_screen.dart';
import 'control_economico_screen.dart';
import 'informes_screen.dart';
import 'gps_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E3A8A)),
          onPressed: () {},
        ),
        title: Center(
          child: Image.asset('assets/images/logo.png', height: 40, errorBuilder: (c, e, s) => const Text('continental', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold))),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF1E3A8A)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.person, color: Color(0xFF3B82F6), size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hola, Encargado', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Grupo Continental Trufi 101 - 127', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Hoy, 17 de septiembre de 2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard(Icons.person, const Color(0xFF10B981), 'Asistencia', '38 / 40', 'conductores')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(Icons.route, const Color(0xFF3B82F6), 'Vueltas', '76', 'registradas')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(Icons.warning_amber_rounded, const Color(0xFFEF4444), 'Sanciones', '2', 'pendientes')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(Icons.account_balance_wallet, const Color(0xFF8B5CF6), 'Cuotas', 'Bs. 1.250', 'registradas')),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Accesos rápidos', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildQuickAccess(Icons.groups, 'Asistencia', const AsistenciaScreen()),
                _buildQuickAccess(Icons.route, 'Vueltas', const VueltasScreen()),
                _buildQuickAccess(Icons.warning_amber_rounded, 'Sanciones', const SancionesScreen()),
                _buildQuickAccess(Icons.person, 'Conductores', const ConductoresScreen()),
                _buildQuickAccess(Icons.account_balance_wallet, 'Económico', const ControlEconomicoScreen()),
                _buildQuickAccess(Icons.description, 'Informes', const InformesScreen()),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AsistenciaScreen()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VueltasScreen()));
            } else if (index == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GpsScreen())); // Placeholder
            } else if (index == 4) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: const Color(0xFF94A3B8),
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Asistencia'),
            BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Vueltas'),
            BottomNavigationBarItem(icon: Icon(Icons.gps_fixed), label: 'GPS'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Más'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color iconColor, String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 20, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(IconData icon, String title, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF3B82F6), size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
