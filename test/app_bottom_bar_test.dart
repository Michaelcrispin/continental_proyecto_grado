import 'package:continental/widgets/app_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(AppBottomTab tab, ValueChanged<AppBottomTab> onTap) {
    return MaterialApp(
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: AppBottomBar(
          currentTab: tab,
          onTabSelected: onTap,
        ),
      ),
    );
  }

  testWidgets('render all tabs and report tap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    AppBottomTab? tapped;
    for (final tab in AppBottomTab.values) {
      await tester.pumpWidget(wrap(tab, (t) => tapped = t));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sanciones'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Asistencias'), findsOneWidget);
      expect(find.text('Vueltas'), findsOneWidget);
      expect(find.text('Cuotas'), findsOneWidget);
    }

    await tester.pumpWidget(wrap(AppBottomTab.inicio, (t) => tapped = t));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuotas'));
    await tester.pump();
    expect(tapped, AppBottomTab.cuotas);
    await tester.binding.setSurfaceSize(null);
  });
}
