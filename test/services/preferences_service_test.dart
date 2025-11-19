// test/services/preferences_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legal_ai/core/services/preferences_service.dart';

void main() {
  group('PreferencesService Tests', () {
    late PreferencesService preferencesService;

    setUp(() async {
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
      preferencesService = PreferencesService();
      await preferencesService.init();
    });

    test('should return default theme mode when not set', () {
      expect(preferencesService.getThemeMode(), 'dark');
    });

    test('should save and retrieve theme mode', () async {
      await preferencesService.setThemeMode('light');
      expect(preferencesService.getThemeMode(), 'light');
    });

    test('should save and retrieve notifications preference', () async {
      await preferencesService.setNotificationsEnabled(false);
      expect(preferencesService.getNotificationsEnabled(), false);
    });

    test('should save and retrieve language preference', () async {
      await preferencesService.setLanguage('es');
      expect(preferencesService.getLanguage(), 'es');
    });

    test('should return default values when not set', () {
      expect(preferencesService.getNotificationsEnabled(), true);
      expect(preferencesService.getAutoSaveEnabled(), true);
      expect(preferencesService.getLanguage(), 'en');
    });

    test('should export all preferences correctly', () async {
      await preferencesService.setThemeMode('light');
      await preferencesService.setNotificationsEnabled(false);
      await preferencesService.setLanguage('fr');

      final exported = preferencesService.exportPreferences();

      expect(exported['theme_mode'], 'light');
      expect(exported['notifications_enabled'], false);
      expect(exported['language'], 'fr');
    });

    test('should clear all preferences', () async {
      await preferencesService.setThemeMode('light');
      await preferencesService.setNotificationsEnabled(false);

      await preferencesService.clearAll();

      // After clear, should return defaults
      expect(preferencesService.getThemeMode(), 'dark');
      expect(preferencesService.getNotificationsEnabled(), true);
    });
  });
}

// // test/bloc/preferences_bloc_test.dart
// import 'package:bloc_test/bloc_test.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:legal_ai/core/services/preferences_service.dart';
// import 'package:legal_ai/bloc/preferences/preferences_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// void main() {
//   group('PreferencesBloc Tests', () {
//     late PreferencesService preferencesService;
//     late PreferencesBloc preferencesBloc;
//
//     setUp(() async {
//       SharedPreferences.setMockInitialValues({});
//       preferencesService = PreferencesService();
//       await preferencesService.init();
//       preferencesBloc = PreferencesBloc(preferencesService);
//     });
//
//     tearDown(() {
//       preferencesBloc.close();
//     });
//
//     test('initial state is PreferencesInitial', () {
//       expect(preferencesBloc.state, PreferencesInitial());
//     });
//
//     blocTest<PreferencesBloc, PreferencesState>(
//       'emits PreferencesLoaded when LoadPreferences is added',
//       build: () => preferencesBloc,
//       act: (bloc) => bloc.add(LoadPreferences()),
//       expect: () => [
//         PreferencesLoading(),
//         isA<PreferencesLoaded>()
//             .having((s) => s.themeMode, 'themeMode', 'dark')
//             .having((s) => s.notificationsEnabled, 'notificationsEnabled', true)
//             .having((s) => s.language, 'language', 'en'),
//       ],
//     );
//
//     blocTest<PreferencesBloc, PreferencesState>(
//       'emits updated PreferencesLoaded when ChangeThemeMode is added',
//       build: () => preferencesBloc,
//       seed: () => const PreferencesLoaded(
//         themeMode: 'dark',
//         notificationsEnabled: true,
//         language: 'en',
//         autoSaveEnabled: true,
//       ),
//       act: (bloc) => bloc.add(const ChangeThemeMode('light')),
//       expect: () => [
//         isA<PreferencesLoaded>().having((s) => s.themeMode, 'themeMode', 'light'),
//       ],
//     );
//
//     blocTest<PreferencesBloc, PreferencesState>(
//       'emits updated PreferencesLoaded when ToggleNotifications is added',
//       build: () => preferencesBloc,
//       seed: () => const PreferencesLoaded(
//         themeMode: 'dark',
//         notificationsEnabled: true,
//         language: 'en',
//         autoSaveEnabled: true,
//       ),
//       act: (bloc) => bloc.add(const ToggleNotifications(false)),
//       expect: () => [
//         isA<PreferencesLoaded>()
//             .having((s) => s.notificationsEnabled, 'notificationsEnabled', false),
//       ],
//     );
//   });
// }
//
// // test/widgets/chat_bubble_test.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:legal_ai/widgets/chat_bubble.dart';
//
// void main() {
//   group('ChatBubble Widget Tests', () {
//     testWidgets('displays user message correctly', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         const MaterialApp(
//           home: Scaffold(
//             body: ChatBubble(
//               message: 'Hello, this is a test message',
//               isUser: true,
//             ),
//           ),
//         ),
//       );
//
//       expect(find.text('Hello, this is a test message'), findsOneWidget);
//       expect(find.byType(ChatBubble), findsOneWidget);
//     });
//
//     testWidgets('displays AI message correctly', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         const MaterialApp(
//           home: Scaffold(
//             body: ChatBubble(
//               message: 'AI response message',
//               isUser: false,
//             ),
//           ),
//         ),
//       );
//
//       expect(find.text('AI response message'), findsOneWidget);
//       expect(find.byType(ChatBubble), findsOneWidget);
//     });
//
//     testWidgets('aligns user message to the right', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         const MaterialApp(
//           home: Scaffold(
//             body: ChatBubble(
//               message: 'User message',
//               isUser: true,
//             ),
//           ),
//         ),
//       );
//
//       final alignWidget = tester.widget<Align>(find.byType(Align));
//       expect(alignWidget.alignment, Alignment.centerRight);
//     });
//
//     testWidgets('aligns AI message to the left', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         const MaterialApp(
//           home: Scaffold(
//             body: ChatBubble(
//               message: 'AI message',
//               isUser: false,
//             ),
//           ),
//         ),
//       );
//
//       final alignWidget = tester.widget<Align>(find.byType(Align));
//       expect(alignWidget.alignment, Alignment.centerLeft);
//     });
//   });
// }