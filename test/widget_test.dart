import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const VIOSAApp());
    expect(find.text('VIOSA'), findsOneWidget);
  });
}
