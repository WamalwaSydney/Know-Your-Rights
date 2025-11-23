// test/bloc/preferences_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_ai/core/services/preferences_service.dart';
import 'package:legal_ai/bloc/preferences/preferences_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PreferencesBloc Tests', () {
    late PreferencesService preferencesService;
    late PreferencesBloc preferencesBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferencesService = PreferencesService();
      await preferencesService.init();
      preferencesBloc = PreferencesBloc(preferencesService);
    });

    tearDown(() {
      preferencesBloc.close();
    });

    test('initial state is PreferencesInitial', () {
      expect(preferencesBloc.state, PreferencesInitial());
    });

    blocTest<PreferencesBloc, PreferencesState>(
      'emits [PreferencesLoading, PreferencesLoaded] when LoadPreferences is added',
      build: () => preferencesBloc,
      act: (bloc) => bloc.add(LoadPreferences()),
      expect: () => [
        PreferencesLoading(),
        isA<PreferencesLoaded>()
            .having((s) => s.themeMode, 'themeMode', 'dark')
            .having((s) => s.notificationsEnabled, 'notificationsEnabled', true)
            .having((s) => s.language, 'language', 'en')
            .having((s) => s.autoSaveEnabled, 'autoSaveEnabled', true),
      ],
    );

    blocTest<PreferencesBloc, PreferencesState>(
      'emits updated PreferencesLoaded when ChangeThemeMode is added',
      build: () => preferencesBloc,
      seed: () => const PreferencesLoaded(
        themeMode: 'dark',
        notificationsEnabled: true,
        language: 'en',
        autoSaveEnabled: true,
      ),
      act: (bloc) => bloc.add(const ChangeThemeMode('light')),
      expect: () => [
        isA<PreferencesLoaded>()
            .having((s) => s.themeMode, 'themeMode', 'light')
            .having((s) => s.notificationsEnabled, 'notificationsEnabled', true)
            .having((s) => s.language, 'language', 'en')
            .having((s) => s.autoSaveEnabled, 'autoSaveEnabled', true),
      ],
      verify: (_) {
        expect(preferencesService.getThemeMode(), 'light');
      },
    );

    blocTest<PreferencesBloc, PreferencesState>(
      'emits updated PreferencesLoaded when ToggleNotifications is added',
      build: () => preferencesBloc,
      seed: () => const PreferencesLoaded(
        themeMode: 'dark',
        notificationsEnabled: true,
        language: 'en',
        autoSaveEnabled: true,
      ),
      act: (bloc) => bloc.add(const ToggleNotifications(false)),
      expect: () => [
        isA<PreferencesLoaded>()
            .having((s) => s.notificationsEnabled, 'notificationsEnabled', false),
      ],
      verify: (_) {
        expect(preferencesService.getNotificationsEnabled(), false);
      },
    );

    blocTest<PreferencesBloc, PreferencesState>(
      'emits updated PreferencesLoaded when ChangeLanguage is added',
      build: () => preferencesBloc,
      seed: () => const PreferencesLoaded(
        themeMode: 'dark',
        notificationsEnabled: true,
        language: 'en',
        autoSaveEnabled: true,
      ),
      act: (bloc) => bloc.add(const ChangeLanguage('es')),
      expect: () => [
        isA<PreferencesLoaded>()
            .having((s) => s.language, 'language', 'es'),
      ],
      verify: (_) {
        expect(preferencesService.getLanguage(), 'es');
      },
    );

    blocTest<PreferencesBloc, PreferencesState>(
      'emits updated PreferencesLoaded when ToggleAutoSave is added',
      build: () => preferencesBloc,
      seed: () => const PreferencesLoaded(
        themeMode: 'dark',
        notificationsEnabled: true,
        language: 'en',
        autoSaveEnabled: true,
      ),
      act: (bloc) => bloc.add(const ToggleAutoSave(false)),
      expect: () => [
        isA<PreferencesLoaded>()
            .having((s) => s.autoSaveEnabled, 'autoSaveEnabled', false),
      ],
      verify: (_) {
        expect(preferencesService.getAutoSaveEnabled(), false);
      },
    );

    blocTest<PreferencesBloc, PreferencesState>(
      'handles multiple preference changes in sequence',
      build: () => preferencesBloc,
      seed: () => const PreferencesLoaded(
        themeMode: 'dark',
        notificationsEnabled: true,
        language: 'en',
        autoSaveEnabled: true,
      ),
      act: (bloc) => bloc
        ..add(const ChangeThemeMode('light'))
        ..add(const ToggleNotifications(false))
        ..add(const ChangeLanguage('fr')),
      expect: () => [
        isA<PreferencesLoaded>().having((s) => s.themeMode, 'themeMode', 'light'),
        isA<PreferencesLoaded>().having((s) => s.notificationsEnabled, 'notificationsEnabled', false),
        isA<PreferencesLoaded>().having((s) => s.language, 'language', 'fr'),
      ],
    );
  });
}