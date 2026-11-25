// HopAlong smoke test: the welcome screen renders in demo mode.
import 'package:flutter_test/flutter_test.dart';
import 'package:hopalong/app_state.dart';
import 'package:hopalong/main.dart';

void main() {
  testWidgets('Welcome screen shows HopAlong and both modes',
      (WidgetTester tester) async {
    final state = AppState.create();
    await tester.pumpWidget(HopAlongApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('HopAlong'), findsWidgets);
    expect(find.text('Find a ride'), findsOneWidget);
    expect(find.text('Offer a ride'), findsOneWidget);
  });
}
