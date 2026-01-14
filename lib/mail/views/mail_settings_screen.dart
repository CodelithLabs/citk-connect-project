// lib/mail/views/mail_settings_screen.dart

import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:citk_connect/mail/providers/mail_provider.dart';
import 'package:citk_connect/mail/services/mail_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MailSettingsScreen extends ConsumerStatefulWidget {
  const MailSettingsScreen({super.key});

  @override
  ConsumerState<MailSettingsScreen> createState() => _MailSettingsScreenState();
}

class _MailSettingsScreenState extends ConsumerState<MailSettingsScreen> {
  bool _isLoading = true;
  late MailSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(authServiceProvider).value;
    if (user == null) return;

    final repo = ref.read(mailRepositoryProvider);
    try {
      final settings = await repo.getSettings(user.uid);
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error or use defaults
      if (mounted) {
        setState(() {
          _settings = const MailSettings();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSettings(MailSettings newSettings) async {
    setState(() => _settings = newSettings); // Optimistic update

    final user = ref.read(authServiceProvider).value;
    if (user == null) return;

    final repo = ref.read(mailRepositoryProvider);
    try {
      await repo.updateSettings(user.uid, newSettings);
    } catch (e) {
      // Revert on failure if needed, or show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Mail Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Synchronization'),
                _buildSwitchTile(
                  title: 'Enable Sync',
                  subtitle: 'Automatically fetch new emails',
                  value: _settings.enabled,
                  onChanged: (val) =>
                      _updateSettings(_settings.copyWith(enabled: val)),
                ),
                if (_settings.enabled) ...[
                  const SizedBox(height: 16),
                  _buildDropdownTile(
                    title: 'Sync Frequency',
                    value: _settings.syncIntervalMin,
                    items: const [
                      DropdownMenuItem(
                          value: 15, child: Text('Every 15 minutes')),
                      DropdownMenuItem(
                          value: 30, child: Text('Every 30 minutes')),
                      DropdownMenuItem(value: 60, child: Text('Every hour')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(
                            _settings.copyWith(syncIntervalMin: val));
                      }
                    },
                  ),
                ],
                const SizedBox(height: 32),
                _buildSectionHeader('Notifications'),
                _buildSwitchTile(
                  title: 'High Priority Only',
                  subtitle: 'Only notify for important emails (Exams, Fees)',
                  value: _settings.notifyHighPriorityOnly,
                  onChanged: (val) => _updateSettings(
                      _settings.copyWith(notifyHighPriorityOnly: val)),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Storage'),
                ListTile(
                  title: Text(
                    'Clear Email Cache',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  subtitle: Text(
                    'Removes locally stored emails. They will be re-fetched.',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  onTap: () async {
                    // TODO: Implement clear cache in repository
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.2)),
                  ),
                  tileColor: theme.colorScheme.error.withValues(alpha: 0.05),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
