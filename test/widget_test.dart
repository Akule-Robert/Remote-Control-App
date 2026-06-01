import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_tv_remote/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WifiTvRemoteApp());
    await tester.pump();
    expect(find.byType(WifiTvRemoteApp), findsOneWidget);
  });
}
