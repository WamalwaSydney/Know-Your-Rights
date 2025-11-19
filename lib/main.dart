// lib/main.dart (UPDATED WITH BLOC AND PREFERENCES)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/core/config/env_config.dart';
import 'package:legal_ai/firebase_options.dart';
import 'package:legal_ai/core/services/auth_service.dart';
import 'package:legal_ai/core/services/preferences_service.dart';
import 'package:legal_ai/bloc/preferences/preferences_bloc.dart';
import 'package:legal_ai/screens/splash_screen.dart';
import 'package:legal_ai/screens/auth/authenticate.dart';
import 'package:legal_ai/screens/auth/email_verification_screen.dart';
import 'package:legal_ai/screens/auth/password_reset_screen.dart';
import 'package:legal_ai/screens/main/home_screen.dart';
import 'package:legal_ai/screens/main/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Validate environment configuration
  try {
    EnvConfig.validate();
  } catch (e) {
    print('Environment validation failed: $e');
    if (EnvConfig.isProduction) {
      runApp(ErrorApp(error: e.toString()));
      return;
    }
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    runApp(ErrorApp(error: 'Failed to initialize Firebase: $e'));
    return;
  }

  // Initialize Shared Preferences
  final preferencesService = PreferencesService();
  try {
    await preferencesService.init();
    print('✅ Preferences initialized successfully');
  } catch (e) {
    print('⚠️ Preferences initialization warning: $e');
  }

  // Set transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: kDarkBackgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(MyApp(preferencesService: preferencesService));
}

class MyApp extends StatelessWidget {
  final PreferencesService preferencesService;

  const MyApp({Key? key, required this.preferencesService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Preferences BLoC
        BlocProvider<PreferencesBloc>(
          create: (context) => PreferencesBloc(preferencesService)
            ..add(LoadPreferences()),
        ),
      ],
      child: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, preferencesState) {
          // Determine theme mode
          ThemeMode themeMode = ThemeMode.dark;
          if (preferencesState is PreferencesLoaded) {
            switch (preferencesState.themeMode) {
              case 'light':
                themeMode = ThemeMode.light;
                break;
              case 'dark':
                themeMode = ThemeMode.dark;
                break;
              case 'system':
                themeMode = ThemeMode.system;
                break;
            }
          }

          return StreamProvider<User?>.value(
            value: AuthService().user,
            initialData: null,
            catchError: (context, error) {
              print('Auth stream error: $error');
              return null;
            },
            child: MaterialApp(
              title: EnvConfig.appName,
              debugShowCheckedModeBanner: EnvConfig.isDevelopment,
              themeMode: themeMode,

              // Light Theme
              theme: ThemeData(
                brightness: Brightness.light,
                primaryColor: kPrimaryColor,
                scaffoldBackgroundColor: Colors.grey[100],
                cardColor: Colors.white,
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  iconTheme: const IconThemeData(color: kDarkTextColor),
                  titleTextStyle: const TextStyle(
                    color: kDarkTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: kDarkTextColor),
                  bodyMedium: TextStyle(color: kDarkTextColor),
                  titleLarge: TextStyle(color: kDarkTextColor),
                ),
              ),

              // Dark Theme
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: kPrimaryColor,
                scaffoldBackgroundColor: kDarkBackgroundColor,
                cardColor: kDarkCardColor,
                appBarTheme: const AppBarTheme(
                  backgroundColor: kDarkBackgroundColor,
                  elevation: 0,
                  centerTitle: true,
                ),
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: kLightTextColor),
                  bodyMedium: TextStyle(color: kLightTextColor),
                  titleLarge: TextStyle(color: kLightTextColor),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: kDarkCardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                  ),
                  hintStyle: TextStyle(color: kLightTextColor.withOpacity(0.5)),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondaryColor,
                    foregroundColor: kLightTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: kDarkCardColor,
                  selectedItemColor: kPrimaryColor,
                  unselectedItemColor: kLightTextColor,
                ),
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),

              // Routes
              home: const SplashScreen(),
              routes: {
                '/splash': (context) => const SplashScreen(),
                '/signin': (context) => const Authenticate(),
                '/home': (context) => const HomeScreen(),
                '/email-verification': (context) => const EmailVerificationScreen(),
                '/password-reset': (context) => const PasswordResetScreen(),
                '/settings': (context) => const SettingsScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: kDarkBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Application Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}