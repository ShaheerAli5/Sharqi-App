import 'package:flutter_test/flutter_test.dart';
import 'package:sharqi/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SelfServiceApp());
    expect(find.byType(SelfServiceApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
