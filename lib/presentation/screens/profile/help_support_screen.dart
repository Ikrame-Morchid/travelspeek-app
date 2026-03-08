import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context),
            const SizedBox(height: 24),
            _buildSectionTitle('frequently_asked_questions'.tr(context), theme),
            const SizedBox(height: 12),
            _buildFAQSection(context, theme),
            const SizedBox(height: 24),
            _buildSectionTitle('contact_us'.tr(context), theme),
            const SizedBox(height: 12),
            _buildContactOptions(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'help_support'.tr(context),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
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
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent,
                  color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'how_can_we_help_you'.tr(context),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'were_here_to_assist_you_with_any_questions_or_issue'
                .tr(context),
            style: const TextStyle(
                fontSize: 14, color: Colors.white, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodySmall?.color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildFAQItem(
          context: context,
          theme: theme,
          question: 'how_do_i_use_the_translation_feature'.tr(context),
          answer:
              'tap_the_translation_icon_in_the_bottom_navigation_b'
                  .tr(context),
          icon: Icons.translate,
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context: context,
          theme: theme,
          question:
              'how_do_i_save_my_favorite_monuments'.tr(context),
          answer:
              'when_viewing_a_monument_tap_the_heart_icon_to_add_i'
                  .tr(context),
          icon: Icons.favorite_outline,
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context: context,
          theme: theme,
          question: 'can_i_use_the_app_offline'.tr(context),
          answer:
              'some_features_like_saved_translations_and_downloaded'
                  .tr(context),
          icon: Icons.wifi_off,
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context: context,
          theme: theme,
          question:
              'how_do_i_change_the_app_language'.tr(context),
          answer:
              'go_to_profile_language_to_select_your_preferred_app'
                  .tr(context),
          icon: Icons.language,
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context: context,
          theme: theme,
          question: 'is_my_data_secure'.tr(context),
          answer:
              'yes_we_take_your_privacy_seriously_all_data_is_encr'
                  .tr(context),
          icon: Icons.security,
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required BuildContext context,
    required ThemeData theme,
    required String question,
    required String answer,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          iconColor: theme.textTheme.bodyMedium?.color,
          collapsedIconColor: theme.textTheme.bodyMedium?.color,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOptions(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildContactCard(
          context: context,
          theme: theme,
          icon: Icons.email,
          iconColor: AppColors.primary,
          title: 'email_support'.tr(context),
          subtitle: 'travelspeekt@gmail.com',
          description: 'get_a_response_within_24_hours'.tr(context),
          onTap: () => _launchEmail(context),
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          context: context,
          theme: theme,
          icon: Icons.chat_bubble,
          iconColor: const Color(0xFF25D366),
          title: 'whatsapp'.tr(context),
          subtitle: '+212 713 205 620',
          description: 'chat_with_us_instantly'.tr(context),
          onTap: () => _launchWhatsApp(context),
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          context: context,
          theme: theme,
          icon: Icons.phone,
          iconColor: const Color(0xFF2196F3),
          title: 'phone_support'.tr(context),
          subtitle: '+212 713 205 620',
          description: 'mon_fri_9am_6pm_gmt'.tr(context),
          onTap: () => _launchPhone(context),
        ),
      ],
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'travelspeekt@gmail.com',
      query: 'subject=Support Request - TravelSpeak',
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/212713205620?text=${Uri.encodeComponent("Bonjour, j\'ai besoin d\'aide avec TravelSpeak")}');
    try {
      await launchUrl(whatsappUri,
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri.parse('tel:+212713205620');
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  Widget _buildContactCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                size: 16,
                color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}