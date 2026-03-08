import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/services/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _confirmEmailController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureEmail = true;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail =
          prefs.getString('user_email') ?? 'user@example.com';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final theme = Theme.of(context);

    if (_emailController.text.trim() != _userEmail) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('email_does_not_match'.tr(context)),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_emailController.text.trim() !=
        _confirmEmailController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('emails_do_not_match'.tr(context)),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red[700], size: 28),
          const SizedBox(width: 12),
          Text('confirmation'.tr(context),
              style: TextStyle(
                  color: theme.colorScheme.onSurface)),
        ]),
        content: Text(
          'confirm_delete_account_message'.tr(context),
          style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(context)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600]),
            child: Text('delete_permanently'.tr(context),
                style:
                    const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final result = await authService.deleteAccount();

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ));
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/welcome', (route) => false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'error'.tr(context)}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWarningCard(isDark),
              const SizedBox(height: 32),
              _buildInfoSection(theme, isDark),
              const SizedBox(height: 32),
              _buildEmailField(theme),
              const SizedBox(height: 16),
              _buildConfirmEmailField(theme),
              const SizedBox(height: 32),
              _buildConsequencesCard(theme),
              const SizedBox(height: 32),
              _buildDeleteButton(),
              const SizedBox(height: 16),
              _buildCancelButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'delete_account'.tr(context),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWarningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.withOpacity(0.15)
            : Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.red.withOpacity(0.4)
                : Colors.red[200]!,
            width: 2),
      ),
      child: Row(children: [
        Icon(Icons.warning_rounded,
            color: Colors.red[isDark ? 400 : 700], size: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              'warning'.tr(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[isDark ? 300 : 900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'this_action_is_irreversible'.tr(context),
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[isDark ? 400 : 800]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildInfoSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'verify_your_identity'.tr(context),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'to_delete_your_account_please_enter_your_email_addre'
              .tr(context),
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'your_current_email'
                    .tr(context)
                    .replaceAll('{email}', _userEmail),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'email_address'.tr(context),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          obscureText: _obscureEmail,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'enter_your_email'.tr(context),
            hintStyle: TextStyle(
                color: theme.textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.email_outlined,
                color: theme.textTheme.bodyMedium?.color),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureEmail
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: theme.textTheme.bodyMedium?.color,
              ),
              onPressed: () =>
                  setState(() => _obscureEmail = !_obscureEmail),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.dividerTheme.color!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.dividerTheme.color!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'email_is_required'.tr(context);
            }
            if (!value.contains('@')) {
              return 'please_enter_a_valid_email'.tr(context);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmEmailField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'confirm_email_address'.tr(context),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmEmailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 're_enter_your_email'.tr(context),
            hintStyle: TextStyle(
                color: theme.textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.email_outlined,
                color: theme.textTheme.bodyMedium?.color),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.dividerTheme.color!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.dividerTheme.color!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'please_confirm_your_email'.tr(context);
            }
            if (value != _emailController.text) {
              return 'emails_do_not_match'.tr(context);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConsequencesCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Text(
              'what_will_be_deleted'.tr(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildConsequenceItem(Icons.favorite,
              'all_your_favorite_monuments'.tr(context), theme),
          const SizedBox(height: 12),
          _buildConsequenceItem(Icons.history,
              'your_translation_history'.tr(context), theme),
          const SizedBox(height: 12),
          _buildConsequenceItem(Icons.chat_bubble,
              'chat_conversations'.tr(context), theme),
          const SizedBox(height: 12),
          _buildConsequenceItem(Icons.settings,
              'app_settings_and_preferences'.tr(context), theme),
          const SizedBox(height: 12),
          _buildConsequenceItem(Icons.person,
              'profile_information'.tr(context), theme),
        ],
      ),
    );
  }

  Widget _buildConsequenceItem(
      IconData icon, String text, ThemeData theme) {
    return Row(children: [
      Icon(icon,
          color: theme.textTheme.bodyMedium?.color, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color),
        ),
      ),
    ]);
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _deleteAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_forever, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'delete_my_account'.tr(context),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCancelButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed:
            _isLoading ? null : () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: theme.dividerTheme.color!, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'cancel'.tr(context),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}