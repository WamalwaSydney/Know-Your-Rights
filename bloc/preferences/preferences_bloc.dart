// lib/presentation/bloc/preferences/preferences_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:legal_ai/core/services/preferences_service.dart';

// Events
abstract class PreferencesEvent extends Equatable {
  const PreferencesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPreferences extends PreferencesEvent {}

class ChangeThemeMode extends PreferencesEvent {
  final String themeMode;
  const ChangeThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class ToggleNotifications extends PreferencesEvent {
  final bool enabled;
  const ToggleNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ChangeLanguage extends PreferencesEvent {
  final String languageCode;
  const ChangeLanguage(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class ToggleAutoSave extends PreferencesEvent {
  final bool enabled;
  const ToggleAutoSave(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// States
abstract class PreferencesState extends Equatable {
  const PreferencesState();

  @override
  List<Object?> get props => [];
}

class PreferencesInitial extends PreferencesState {}

class PreferencesLoading extends PreferencesState {}

class PreferencesLoaded extends PreferencesState {
  final String themeMode;
  final bool notificationsEnabled;
  final String language;
  final bool autoSaveEnabled;

  const PreferencesLoaded({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.language,
    required this.autoSaveEnabled,
  });

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    language,
    autoSaveEnabled,
  ];

  PreferencesLoaded copyWith({
    String? themeMode,
    bool? notificationsEnabled,
    String? language,
    bool? autoSaveEnabled,
  }) {
    return PreferencesLoaded(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
    );
  }
}

class PreferencesError extends PreferencesState {
  final String message;
  const PreferencesError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final PreferencesService _preferencesService;

  PreferencesBloc(this._preferencesService) : super(PreferencesInitial()) {
    on<LoadPreferences>(_onLoadPreferences);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ToggleAutoSave>(_onToggleAutoSave);
  }

  Future<void> _onLoadPreferences(
      LoadPreferences event,
      Emitter<PreferencesState> emit,
      ) async {
    emit(PreferencesLoading());
    try {
      final themeMode = _preferencesService.getThemeMode();
      final notificationsEnabled = _preferencesService.getNotificationsEnabled();
      final language = _preferencesService.getLanguage();
      final autoSaveEnabled = _preferencesService.getAutoSaveEnabled();

      emit(PreferencesLoaded(
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        language: language,
        autoSaveEnabled: autoSaveEnabled,
      ));
    } catch (e) {
      emit(PreferencesError('Failed to load preferences: $e'));
    }
  }

  Future<void> _onChangeThemeMode(
      ChangeThemeMode event,
      Emitter<PreferencesState> emit,
      ) async {
    if (state is PreferencesLoaded) {
      try {
        await _preferencesService.setThemeMode(event.themeMode);
        emit((state as PreferencesLoaded).copyWith(themeMode: event.themeMode));
      } catch (e) {
        emit(PreferencesError('Failed to change theme: $e'));
      }
    }
  }

  Future<void> _onToggleNotifications(
      ToggleNotifications event,
      Emitter<PreferencesState> emit,
      ) async {
    if (state is PreferencesLoaded) {
      try {
        await _preferencesService.setNotificationsEnabled(event.enabled);
        emit((state as PreferencesLoaded)
            .copyWith(notificationsEnabled: event.enabled));
      } catch (e) {
        emit(PreferencesError('Failed to toggle notifications: $e'));
      }
    }
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event,
      Emitter<PreferencesState> emit,
      ) async {
    if (state is PreferencesLoaded) {
      try {
        await _preferencesService.setLanguage(event.languageCode);
        emit((state as PreferencesLoaded).copyWith(language: event.languageCode));
      } catch (e) {
        emit(PreferencesError('Failed to change language: $e'));
      }
    }
  }

  Future<void> _onToggleAutoSave(
      ToggleAutoSave event,
      Emitter<PreferencesState> emit,
      ) async {
    if (state is PreferencesLoaded) {
      try {
        await _preferencesService.setAutoSaveEnabled(event.enabled);
        emit((state as PreferencesLoaded).copyWith(autoSaveEnabled: event.enabled));
      } catch (e) {
        emit(PreferencesError('Failed to toggle auto-save: $e'));
      }
    }
  }
}