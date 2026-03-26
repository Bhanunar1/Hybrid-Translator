import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_translator/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HybridTranslatorApp());
    expect(find.text('HYBRID TRANS'), findsOneWidget);
  });
}
