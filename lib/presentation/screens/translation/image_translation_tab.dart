import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import 'translation_cubit.dart';

class ImageTranslationTab extends StatefulWidget {
  const ImageTranslationTab({super.key});

  @override
  State<ImageTranslationTab> createState() => _ImageTranslationTabState();
}

class _ImageTranslationTabState extends State<ImageTranslationTab>
    with TickerProviderStateMixin {
  File? _selectedImage;
  String _sourceLanguage = 'auto';
  String _targetLanguage = 'fr';
  bool _hateSpeechDetection = true;
  bool _enhance = true;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Map<String, String> get _availableLanguages => {
    'auto': 'auto_detect'.tr(context),
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920, maxHeight: 1080, imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _selectedImage = File(photo.path));
        _showSnack('photo_captured'.tr(context), Colors.green);
      }
    } catch (e) {
      _showSnack('${'camera_error'.tr(context)}$e', Colors.red);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, maxHeight: 1080, imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        _showSnack('image_selected'.tr(context), Colors.green);
      }
    } catch (e) {
      _showSnack('${'gallery_error'.tr(context)}$e', Colors.red);
    }
  }

  Future<void> _translateImage() async {
    if (_selectedImage == null) {
      _showSnack('select_image_first'.tr(context), Colors.orange);
      return;
    }
    context.read<TranslationCubit>().translateImage(
      imageFile: _selectedImage!,
      sourceLang: _sourceLanguage,
      targetLang: _targetLanguage,
      enhance: _enhance,
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return BlocListener<TranslationCubit, TranslationState>(
      listener: (context, state) {
        if (state is TranslationError) {
          _showSnack(
            '❌ ${state.errorKey.tr(context).replaceAll('{error}', state.errorDetail)}',
            Colors.red,
          );
        }
      },
      child: BlocBuilder<TranslationCubit, TranslationState>(
        builder: (context, state) {
          final isLoading = state is TranslationLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildOptionsCard(),
                const SizedBox(height: 12),
                _buildLanguageSelector(),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _buildActionButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'take_photo'.tr(context),
                    onTap: _takePhoto,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'gallery'.tr(context),
                    onTap: _pickImage,
                  )),
                ]),
                const SizedBox(height: 16),
                _buildImagePreview(isLoading),
                const SizedBox(height: 16),
                _buildTranslateButton(state),
                const SizedBox(height: 20),
                if (isLoading) ...[
                  _buildLoadingSteps(),
                  const SizedBox(height: 30),
                ],
                if (state is ImageTranslationSuccess) ...[
                  _buildOcrResult(state),
                  const SizedBox(height: 12),
                  _buildTranslationResult(state),
                  const SizedBox(height: 12),
                  if (_hateSpeechDetection) _buildHateSpeechCard(state),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        _buildToggleRow(
          icon: Icons.auto_fix_high_outlined,
          iconBg: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1E88E5),
          title: 'ai_enhancement'.tr(context),
          value: _enhance,
          onChanged: (v) => setState(() => _enhance = v),
        ),
        Divider(height: 14, thickness: 0.5, color: theme.dividerColor),
        _buildToggleRow(
          icon: Icons.shield_outlined,
          iconBg: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFE57373),
          title: 'hate_speech_detection'.tr(context),
          value: _hateSpeechDetection,
          onChanged: (v) => setState(() => _hateSpeechDetection = v),
        ),
      ]),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: iconBg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: subtitle != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
                Text(subtitle, style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
              ])
            : Text(title, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: colorScheme.onSurface)),
      ),
      Transform.scale(
        scale: 0.85,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    ]);
  }

  Widget _buildLanguageSelector() {
    return Row(children: [
      Expanded(child: _buildLangButton(_sourceLanguage, isSource: true)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: GestureDetector(
          onTap: () => setState(() {
            final tmp = _sourceLanguage;
            _sourceLanguage = _targetLanguage;
            _targetLanguage = tmp;
          }),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.swap_horiz, color: AppColors.primary),
          ),
        ),
      ),
      Expanded(child: _buildLangButton(_targetLanguage, isSource: false)),
    ]);
  }

  Widget _buildLangButton(String code, {required bool isSource}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: () => _showLanguagePicker(isSource: isSource),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(Icons.language, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(
            _availableLanguages[code] ?? code,
            style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface),
            overflow: TextOverflow.ellipsis,
          )),
          Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  void _showLanguagePicker({required bool isSource}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text(
            isSource
                ? 'source_language'.tr(context)
                : 'target_language'.tr(context),
            style: TextStyle(
                fontSize: 17, 
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          ...(_availableLanguages.entries.map((e) {
            final sel = isSource
                ? _sourceLanguage == e.key
                : _targetLanguage == e.key;
            return ListTile(
              leading: Icon(Icons.language,
                  color: sel ? AppColors.primary : Colors.grey),
              title: Text(e.value, style: TextStyle(
                color: sel ? AppColors.primary : colorScheme.onSurface,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              )),
              trailing: sel
                  ? Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  if (isSource) _sourceLanguage = e.key;
                  else _targetLanguage = e.key;
                });
                Navigator.pop(context);
              },
            );
          })),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8, offset: const Offset(0, 4),
          )],
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 12,
              fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildImagePreview(bool isLoading) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey.shade200),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: _selectedImage != null
          ? Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(_selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220),
              ),
              if (isLoading)
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.document_scanner_outlined,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('analyzing'.tr(context),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!isLoading)
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ])
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 56, 
                  color: isDark ? Colors.grey[700] : Colors.grey[300]),
              const SizedBox(height: 10),
              Text('select_or_take_photo'.tr(context),
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('supported_formats'.tr(context),
                  style: TextStyle(
                      fontSize: 11, 
                      color: isDark ? Colors.grey[500] : Colors.grey[400])),
            ]),
    );
  }

  Widget _buildTranslateButton(TranslationState state) {
    final isLoading = state is TranslationLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _translateImage,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _selectedImage != null ? AppColors.primary : Colors.grey,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate,
                      size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'translate_image'.tr(context),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingSteps() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.document_scanner_outlined,
                color: AppColors.primary, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        _buildStep(1, Icons.auto_fix_high_outlined,
            'image_enhancement_step'.tr(context), true),
        _buildStepConnector(),
        _buildStep(2, Icons.text_fields_outlined,
            'ocr_extraction_step'.tr(context), true),
        _buildStepConnector(),
        _buildStep(3, Icons.translate_outlined,
            'translation_step'.tr(context), false),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 4,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ]),
    );
  }

  Widget _buildStep(int num, IconData icon, String label, bool active) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = active ? AppColors.primary : (isDark ? Colors.grey[600]! : Colors.grey[400]!);
    
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? AppColors.primary.withOpacity(0.4)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(
        fontSize: 13,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        color: active 
            ? theme.colorScheme.onSurface 
            : (isDark ? Colors.grey[600] : Colors.grey[400]),
      )),
      const Spacer(),
      if (active)
        SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
    ]);
  }

  Widget _buildStepConnector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 3, bottom: 3),
      child: Container(
          width: 2, 
          height: 12, 
          color: isDark ? Colors.grey[800] : Colors.grey[200]),
    );
  }

  Widget _buildOcrResult(ImageTranslationSuccess state) {
    if (state.extractedText.isEmpty) {
      return _buildInfoCard(
        icon: Icons.info_outline,
        color: Colors.orange,
        title: 'no_text_detected'.tr(context),
        message: 'try_clearer_image'.tr(context),
      );
    }
    return _buildResultCard(
      icon: Icons.document_scanner_outlined,
      tag: '${state.sourceLang.toUpperCase()} · ${'text'.tr(context)} · ${state.totalBlocks} bloc${state.totalBlocks > 1 ? "s" : ""}',
      text: state.extractedText,
      tagColor: Colors.blueAccent,
    );
  }

  Widget _buildTranslationResult(ImageTranslationSuccess state) {
    if (state.translatedText.isEmpty) return const SizedBox();
    return _buildResultCard(
      icon: Icons.translate_outlined,
      tag: '${state.targetLang.toUpperCase()} · ${'translation'.tr(context)}',
      text: state.translatedText,
      tagColor: AppColors.primary,
      showCopy: true,
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required String tag,
    required String text,
    required Color tagColor,
    bool showCopy = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 13, color: tagColor),
              const SizedBox(width: 5),
              Text(tag, style: TextStyle(
                  fontSize: 11, color: tagColor,
                  fontWeight: FontWeight.w700)),
            ]),
          ),
          const Spacer(),
          if (showCopy)
            GestureDetector(
              onTap: () =>
                  _showSnack('text_copied'.tr(context), Colors.green),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.copy_outlined,
                    size: 16, color: AppColors.textSecondary),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text(text, style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            height: 1.5)),
      ]),
    );
  }

  Widget _buildHateSpeechCard(ImageTranslationSuccess state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOffensive = state.hasOffensiveContent;
    final message = state.hateSpeechMessage;
    final words = state.offensiveWords;

    final color = isOffensive ? Colors.red : Colors.green;
    final bgColor = isOffensive
        ? (isDark ? const Color(0xFF3D1A1A) : const Color(0xFFFFEBEE))
        : (isDark ? const Color(0xFF1A3D1A) : const Color(0xFFE8F5E9));
    final icon = isOffensive
        ? Icons.dangerous_outlined
        : Icons.verified_user_outlined;
    final badge = isOffensive
        ? 'offensive_badge'.tr(context)
        : 'clean_badge'.tr(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Text('content_analysis'.tr(context),
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: color)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badge, style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: TextStyle(
              fontSize: 13, color: color, height: 1.4))),
        ]),
        if (words.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: words.map((w) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(w, style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
        if (isOffensive && state.censoredText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: color.withOpacity(0.2)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.visibility_off_outlined,
                size: 13, color: color),
            const SizedBox(width: 6),
            Text('censored_text'.tr(context),
                style: TextStyle(fontSize: 11, color: color,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text(state.censoredText, style: TextStyle(
              fontSize: 13, color: color.withOpacity(0.8))),
        ],
      ]),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(title, style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color)),
          const SizedBox(height: 2),
          Text(message, style: TextStyle(
              fontSize: 12, color: color.withOpacity(0.8))),
        ])),
      ]),
    );
  }
}