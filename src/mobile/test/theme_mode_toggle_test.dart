import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_utils.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'the app bar theme toggle cycles system -> light -> dark -> system, '
    'updating the app brightness and persisting the choice',
    (tester) async {
      await tester.pumpWidget(appWithCompletedOnboarding());
      await tester.pumpAndSettle();

      final toggle = find.byTooltip('Tema: automático (sigue el sistema)');
      expect(toggle, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tema: claro'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light,
      );

      await tester.tap(find.byTooltip('Tema: claro'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tema: oscuro'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');

      await tester.tap(find.byTooltip('Tema: oscuro'));
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Tema: automático (sigue el sistema)'),
        findsOneWidget,
      );
    },
  );
}
