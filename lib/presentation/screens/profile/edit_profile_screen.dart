import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;

  bool _showEmailSection = false;
  final _currentEmailController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _confirmEmailController = TextEditingController();

  bool _showPasswordSection = false;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _hasDefaultImage = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ Attendre loadUserData() → user_id dispo avant photo
      await context.read<UserProvider>().loadUserData();
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        if (_nameController.text.isEmpty) {
          _nameController.text = userProvider.username;
        }
        if (_usernameController.text.isEmpty) {
          _usernameController.text = userProvider.username;
        }
        await _loadProfileImage();
      }
    });
  }

  // ✅ PAS de didChangeDependencies() pour la photo

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentEmailController.dispose();
    _newEmailController.dispose();
    _confirmEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String> _getPhotoKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    return 'profile_image_path_$userId';
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    if (userId == 0) return; // ✅ garde-fou
    final key = 'profile_image_path_$userId';
    final imagePath = prefs.getString(key);
    if (imagePath != null && await File(imagePath).exists()) {
      if (mounted) {
        setState(() {
          _profileImagePath = imagePath;
          _hasDefaultImage = false;
        });
      }
    }
  }

  Future<void> _saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getPhotoKey();
    await prefs.setString(key, path);
  }

  Future<void> _deleteProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getPhotoKey();
    await prefs.remove(key);
  }

  void _showPhotoOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerTheme.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('profile_picture'.tr(context),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle),
                child:
                    Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: Text('take_photo'.tr(context),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.photo_library,
                    color: Colors.blue),
              ),
              title: Text('choose_from_gallery'.tr(context),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (!_hasDefaultImage || _profileImagePath != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red),
                ),
                title: Text('remove_photo'.tr(context),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor:
                        theme.dividerTheme.color?.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('cancel'.tr(context),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path;
          _hasDefaultImage = false;
        });
        await _saveProfileImagePath(pickedFile.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('photo_updated_successfully'.tr(context)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'error'.tr(context)}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _profileImagePath = null;
      _hasDefaultImage = true;
    });
    await _deleteProfileImagePath();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('photo_removed'.tr(context)),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );
      try {
        final userProvider = context.read<UserProvider>();
        String? newEmail;
        if (_showEmailSection && _newEmailController.text.isNotEmpty) {
          newEmail = _newEmailController.text;
        }
        final success = await userProvider.updateProfile(
          username: _usernameController.text,
          email: newEmail,
        );
        if (mounted) Navigator.pop(context);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('profile_updated_successfully'.tr(context)),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ));
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('failed_to_update_profile'.tr(context)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'error'.tr(context)}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAvatarSection(userProvider.username, theme),
                const SizedBox(height: 32),
                _buildTextField(
                  label: 'name'.tr(context),
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'username'.tr(context),
                  controller: _usernameController,
                  prefixIcon: Icons.alternate_email,
                  theme: theme,
                ),
                const SizedBox(height: 24),
                _buildSectionToggle(
                  icon: Icons.email_outlined,
                  label: 'change_email'.tr(context),
                  isOpen: _showEmailSection,
                  onTap: () => setState(
                      () => _showEmailSection = !_showEmailSection),
                  theme: theme,
                ),
                if (_showEmailSection) ...[
                  const SizedBox(height: 16),
                  _buildEmailSection(theme),
                ],
                const SizedBox(height: 16),
                _buildSectionToggle(
                  icon: Icons.lock_outline,
                  label: 'change_password'.tr(context),
                  isOpen: _showPasswordSection,
                  onTap: () => setState(() =>
                      _showPasswordSection = !_showPasswordSection),
                  theme: theme,
                ),
                if (_showPasswordSection) ...[
                  const SizedBox(height: 16),
                  _buildPasswordSection(theme),
                ],
                const SizedBox(height: 40),
              ],
            ),
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
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('edit_profile'.tr(context),
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
      centerTitle: false,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: TextButton(
            onPressed: _handleSave,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('save'.tr(context),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(String username, ThemeData theme) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipOval(
                child: _profileImagePath != null
                    ? Image.file(File(_profileImagePath!),
                        fit: BoxFit.cover)
                    : _hasDefaultImage
                        ? Container(
                            decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient),
                            child: Center(
                              child: Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          )
                        : Container(
                            color:
                                AppColors.primary.withOpacity(0.15),
                            child: Icon(Icons.person,
                                size: 50, color: AppColors.primary),
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _showPhotoOptions,
          child: Text('edit_picture'.tr(context),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildSectionToggle({
    required IconData icon,
    required String label,
    required bool isOpen,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerTheme.color!),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: theme.textTheme.bodyMedium?.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface)),
            ),
            Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    required ThemeData theme,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            prefixIcon: Icon(prefixIcon,
                size: 20,
                color: theme.textTheme.bodyMedium?.color),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.dividerTheme.color!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.dividerTheme.color!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'this_field_is_required'.tr(context);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailSection(ThemeData theme) {
    return Column(
      children: [
        _buildEmailField(
            label: 'current_email'.tr(context),
            controller: _currentEmailController,
            hintText: 'enter_current_email'.tr(context),
            theme: theme,
            validator: (_) => null),
        const SizedBox(height: 16),
        _buildEmailField(
          label: 'new_email'.tr(context),
          controller: _newEmailController,
          hintText: 'enter_new_email'.tr(context),
          theme: theme,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'please_enter_a_valid_email'.tr(context);
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildEmailField(
          label: 're_enter_new_email'.tr(context),
          controller: _confirmEmailController,
          hintText: 'confirm_new_email'.tr(context),
          theme: theme,
          validator: (value) {
            if (_newEmailController.text.isNotEmpty &&
                value != _newEmailController.text) {
              return 'emails_do_not_match'.tr(context);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ThemeData theme,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            hintText: hintText,
            hintStyle:
                TextStyle(color: theme.textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.email_outlined,
                size: 20,
                color: theme.textTheme.bodyMedium?.color),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.dividerTheme.color!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.dividerTheme.color!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordSection(ThemeData theme) {
    return Column(
      children: [
        _buildPasswordField(
          label: 'current_password'.tr(context),
          controller: _currentPasswordController,
          isVisible: _isCurrentPasswordVisible,
          theme: theme,
          onToggleVisibility: () => setState(() =>
              _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
          validator: (_) => null,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'new_password'.tr(context),
          controller: _newPasswordController,
          isVisible: _isNewPasswordVisible,
          theme: theme,
          onToggleVisibility: () => setState(
              () => _isNewPasswordVisible = !_isNewPasswordVisible),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                value.length < 6) {
              return 'password_must_be_at_least_6_characters'
                  .tr(context);
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 're_enter_new_password'.tr(context),
          controller: _confirmPasswordController,
          isVisible: _isConfirmPasswordVisible,
          theme: theme,
          onToggleVisibility: () => setState(() =>
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          validator: (value) {
            if (_newPasswordController.text.isNotEmpty &&
                value != _newPasswordController.text) {
              return 'passwords_do_not_match'.tr(context);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required ThemeData theme,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            hintText: '••••••••',
            hintStyle:
                TextStyle(color: theme.textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.lock_outline,
                size: 20,
                color: theme.textTheme.bodyMedium?.color),
            suffixIcon: IconButton(
              icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: theme.textTheme.bodyMedium?.color),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.dividerTheme.color!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.dividerTheme.color!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}