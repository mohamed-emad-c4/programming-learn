// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth/auth_cubit.dart';
import 'package:learn_programming/presentation/cubit/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const _ThemeSettings(),
          const Divider(),
          _buildSettingsSection(
            title: 'عام',
            children: [
              _buildSettingsItem(
                icon: Icons.language,
                title: 'اللغة',
                subtitle: 'تغيير لغة التطبيق',
                onTap: () {
                  // Navigate to language settings
                },
              ),
              _buildSettingsItem(
                icon: Icons.notifications,
                title: 'الإشعارات',
                subtitle: 'إدارة الإشعارات',
                onTap: () {
                  // Navigate to notification settings
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildSettingsSection(
            title: 'الحساب',
            children: [
              _buildSettingsItem(
                icon: Icons.person,
                title: 'معلومات الحساب',
                subtitle: 'عرض وتعديل معلومات الحساب',
                onTap: () {
                  // Navigate to account info
                },
              ),
              _buildSettingsItem(
                icon: Icons.lock,
                title: 'تغيير كلمة المرور',
                subtitle: 'تغيير كلمة المرور الحالية',
                onTap: () {
                  // Navigate to change password
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildSettingsSection(
            title: 'أخرى',
            children: [
              _buildSettingsItem(
                icon: Icons.help,
                title: 'المساعدة',
                subtitle: 'الدعم والمساعدة',
                onTap: () {
                  // Navigate to help
                },
              ),
              _buildSettingsItem(
                icon: Icons.info,
                title: 'عن التطبيق',
                subtitle: 'معلومات عن التطبيق',
                onTap: () {
                  // Navigate to about
                },
              ),
              _buildSettingsItem(
                icon: Icons.logout,
                title: 'تسجيل الخروج',
                subtitle: 'تسجيل الخروج من التطبيق',
                onTap: () {
                  authCubit.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Card(
          elevation: 2.0,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: onTap,
    );
  }
}

class _ThemeSettings extends StatelessWidget {
  const _ThemeSettings();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RadioListTile<ThemeState>(
              title: const Text('Light'),
              value: ThemeState.light,
              groupValue: state,
              onChanged: (ThemeState? value) {
                if (value != null) {
                  context.read<ThemeCubit>().setTheme(value);
                }
              },
            ),
            RadioListTile<ThemeState>(
              title: const Text('Dark'),
              value: ThemeState.dark,
              groupValue: state,
              onChanged: (ThemeState? value) {
                if (value != null) {
                  context.read<ThemeCubit>().setTheme(value);
                }
              },
            ),
            RadioListTile<ThemeState>(
              title: const Text('System'),
              value: ThemeState.system,
              groupValue: state,
              onChanged: (ThemeState? value) {
                if (value != null) {
                  context.read<ThemeCubit>().setTheme(value);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
