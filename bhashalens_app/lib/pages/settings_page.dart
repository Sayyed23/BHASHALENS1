import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/accessibility_service.dart';
import 'package:bhashalens_app/services/firebase_auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Mock State for UI Demo (will be connected to services later where applicable)
  bool _highContrast =
      false; // Mapped to Dark Mode via Service usually, but keeping separate for UI demo
  bool _simplifiedInterface = false;
  bool _voiceGuidance = false;
  bool _autoDetectLanguage = true;
  bool _offlineMode = false;
  bool _wifiOnlyDownloads = false;

  void _navigateTo(String route) {
    if (route == 'settings') return;

    final routeMap = {
      'edit_profile': '/profile',
      'app_language': '/app_language',
      'default_translation': '/default_language', // Updated key
      'privacy_permissions': '/privacy_policy', // Updated key
      'help_support': '/help_support',
      'clear_history': '/clear_history', // Placeholder route
      'manage_packs': '/offline_models',
    };

    final namedRoute = routeMap[route];
    if (namedRoute != null) {
      if (route == 'clear_history') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('History cleared (Demo)')));
        return;
      }
      Navigator.of(context).pushNamed(namedRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feature not implemented: $route')),
      );
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C222B),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access your saved settings.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFEF5350)),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      if (!mounted) return;
      try {
        // Get the auth service - handle case where it might not be available
        FirebaseAuthService? authService;
        try {
          authService =
              Provider.of<FirebaseAuthService?>(context, listen: false);
        } catch (e) {
          debugPrint('FirebaseAuthService not available: $e');
        }

        if (authService != null) {
          // Show loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logging out...'),
                backgroundColor: Color(0xFF136DEC),
              ),
            );
          }

          // Perform logout
          await authService.signOut();

          // Navigate to login/onboarding page
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/onboarding',
              (route) => false,
            );
          }
        } else {
          // Fallback when auth service is not available
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication service not available'),
                backgroundColor: Color(0xFFEF5350),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error during logout: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF5350),
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Sync local state with actual services if needed
  }

  @override
  Widget build(BuildContext context) {
    AccessibilityService? accessibilityService;
    try {
      accessibilityService = Provider.of<AccessibilityService>(context);
    } catch (e) {
      debugPrint('AccessibilityService not found: $e');
    }

    // AccessibilityService might be null, but we continue rendering other settings.
    final service = accessibilityService;

    // Theme Colors from Mockup
    const Color bgDark = Color(0xFF101822);
    const Color cardDark = Color(0xFF1C222B);
    const Color primaryBlue = Color(0xFF136DEC);
    // const Color textWhite = Colors.white; // Unused
    const Color textGrey = Color(0xFF94A3B8); // Slate-400
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
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                                color: Color(0xFF22C55E), // Green
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Account Status: Active",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "BhashaLens App Version 2.1.0",
                          style: TextStyle(color: textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: primaryBlue,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ACCESSIBILITY CONTROLS
            const Text(
              "ACCESSIBILITY CONTROLS",
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            if (service != null) ...[
              // Text Size Slider
              const Text(
                "Text Size",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    "Tt",
                    style: TextStyle(color: textGrey, fontSize: 14),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: const Color(0xFF334155),
                        thumbColor: primaryBlue,
                        overlayColor: primaryBlue.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: service.textSizeFactor,
                        min: 0.8,
                        max: 1.4,
                        onChanged: (val) {
                          service.setTextSizeFactor(val);
                        },
                      ),
                    ),
                  ),
                  const Text(
                    "Tt",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // Accessibility Toggles
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
                      value: _highContrast,
                      onChanged: (val) => setState(() => _highContrast = val),
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
                      value: _voiceGuidance,
                      onChanged: (val) => setState(() => _voiceGuidance = val),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Fallback when AccessibilityService is unavailable
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748)),
                ),
                child: const Text(
                  "Accessibility controls unavailable",
                  style: TextStyle(color: textGrey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // LANGUAGES & TRANSLATION
            const Text(
              "LANGUAGES & TRANSLATION",
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
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
                    subtitle: "Hindi → English",
                    onTap: () => _navigateTo("default_translation"),
                  ),
                  const Divider(height: 1, color: dividerColor),
                  _buildSwitchTile(
                    title: "Auto-detect Language",
                    value: _autoDetectLanguage,
                    onChanged: (val) =>
                        setState(() => _autoDetectLanguage = val),
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
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Speech Playback Speed
            const Text(
              "Speech Playback Speed",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: textGrey,
                  size: 20,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: primaryBlue,
                      inactiveTrackColor: const Color(0xFF334155),
                      thumbColor: primaryBlue,
                      overlayColor: primaryBlue.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: 0.5, // Mock value
                      onChanged: (val) {}, // Mock action
                    ),
                  ),
                ),
                const Icon(
                  Icons.run_circle_outlined,
                  color: Colors.white,
                  size: 20,
                ),
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
                letterSpacing: 1.0,
              ),
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
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () => _navigateTo("help_support"),
                  ),
                  const Divider(height: 1, color: dividerColor),
                  _buildNavTile(
                    icon: Icons.lock_outline,
                    title: "Privacy & Permissions",
                    onTap: () => _navigateTo("privacy_permissions"),
                  ),
                  const Divider(height: 1, color: dividerColor),
                  _buildActionTile(
                    icon: Icons.delete_sweep_outlined,
                    iconColor: const Color(0xFFEF5350), // Red
                    title: "Clear History",
                    titleColor: const Color(0xFFEF5350),
                    onTap: () => _navigateTo("clear_history"),
                  ),
                  const Divider(height: 1, color: dividerColor),
                  _buildActionTile(
                    icon: Icons.logout,
                    iconColor: const Color(0xFFEF5350), // Red
                    title: "Logout",
                    titleColor: const Color(0xFFEF5350),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(height: 40),
          ],
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
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8), // textGrey
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // activeColor: Colors.white, // Removed based on feedback
            activeTrackColor: const Color(0xFF136DEC), // primaryBlue
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
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF136DEC), // primaryBlue
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
