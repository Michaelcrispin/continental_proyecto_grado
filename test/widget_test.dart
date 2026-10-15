import 'package:flutter_test/flutter_test.dart';
import 'package:continental/main.dart';

void main() {
  testWidgets('Continental app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
