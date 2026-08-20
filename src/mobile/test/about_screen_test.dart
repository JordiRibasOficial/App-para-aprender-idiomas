import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/presentation/about_screen.dart';

void main() {
  testWidgets('shows the app name and version', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    expect(find.text('App para Aprender Idiomas'), findsOneWidget);
    expect(find.text('Versión 1.0.0'), findsOneWidget);
  });

  testWidgets('tapping the licenses tile opens the open-source license page', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    await tester.tap(find.text('Licencias de código abierto'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
