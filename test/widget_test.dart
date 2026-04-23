import 'package:flutter_test/flutter_test.dart';
import 'package:sprachcaffe_mobile1/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SprachcaffeApp());

    expect(find.text('Sprachcaffe'), findsOneWidget);
  });
}