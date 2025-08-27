// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/routes.dart';

void main() {
  testWidgets('App boots to Main screen', (tester) async {
    await tester.pumpWidget(const GabAndGoApp(initialRoute: Routes.main));
    await tester.pumpAndSettle();

    expect(find.text('Gab & Go'), findsOneWidget);
  });
}
