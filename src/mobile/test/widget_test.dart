import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/main.dart';

void main() {
  testWidgets('App boots and shows the lesson list', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Inglés · A1'), findsOneWidget);
    expect(find.text('Saludos y presentaciones'), findsOneWidget);
  });
}
