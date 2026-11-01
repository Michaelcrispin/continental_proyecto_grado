import 'package:flutter/material.dart';
import '../../../services/gps_service.dart';

/// Tarjeta de configuración para el Punto de Parada A (Cruce Villadela)
/// y Punto de Parada B (Teleférico Amarillo), exclusiva para Superadmin.
/// Soporta radios ultra-cortos (desde 1m / 2m) y monitoreo de distancia en vivo.
class ParadaConfigCard extends StatelessWidget {
  final bool esParadaA;
  final TextEditingController nombreCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  final double radioM;
  final double? distanciaActualM;
  final bool guardando;
  final ValueChanged<double> onRadioChanged;
  final VoidCallback onCoordManualSubmit;
  final VoidCallback onCapturarGps;
  final VoidCallback onRestablecerOficial;
  final VoidCallback onGuardar;

  const ParadaConfigCard({
    super.key,
    required this.esParadaA,
    required this.nombreCtrl,
    required this.latCtrl,
    required this.lonCtrl,
    required this.radioM,
    this.distanciaActualM,
    required this.guardando,
    required this.onRadioChanged,
    required this.onCoordManualSubmit,
    required this.onCapturarGps,
    required this.onRestablecerOficial,
    required this.onGuardar,
  });

  static const List<int> _radiosRapidos = [2, 3, 5, 10, 50, 100];

  @override
  Widget build(BuildContext context) {
    final colorPrimario = esParadaA ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final letraParada = esParadaA ? 'A' : 'B';
    final dentroAhora = distanciaActualM != null && distanciaActualM! <= radioM;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador en vivo de distancia al punto configurado
          if (distanciaActualM != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: dentroAhora ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dentroAhora ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    dentroAhora ? Icons.check_circle : Icons.directions_walk,
                    size: 16,
                    color: dentroAhora ? const Color(0xFF10B981) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dentroAhora
                          ? 'DENTRO DEL PUNTO $letraParada • Tu distancia: ${GpsService.formatearDistancia(distanciaActualM)} (Radio: ${radioM.toInt()} m)'
                          : 'FUERA DEL PUNTO $letraParada • Tu distancia: ${GpsService.formatearDistancia(distanciaActualM)} (Radio: ${radioM.toInt()} m)',
                      style: TextStyle(
                        color: dentroAhora ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Nombre y Coordenadas con 7 decimales (precisión centimétrica)
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildCompactField(
                  controller: nombreCtrl,
                  label: 'Parada $letraParada',
                  icon: Icons.place_outlined,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _buildCompactField(
                  controller: latCtrl,
                  label: 'Latitud',
                  icon: Icons.north_east,
                  isNumber: true,
                  onSubmitted: (_) => onCoordManualSubmit(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _buildCompactField(
                  controller: lonCtrl,
                  label: 'Longitud',
                  icon: Icons.east,
                  isNumber: true,
                  onSubmitted: (_) => onCoordManualSubmit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Botones de captura de ubicación exacta (0.0 m) y restaurar oficial
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCapturarGps,
                  icon: const Icon(Icons.my_location, size: 16, color: Colors.white),
                  label: const Text(
                    'Fijar Parada Aquí (Mi GPS 0.0m)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onRestablecerOficial,
                icon: const Icon(Icons.restore, size: 15, color: Color(0xFF64748B)),
                label: const Text(
                  'Oficial',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Botones rápidos de Radio (2m, 3m, 5m, 10m, 50m, 100m)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Radio de Geocerca:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              Row(
                children: _radiosRapidos.map((r) {
                  final activo = radioM.round() == r;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => onRadioChanged(r.toDouble()),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: activo ? colorPrimario : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: activo ? colorPrimario : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          '${r}m',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: activo ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Deslizador fino desde 1 metro hasta 200 metros
          Row(
            children: [
              const Text('1m', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: radioM.clamp(1.0, 200.0),
                    min: 1.0,
                    max: 200.0,
                    divisions: 199,
                    activeColor: colorPrimario,
                    onChanged: onRadioChanged,
                  ),
                ),
              ),
              Text(
                '${radioM.toInt()} m',
                style: TextStyle(fontSize: 11, color: colorPrimario, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: guardando ? null : onGuardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F265C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: guardando
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, color: Colors.white, size: 17),
              label: Text(
                guardando
                    ? 'Guardando...'
                    : 'Guardar Parada $letraParada (Radio: ${radioM.toInt()} m)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(signed: true, decimal: true)
          : TextInputType.text,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, size: 13, color: const Color(0xFF64748B)),
        prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 0),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
