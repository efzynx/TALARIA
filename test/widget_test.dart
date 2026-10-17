import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/core/theme/app_colors.dart';
import 'package:talaria/main.dart';
import 'package:talaria/presentation/widgets/connection_pill.dart';

void main() {
  testWidgets('Talaria App initial smoke test', (WidgetTester tester) async {
    // Force mobile layout (< 720px wide)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: TalariaApp(),
      ),
    );
    await tester.pump();

    // Connection pill exists somewhere in the tree
    expect(find.byType(ConnectionPill), findsWidgets);
    // Scaffold (app shell) renders
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('Navigation bar destination switching smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: TalariaApp(),
      ),
    );
    await tester.pump();

    // Mobile bottom nav: 'Chat', 'Sessions', 'Settings' labels exist
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap on Sessions, then back to Chat
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    // Still in the app tree
    expect(find.byType(Scaffold), findsWidgets);
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
