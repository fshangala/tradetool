import 'package:flutter_test/flutter_test.dart';
import 'package:tradetool/main.dart';

void main() {
  testWidgets('Settings page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BinanceTradeApp());

    // Verify that our settings page is displayed.
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Network Mode'), findsOneWidget);
  });
}
