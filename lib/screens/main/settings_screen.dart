// lib/presentation/screens/main/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/core/services/auth_service.dart';
import 'package:legal_ai/bloc/preferences/preferences_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kDarkCardColor,
      ),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) {
          if (state is PreferencesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            );
          }

          if (state is PreferencesError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is! PreferencesLoaded) {
            return const Center(child: Text('Loading preferences...'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account Section
              _buildSectionHeader('Account'),
              _buildAccountCard(context, user),
              const SizedBox(height: 24),

              // Appearance Section
              _buildSectionHeader('Appearance'),
              _buildAppearanceCard(context, state),
              const SizedBox(height: 24),

              // Preferences Section
              _buildSectionHeader('Preferences'),
              _buildPreferencesCard(context, state),
              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader('About'),
              _buildAboutCard(context),
              const SizedBox(height: 24),

              // Sign Out Button
              _buildSignOutButton(context, authService),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, user) {
    return Card(
      color: kDarkCardColor,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: kPrimaryColor,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: kDarkTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user?.displayName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user?.email ?? 'No email'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.verified, color: Colors.green),
            title: const Text('Email Verification'),
            subtitle: Text(
              user?.emailVerified == true ? 'Verified' : 'Not Verified',
            ),
            trailing: user?.emailVerified != true
                ? TextButton(
              onPressed: () {
                // Navigate to email verification
                Navigator.pushNamed(context, '/email-verification');
              },
              child: const Text('Verify'),
            )
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: kPrimaryColor),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/password-reset');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context, PreferencesLoaded state) {
    return Card(
      color: kDarkCardColor,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette, color: kPrimaryColor),
            title: const Text('Theme Mode'),
            subtitle: Text(_getThemeLabel(state.themeMode)),
            trailing: DropdownButton<String>(
              value: state.themeMode,
              dropdownColor: kDarkBackgroundColor,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                DropdownMenuItem(value: 'system', child: Text('System')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<PreferencesBloc>().add(ChangeThemeMode(value));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, PreferencesLoaded state) {
    return Card(
      color: kDarkCardColor,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: kPrimaryColor),
            title: const Text('Notifications'),
            subtitle: const Text('Receive app notifications'),
            value: state.notificationsEnabled,
            activeColor: kPrimaryColor,
            onChanged: (value) {
              context.read<PreferencesBloc>().add(ToggleNotifications(value));
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.save, color: kPrimaryColor),
            title: const Text('Auto-Save Documents'),
            subtitle: const Text('Automatically save drafts'),
            value: state.autoSaveEnabled,
            activeColor: kPrimaryColor,
            onChanged: (value) {
              context.read<PreferencesBloc>().add(ToggleAutoSave(value));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language, color: kPrimaryColor),
            title: const Text('Language'),
            subtitle: Text(_getLanguageLabel(state.language)),
            trailing: DropdownButton<String>(
              value: state.language,
              dropdownColor: kDarkBackgroundColor,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Spanish')),
                DropdownMenuItem(value: 'fr', child: Text('French')),
                DropdownMenuItem(value: 'sw', child: Text('Swahili')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<PreferencesBloc>().add(ChangeLanguage(value));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      color: kDarkCardColor,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: kPrimaryColor),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: kPrimaryColor),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {
              // Open privacy policy URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Privacy Policy...')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: kPrimaryColor),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {
              // Open terms URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Terms of Service...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthService authService) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: kDarkCardColor,
              title: const Text('Sign Out', style: TextStyle(color: kLightTextColor)),
              content: const Text(
                'Are you sure you want to sign out?',
                style: TextStyle(color: kLightTextColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm == true && context.mounted) {
            try {
              await authService.signOut();
              if (context.mounted) {
                // Navigate to root and remove all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/signin',
                      (route) => false,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  String _getThemeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light Mode';
      case 'dark':
        return 'Dark Mode';
      case 'system':
        return 'System Default';
      default:
        return 'Dark Mode';
    }
  }

  String _getLanguageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'sw':
        return 'Swahili';
      default:
        return 'English';
    }
  }
}