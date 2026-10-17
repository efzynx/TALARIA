import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/main.dart';
import 'package:talaria/presentation/widgets/connection_pill.dart';

void main() {
  testWidgets('Talaria App initial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TalariaApp(),
      ),
    );

    // Initial check: app title should exist
    expect(find.text('TALARIA / CHAT'), findsOneWidget);
    // Connection pill should be rendered
    expect(find.byType(ConnectionPill), findsOneWidget);
    // Welcome message should be visible in chat
    expect(
      find.text('Talaria remote client ready. Connect to hermes serve daemon to initiate agent sessions.'),
      findsOneWidget,
    );
  });
}
