import 'package:flutter_test/flutter_test.dart';
import 'package:sharqi/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SelfServiceApp());
    expect(find.byType(SelfServiceApp), findsOneWidget);
  });
}
