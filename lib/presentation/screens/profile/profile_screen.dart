import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/monument_model.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_drawer.dart';
import 'language_screen.dart';
import '../monuments/monument_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  int _selectedIndex = 4;
  final NotificationService _notificationService = NotificationService();
  bool _isLoadingNotifications = true;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ Attendre loadUserData() → user_id dispo avant de charger la photo
      await context.read<UserProvider>().loadUserData();
      await context.read<FavoriteProvider>().loadFavorites();
      if (mounted) await _loadProfileImage();
    });
  }

  // ✅ PAS de didChangeDependencies() → évite userId=0

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    if (userId == 0) return;
    final imagePath = prefs.getString('profile_image_path_$userId');
    if (imagePath != null && await File(imagePath).exists()) {
      if (mounted) setState(() => _profileImagePath = imagePath);
    } else {
      if (mounted) setState(() => _profileImagePath = null);
    }
  }

  Future<void> _loadNotificationStatus() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _isLoadingNotifications = true);
    await _notificationService.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
      _isLoadingNotifications = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value
            ? 'notifications_enabled'.tr(context)
            : 'notifications_disabled'.tr(context)),
        backgroundColor: value ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final languageProvider = context.watch<LanguageProvider>();
    final currentLanguageName =
        languageProvider.getLanguageName(languageProvider.currentLanguage);

    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1A2530) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final dividerColor = isDark ? const Color(0xFF2A3540) : Colors.grey[200];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      endDrawer: const AppDrawer(),
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, textColor),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(isDark, cardColor, textColor, subtitleColor),
            const SizedBox(height: 32),
            _buildSectionTitle('general_settings'.tr(context)),
            const SizedBox(height: 12),
            _buildSettingsList(
              currentLanguageName,
              isDark,
              cardColor,
              textColor,
              subtitleColor,
              dividerColor,
              iconColor,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('my_favorites'.tr(context)),
            const SizedBox(height: 12),
            _buildFavoritesList(isDark, cardColor),
            const SizedBox(height: 32),
            _buildLogOutButton(),
            const SizedBox(height: 12),
            _buildDeleteAccountButton(),
            const SizedBox(height: 16),
            _buildVersionText(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF8F9FA);
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'profile'.tr(context),
        style: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.more_vert, color: textColor),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final username = userProvider.username;
        final email = userProvider.email;

        return Column(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                ),
                child: ClipOval(
                  child: _profileImagePath != null
                      ? Image.file(File(_profileImagePath!),
                          fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Center(
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              username,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 16, color: subtitleColor),
                const SizedBox(width: 6),
                Text(email,
                    style: TextStyle(fontSize: 14, color: subtitleColor)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Explorer • Morocco',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(
    String currentLanguageName,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color? dividerColor,
    Color? iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.language,
            title: 'language'.tr(context),
            subtitle: currentLanguageName,
            textColor: textColor,
            subtitleColor: subtitleColor,
            iconColor: iconColor,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LanguageScreen())),
          ),
          _buildDivider(dividerColor),
          _buildSettingItem(
            icon: Icons.edit_outlined,
            title: 'edit_profile'.tr(context),
            textColor: textColor,
            subtitleColor: subtitleColor,
            iconColor: iconColor,
            onTap: () async {
              final updated =
                  await Navigator.pushNamed(context, '/edit-profile');
              if (updated == true) {
                await context.read<UserProvider>().loadUserData();
                // ✅ Recharger photo après retour edit-profile
                await _loadProfileImage();
              }
            },
          ),
          _buildDivider(dividerColor),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'privacy'.tr(context),
            textColor: textColor,
            subtitleColor: subtitleColor,
            iconColor: iconColor,
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),
          _buildDivider(dividerColor),
          _buildNotificationToggle(textColor, subtitleColor, iconColor),
          _buildDivider(dividerColor),
          _buildDarkModeToggle(textColor, subtitleColor, iconColor),
          _buildDivider(dividerColor),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'help_support'.tr(context),
            textColor: textColor,
            subtitleColor: subtitleColor,
            iconColor: iconColor,
            onTap: () => Navigator.pushNamed(context, '/help-support'),
          ),
          _buildDivider(dividerColor),
          _buildSettingItem(
            icon: Icons.star_rate,
            title: 'reviews_feedback'.tr(context),
            subtitle: 'share_your_experience'.tr(context),
            textColor: textColor,
            subtitleColor: subtitleColor,
            iconColor: iconColor,
            onTap: () =>
                Navigator.pushNamed(context, '/reviews-feedback'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color textColor,
    Color? subtitleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: subtitleColor)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 22, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
      Color textColor, Color? subtitleColor, Color? iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined, size: 22, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('notifications'.tr(context),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                Text(
                    _notificationsEnabled
                        ? 'daily_reminders_enabled'.tr(context)
                        : 'disabled'.tr(context),
                    style:
                        TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          if (_isLoadingNotifications)
            const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildDarkModeToggle(
      Color textColor, Color? subtitleColor, Color? iconColor) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(isDark ? Icons.dark_mode : Icons.light_mode_outlined,
              size: 22, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isDark
                        ? 'switch_to_light_theme'.tr(context)
                        : 'switch_to_dark_theme'.tr(context),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                Text(isDark ? '🌙 Dark mode' : '☀️ Light mode',
                    style:
                        TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (value) {
              context.read<ThemeProvider>().toggle(value);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(value
                    ? '🌙 Dark mode activé'
                    : '☀️ Light mode activé'),
                backgroundColor:
                    value ? const Color(0xFF1A2530) : AppColors.primary,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color? color) =>
      Divider(height: 1, thickness: 1, indent: 54, color: color);

  Widget _buildFavoritesList(bool isDark, Color cardColor) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, _) {
        if (favoriteProvider.isLoading) {
          return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()));
        }
        if (!favoriteProvider.hasFavorites) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('no_favorites_yet'.tr(context),
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/monuments'),
                    child: Text('explore_monuments'.tr(context),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: favoriteProvider.favorites.length,
            itemBuilder: (context, index) {
              final monument = favoriteProvider.favorites[index];
              return _buildFavoriteCard(monument, favoriteProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(
      Monument monument, FavoriteProvider favoriteProvider) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MonumentDetailScreen(monument: monument))),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: monument.mainImage != null
                    ? Image.network(monument.mainImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.account_balance,
                                size: 50, color: Colors.grey)))
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.account_balance,
                            size: 50, color: Colors.grey)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7)
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await favoriteProvider
                        .removeFromFavorites(monument.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content:
                            Text('removed_favorites'.tr(context)),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite,
                        color: Colors.red, size: 16),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(monument.nom,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(monument.ville,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogOutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton(
        onPressed: _showLogoutDialog,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red[400]!, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red[400], size: 20),
            const SizedBox(width: 10),
            Text('log_out'.tr(context),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[400])),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('log_out'.tr(context)),
        content: Text('are_you_sure_logout'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () async {
              await context.read<UserProvider>().logout();
              context.read<FavoriteProvider>().clearFavorites();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/welcome', (route) => false);
              }
            },
            child: Text('log_out'.tr(context),
                style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/delete-account'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red[600]!, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever, color: Colors.red[600], size: 20),
            const SizedBox(width: 10),
            Text('delete_account'.tr(context),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionText(bool isDark) {
    final color = isDark ? Colors.grey[600] : Colors.grey[500];
    return Column(
      children: [
        Text('Travel Speak v1.0.0',
            style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('made_with_love'.tr(context),
                style: TextStyle(fontSize: 12, color: color)),
            Icon(Icons.favorite, size: 14, color: Colors.red[300]),
            Text('in_morocco'.tr(context),
                style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin:
          const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E45),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.home_rounded, 0),
            _buildNavIcon(Icons.account_balance_rounded, 1),
            _buildNavIcon(Icons.translate_rounded, 2),
            _buildNavIcon(Icons.chat_bubble_rounded, 3),
            _buildNavIcon(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) Navigator.pushReplacementNamed(context, '/home');
        if (index == 1) Navigator.pushNamed(context, '/monuments');
        if (index == 2) Navigator.pushNamed(context, '/translation');
        if (index == 3) Navigator.pushNamed(context, '/chatbot');
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}