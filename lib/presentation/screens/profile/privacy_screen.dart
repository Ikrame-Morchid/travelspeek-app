import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../providers/theme_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1A2530) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, isDark, textColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(context, isDark),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              icon: Icons.info_outline,
              title: 'information_we_collect'.tr(context),
              content: 'info_collect_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.security,
              title: 'how_we_use_info'.tr(context),
              content: 'how_use_info_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.share_outlined,
              title: 'information_sharing'.tr(context),
              content: 'info_sharing_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.lock_outline,
              title: 'data_security'.tr(context),
              content: 'data_security_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.person_outline,
              title: 'your_rights'.tr(context),
              content: 'your_rights_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.cookie_outlined,
              title: 'cookies_tracking'.tr(context),
              content: 'cookies_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.child_care,
              title: 'children_privacy'.tr(context),
              content: 'children_privacy_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Icons.update,
              title: 'policy_updates'.tr(context),
              content: 'policy_updates_content'.tr(context),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 24),
            _buildContactSection(context, isDark, cardColor, textColor, subtitleColor),
            const SizedBox(height: 24),
            _buildLastUpdated(context, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, Color textColor) {
    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF8F9FA);
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'privacy_policy'.tr(context),
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildIntroSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'your_privacy_matters'.tr(context),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'privacy_intro'.tr(context),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color? subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'contact_us'.tr(context),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'contact_privacy_intro'.tr(context),
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            context: context,
            icon: Icons.email,
            label: 'label_email'.tr(context),
            value: 'travelspeekt@gmail.com',
            subtitleColor: subtitleColor,
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            context: context,
            icon: Icons.language,
            label: 'label_website'.tr(context),
            value: 'www.travelspeek.ma/privacy',
            subtitleColor: subtitleColor,
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            context: context,
            icon: Icons.location_on,
            label: 'label_address'.tr(context),
            value: 'Fes, Morocco',
            subtitleColor: subtitleColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color? subtitleColor,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdated(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A2530) : Colors.grey[100];
    final textColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'last_updated'.tr(context),
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}