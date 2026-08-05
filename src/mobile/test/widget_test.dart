import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/main.dart';

void main() {
  testWidgets('App boots and shows the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
