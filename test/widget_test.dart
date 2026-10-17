import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:talaria/core/theme/app_colors.dart';
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

  testWidgets('Navigation bar destination switching smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TalariaApp(),
      ),
    );

    // Tap on Sessions destination
    await tester.tap(find.byIcon(LucideIcons.layers));
    await tester.pumpAndSettle();
    expect(find.text('TALARIA / SESSIONS'), findsOneWidget);

    // Tap on Projects destination
    await tester.tap(find.byIcon(LucideIcons.folderKanban));
    await tester.pumpAndSettle();
    expect(find.text('TALARIA / PROJECTS'), findsOneWidget);

    // Tap on Settings destination
    await tester.tap(find.byIcon(LucideIcons.settings));
    await tester.pumpAndSettle();
    expect(find.text('TALARIA / SETTINGS'), findsOneWidget);
  });

  test('Design system color tokens verification', () {
    expect(AppColors.background.value, 0xFF080C14);
    expect(AppColors.surface.value, 0xFF0F172A);
    expect(AppColors.primary.value, 0xFF00E5FF);
    expect(AppColors.thinking.value, 0xFF38BDF8);
    expect(AppColors.ok.value, 0xFF10B981);
    expect(AppColors.error.value, 0xFFF43F5E);
  });
}
