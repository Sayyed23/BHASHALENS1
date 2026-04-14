import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/enhanced_accessibility_service.dart';
import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:bhashalens_app/services/preferences_service.dart';
import 'package:bhashalens_app/services/history_service.dart';
import 'package:bhashalens_app/services/aws_api_gateway_client.dart';
import 'package:bhashalens_app/widgets/export_data_dialog.dart';
import 'package:bhashalens_app/widgets/web_constrained_body.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _simplifiedInterface = false;
  bool _wifiOnlyDownloads = false;
  bool _offlineMode = false;

  void _navigateTo(String route) {
    if (route == 'settings') return;

    final routeMap = {
      'edit_profile': 'action:coming_soon',
      'app_language': 'action:coming_soon',
      'default_translation': 'action:coming_soon',
      'privacy_permissions': 'action:coming_soon',
      'help_support': '/help_support',
      'clear_history': 'action:clear_history',
      'manage_packs': '/offline_models',
    };

    final namedRoute = routeMap[route];
    if (namedRoute != null) {
      if (namedRoute == 'action:clear_history') {
        _showClearHistoryDialog(context);
        return;
      }
      if (namedRoute == 'action:coming_soon') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This setting is coming soon.')),
        );
        return;
      }
      Navigator.of(context).pushNamed(namedRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feature not implemented: $route')),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C222B),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access your saved settings.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout',
                  style: TextStyle(color: Color(0xFFEF5350))),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      if (!context.mounted) return;
      try {
        final authService =
            Provider.of<FirebaseAuthService?>(context, listen: false);
        if (authService != null) {
          await authService.signOut();
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Unable to logout. Please try again.')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error during logout: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout failed. Please try again.')),
          );
        }
      }
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C222B),
        title:
            const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: const Text(
            'Are you sure you want to clear all history? This cannot be undone.',
            style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await Provider.of<HistoryService>(context, listen: false)
                  .clearHistory();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared')));
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityController = Provider.of<AccessibilityController>(context);
    final prefsService = Provider.of<PreferencesService>(context);

    // Theme Colors
    const Color bgDark = Color(0xFF101822);
    const Color cardDark = Color(0xFF1C222B);
    const Color primaryBlue = Color(0xFF136DEC);
    const Color textGrey = Color(0xFF94A3B8);
    const Color dividerColor = Color(0xFF2D3748);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: wrapWithWebMaxWidth(
        context,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Account Status: Active",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text("BhashaLens App Version 2.1.0",
                              style: TextStyle(color: textGrey, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person,
                          color: primaryBlue, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cloud sync status
              Consumer<AwsApiGatewayClient>(
                builder: (context, apiClient, _) {
                  final enabled = apiClient.isEnabled;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D3748)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: enabled
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enabled ? 'Cloud sync: On' : 'Cloud sync: Off',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enabled
                                    ? 'History and preferences sync when online.'
                                    : 'Cloud sync is currently disabled.',
                                style: const TextStyle(
                                  color: textGrey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ACCESSIBILITY CONTROLS
              const Text(
                "ACCESSIBILITY CONTROLS",
                style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),

              // Text Size Slider
              const Text("Text Size",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Tt",
                      style: TextStyle(color: textGrey, fontSize: 14)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: const Color(0xFF334155),
                        thumbColor: primaryBlue,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: accessibilityController.textSizeFactor,
                        min: 0.8,
                        max: 1.4,
                        onChanged: (val) =>
                            accessibilityController.setTextSizeFactor(val),
                      ),
                    ),
                  ),
                  const Text("Tt",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748)),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.contrast,
                      iconColor: primaryBlue,
                      title: "High Contrast Mode",
                      value: accessibilityController.themeMode == ThemeMode.dark,
                      onChanged: (val) =>
                          accessibilityController.toggleThemeMode(),
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildSwitchTile(
                      icon: Icons.visibility,
                      iconColor: primaryBlue,
                      title: "Simplified Interface",
                      value: _simplifiedInterface,
                      onChanged: (val) =>
                          setState(() => _simplifiedInterface = val),
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildSwitchTile(
                      icon: Icons.record_voice_over,
                      iconColor: primaryBlue,
                      title: "Voice Guidance",
                      value: accessibilityController.isVoiceNavigationEnabled,
                      onChanged: (val) async {
                        try {
                          if (val) {
                            await accessibilityController.enableAudioFeedback();
                            await accessibilityController.enableVoiceNavigation();
                          } else {
                            await accessibilityController.disableVoiceNavigation();
                            await accessibilityController.disableAudioFeedback();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Voice guidance error: $e',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFFEF5350),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1, color: dividerColor),
                    ListTile(
                      leading: const Icon(Icons.build_circle_outlined, color: primaryBlue),
                      title: const Text(
                        "Troubleshoot Voice Systems",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      subtitle: const Text(
                        "Click here if voice commands stop working",
                        style: TextStyle(color: textGrey, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.refresh, color: textGrey),
                      onTap: () async {
                        try {
                          await accessibilityController.reinitializeServices();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Accessibility services re-initialized'),
                                backgroundColor: Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Re-initialization failed: $e'),
                                backgroundColor: const Color(0xFFEF5350),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // LANGUAGES & TRANSLATION
              const Text(
                "LANGUAGES & TRANSLATION",
                style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748)),
                ),
                child: Column(
                  children: [
                    _buildNavTile(
                      title: "App Language",
                      subtitle: "English",
                      onTap: () => _navigateTo("app_language"),
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildNavTile(
                      title: "Default Translation",
                      subtitle:
                          "${prefsService.defaultSourceLang.toUpperCase()} \u2192 ${prefsService.defaultTargetLang.toUpperCase()}",
                      onTap: () => _navigateTo("default_translation"),
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildSwitchTile(
                      title: "Auto-detect Language",
                      value: prefsService.autoTranslate,
                      onChanged: (val) =>
                          prefsService.updatePreference('autoTranslate', val),
                      hideIcon: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AUDIO & OFFLINE
              const Text(
                "AUDIO & OFFLINE",
                style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748)),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: "Offline Mode",
                      value: _offlineMode,
                      onChanged: (val) => setState(() => _offlineMode = val),
                      hideIcon: true,
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildNavTile(
                      title: "Offline Language Packs",
                      subtitle: "Manage downloads",
                      onTap: () => _navigateTo("manage_packs"),
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildSwitchTile(
                      title: "Wi-Fi Only Downloads",
                      value: _wifiOnlyDownloads,
                      onChanged: (val) =>
                          setState(() => _wifiOnlyDownloads = val),
                      hideIcon: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // DATA & SUPPORT
              const Text(
                "DATA & SUPPORT",
                style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748)),
                ),
                child: Column(
                  children: [
                    _buildNavTile(
                      icon: Icons.download_outlined,
                      title: "Export data",
                      subtitle: "History or saved translations",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ExportDataDialog(),
                        );
                      },
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildNavTile(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () => _navigateTo("help_support"),
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildActionTile(
                      icon: Icons.delete_sweep_outlined,
                      iconColor: const Color(0xFFEF5350),
                      title: "Clear History",
                      titleColor: const Color(0xFFEF5350),
                      onTap: () => _navigateTo("clear_history"),
                    ),
                    const Divider(height: 1, color: dividerColor),
                    _buildActionTile(
                      icon: Icons.logout,
                      iconColor: const Color(0xFFEF5350),
                      title: "Logout",
                      titleColor: const Color(0xFFEF5350),
                      onTap: () => _handleLogout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    IconData? icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool hideIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!hideIcon) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.white).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF136DEC),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF334155),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    IconData? icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF136DEC),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
