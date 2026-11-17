import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webspark_pathfinder/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen renders and validates invalid URL', (tester) async {
    await tester.pumpWidget(const WebsparkApp());
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
    expect(find.text('Set valid API base URL in order to continue'), findsOneWidget);
    expect(find.text('Start counting process'), findsOneWidget);

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'invalid-url');
    await tester.tap(find.text('Start counting process'));
    await tester.pump();

    expect(
      find.text('Please enter a valid HTTP or HTTPS URL'),
      findsOneWidget,
    );
  });
}
