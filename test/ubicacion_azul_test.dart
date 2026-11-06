import 'package:continental/widgets/ubicacion_azul.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UbicacionAzul dibuja el cono y la flecha sin errores', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: UbicacionAzul(rumboGrados: 90))),
      ),
    );

    expect(find.byType(UbicacionAzul), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);

    // Simula el cambio de rumbo para comprobar que se actualiza.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: UbicacionAzul(rumboGrados: 270))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
