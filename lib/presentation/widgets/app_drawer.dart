import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/string_extensions.dart';
import '../providers/user_provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    // ✅ postFrameCallback → user_id déjà sauvegardé quand le drawer s'ouvre
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProfileImage();
    });
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    if (userId == 0) return; // ✅ garde-fou
    final imagePath = prefs.getString('profile_image_path_$userId');
    if (imagePath != null && await File(imagePath).exists()) {
      if (mounted) setState(() => _profileImagePath = imagePath);
    } else {
      if (mounted) setState(() => _profileImagePath = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      width: 260,
      elevation: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildMenuItem(context,
                  icon: Icons.home_outlined,
                  label: 'home'.tr(context),
                  route: '/home'),
              _buildMenuItem(context,
                  icon: Icons.account_balance_outlined,
                  label: 'monuments'.tr(context),
                  route: '/monuments'),
              _buildMenuItem(context,
                  icon: Icons.translate,
                  label: 'translation'.tr(context),
                  route: '/translation'),
              _buildMenuItem(context,
                  icon: Icons.chat_bubble_outline,
                  label: 'chat_bot'.tr(context),
                  route: '/chatbot'),
              _buildMenuItem(context,
                  icon: Icons.history,
                  label: 'history'.tr(context),
                  route: '/history'),
              const Spacer(),
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              const SizedBox(height: 12),
              _buildBottomItem(
                context,
                icon: Icons.settings_outlined,
                label: 'settings'.tr(context),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              _buildBottomItem(
                context,
                icon: Icons.logout,
                label: 'log_out'.tr(context),
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final username = userProvider.username;
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/profile');
          },
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _profileImagePath == null
                      ? AppColors.primaryGradient
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: _profileImagePath != null
                    ? ClipOval(
                        child: Image.file(File(_profileImagePath!),
                            fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text('view_profile'.tr(context),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
                color: colorScheme.onSurface,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String label,
      required String route}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (route == '/home') {
          Navigator.pushNamedAndRemoveUntil(
              context, route, (route) => false);
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomItem(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            Icon(icon,
                color: isDestructive
                    ? Colors.red[400]
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 20),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Colors.red[400]
                        : (isDark
                            ? Colors.grey[300]
                            : Colors.grey[700]))),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('log_out'.tr(context),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        content: Text('are_you_sure_you_want_to_log_out'.tr(context),
            style:
                TextStyle(fontSize: 15, color: colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(context),
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              await context.read<UserProvider>().logout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/welcome', (route) => false);
              }
            },
            child: Text('log_out'.tr(context),
                style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}