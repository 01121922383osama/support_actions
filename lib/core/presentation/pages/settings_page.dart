import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/theme_bloc.dart';
import '../widgets/animated_app_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AnimatedAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: [
              _buildThemeSelector(context),
              const SizedBox(height: 8),
              _buildSettingTile(
                context,
                title: 'Dynamic Colors',
                subtitle: 'Use system colors for theming',
                trailing: Switch(
                  value: true, // TODO: Implement dynamic colors toggle
                  onChanged: (value) {
                    // TODO: Implement dynamic colors toggle
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            children: [
              _buildSettingTile(
                context,
                title: 'Enable Notifications',
                subtitle: 'Get notified about important updates',
                trailing: Switch(
                  value: true, // TODO: Implement notifications toggle
                  onChanged: (value) {
                    // TODO: Implement notifications toggle
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Data & Storage',
            icon: Icons.storage_outlined,
            children: [
              _buildSettingTile(
                context,
                title: 'Clear Cache',
                subtitle: 'Free up space on your device',
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // TODO: Implement clear cache
                  },
                ),
              ),
              const Divider(),
              _buildSettingTile(
                context,
                title: 'Export Data',
                subtitle: 'Save your notes as a backup',
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // TODO: Implement export data
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'About',
            icon: Icons.info_outline,
            children: [
              _buildSettingTile(
                context,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              const Divider(),
              _buildSettingTile(
                context,
                title: 'Privacy Policy',
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // TODO: Implement privacy policy
                  },
                ),
              ),
              const Divider(),
              _buildSettingTile(
                context,
                title: 'Terms of Service',
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // TODO: Implement terms of service
                  },
                ),
              ),
            ],
          ),
        ]
            .animate(interval: 100.ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                context
                    .read<ThemeBloc>()
                    .add(ThemeChanged(selection.first));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
    );
  }
}
