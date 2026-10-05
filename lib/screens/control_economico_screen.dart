import 'package:flutter/material.dart';

class ControlEconomicoScreen extends StatelessWidget {
  const ControlEconomicoScreen({super.key});

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
        title: const Text('Control económico', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        actions: [
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
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                              child: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text('Recaudación', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Bs. 2.450', style: TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text('Pagos pendientes', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Bs. 350', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Conceptos', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildConceptItem(Icons.savings_outlined, const Color(0xFF3B82F6), 'Cuota de ayuda'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 50),
                  _buildConceptItem(Icons.card_giftcard, const Color(0xFF10B981), 'Canastón de fin de año'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 50),
                  _buildConceptItem(Icons.warning_amber_rounded, const Color(0xFFF59E0B), 'Multas'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 50),
                  _buildConceptItem(Icons.person_off_outlined, const Color(0xFF3B82F6), 'Faltas a reuniones'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 50),
                  _buildConceptItem(Icons.assignment_outlined, const Color(0xFF3B82F6), 'Pasanaco'),
                ],
              ),
            ),
          ],
        ),
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
              icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
              label: const Text('Registrar pago', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConceptItem(IconData icon, Color iconColor, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: () {},
    );
  }
}
