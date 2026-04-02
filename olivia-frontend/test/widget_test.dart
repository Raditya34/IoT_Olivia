import 'package:flutter_test/flutter_test.dart';
import 'package:iot_olivia/main.dart';

void main() {
  testWidgets("App loads properly", (tester) async {
    await tester.pumpWidget(const OliviaApp());
    expect(find.text("IoT Olivia Dashboard"), findsOneWidget);
  });
}
