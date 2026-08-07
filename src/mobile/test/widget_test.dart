import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('App boots and shows the lesson list', (WidgetTester tester) async {
    await tester.pumpWidget(appWithCompletedOnboarding());
    await tester.pumpAndSettle();

    expect(find.text('Inglés · A1'), findsOneWidget);
    expect(find.text('Saludos y presentaciones'), findsOneWidget);
  });
}
