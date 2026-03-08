import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/repositories/voice_translation_repository.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/history_provider.dart';
import '../../providers/theme_provider.dart'; // ✅ DARK MODE
import 'translation_cubit.dart';
import 'image_translation_tab.dart';

class TranslationScreen extends StatefulWidget {
  final int initialTab;
  const TranslationScreen({super.key, this.initialTab = 0});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TranslationCubit _translationCubit;

  bool _hateSpeechDetection = false;
  bool _censorOutput = false;
  String _sourceLanguage = 'en';
  String _targetLanguage = 'ar';

  final Map<String, String> _availableLanguages = {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'zh': '中文',
    'ja': '日本語',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
    _translationCubit = TranslationCubit();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _translationCubit.close();
    super.dispose();
  }

  void _saveToHistory(VoiceTranslationResult result) {
    context.read<HistoryProvider>().addTranslationToHistory(
          sourceText: result.originalText,
          translatedText: result.translatedText,
          sourceLang: result.detectedLanguage.toUpperCase(),
          targetLang: result.targetLanguage.toUpperCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DARK MODE
    final isDark = context.watch<ThemeProvider>().isDark;
    
    return BlocProvider.value(
      value: _translationCubit,
      child: Scaffold(
        endDrawer: const AppDrawer(),
        backgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF8F9FA), // ✅ DARK
        appBar: _buildAppBar(isDark),
        body: Column(children: [
          const SizedBox(height: 16),
          _buildTabs(isDark),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVoiceTab(isDark),
                const ImageTranslationTab(),
              ],
            ),
          ),
        ]),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F1923) : Colors.white, // ✅ DARK
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF2D2D2D)), // ✅ DARK
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('translation'.tr(context),
          style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2D2D2D), // ✅ DARK
              fontSize: 18,
              fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        Builder(
            builder: (ctx) => IconButton(
                  icon: Icon(Icons.more_vert,
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D)), // ✅ DARK
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                )),
      ],
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2530) : Colors.white, // ✅ DARK
          borderRadius: BorderRadius.circular(24)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24)),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF2D2D2D), // ✅ DARK
        labelStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.mic, size: 18),
                const SizedBox(width: 6),
                Text('voice'.tr(context))
              ])),
          Tab(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.image, size: 18),
                const SizedBox(width: 6),
                Text('image'.tr(context))
              ])),
        ],
      ),
    );
  }

  Widget _buildVoiceTab(bool isDark) {
    return BlocConsumer<TranslationCubit, TranslationState>(
      listener: (context, state) {
        if (state is TranslationSuccess) {
          _saveToHistory(state.result);
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            _buildHateSpeechToggle(isDark),
            const SizedBox(height: 16),
            _buildLanguageSelector(isDark),
            const SizedBox(height: 40),

            if (state is TranslationRecording)
              Text('🔴 ${'listening'.tr(context)}...',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500)),

            if (state is TranslationLoading)
              Column(children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'translating'.tr(context),
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey), // ✅ DARK
                ),
              ]),

            const SizedBox(height: 20),
            _buildRecordingButton(state),
            const SizedBox(height: 16),

            if (state is TranslationInitial)
              Text('tap_to_start_recording'.tr(context),
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : AppColors.textSecondary)), // ✅ DARK

            if (state is TranslationError)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: isDark ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50], // ✅ DARK
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errorKey
                          .tr(context)
                          .replaceAll('{error}', state.errorDetail),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ]),
              ),

            const SizedBox(height: 30),
            if (state is TranslationSuccess)
              _buildVoiceResults(state.result, isDark),
          ]),
        );
      },
    );
  }

  Widget _buildRecordingButton(TranslationState state) {
    final isRecording = state is TranslationRecording;
    final isLoading = state is TranslationLoading;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              if (isRecording) {
                await _translationCubit.stopAndTranslate(
                  _targetLanguage,
                  checkHateSpeech: _hateSpeechDetection,
                  censorOutput: _censorOutput,
                );
              } else {
                await _translationCubit.startRecording();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isRecording ? 150 : 140,
        height: isRecording ? 150 : 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.red : AppColors.primary)
                  .withOpacity(0.3),
              blurRadius: isRecording ? 50 : 40,
              spreadRadius: isRecording ? 25 : 20,
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isLoading
                ? Colors.grey
                : isRecording
                    ? Colors.red
                    : AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLoading
                ? Icons.hourglass_empty
                : isRecording
                    ? Icons.stop
                    : Icons.mic,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceResults(VoiceTranslationResult result, bool isDark) {
    return Column(children: [
      _buildResultCard(
        isDark: isDark,
        icon: Icons.mic,
        language:
            '${result.detectedLanguage.toUpperCase()} ${'original_label'.tr(context)}',
        text: result.originalText,
        showFavorite: false,
        onSpeakTap: null,
      ),
      const SizedBox(height: 12),
      _buildResultCard(
        isDark: isDark,
        icon: Icons.translate,
        language:
            '${result.targetLanguage.toUpperCase()} ${'translation_label'.tr(context)}',
        text: result.translatedText,
        showFavorite: true,
        onSpeakTap: result.audioUrl != null
            ? () => _translationCubit.playAudio(result.audioUrl!)
            : null,
      ),
      const SizedBox(height: 12),
      if (_hateSpeechDetection) _buildHateSpeechCard(result.hateSpeech, isDark),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildResultCard({
    required bool isDark, // ✅ DARK
    required IconData icon,
    required String language,
    required String text,
    required bool showFavorite,
    VoidCallback? onSpeakTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2530) : Colors.white, // ✅ DARK
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04), // ✅ DARK
              blurRadius: 8)
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(icon, size: 16, color: isDark ? Colors.grey[400] : AppColors.textSecondary), // ✅ DARK
          const SizedBox(width: 6),
          Text(language,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary)), // ✅ DARK
          const Spacer(),
          if (showFavorite)
            Icon(Icons.favorite_border,
                size: 20, color: isDark ? Colors.grey[400] : AppColors.textSecondary), // ✅ DARK
        ]),
        const SizedBox(height: 12),
        Text(text,
            style: TextStyle(
                fontSize: 15, color: isDark ? Colors.white : const Color(0xFF2D2D2D))), // ✅ DARK
        const SizedBox(height: 12),
        Row(children: [
          GestureDetector(
            onTap: onSpeakTap,
            child: Icon(Icons.volume_up,
                size: 20,
                color: onSpeakTap != null
                    ? AppColors.primary
                    : (isDark ? Colors.grey[600] : Colors.grey)), // ✅ DARK
          ),
          const Spacer(),
          if (showFavorite) ...[
            Icon(Icons.copy_outlined,
                size: 20, color: isDark ? Colors.grey[400] : AppColors.textSecondary), // ✅ DARK
            const SizedBox(width: 16),
            Icon(Icons.share_outlined,
                size: 20, color: isDark ? Colors.grey[400] : AppColors.textSecondary), // ✅ DARK
          ],
        ]),
      ]),
    );
  }

  Widget _buildHateSpeechCard(HateSpeechResult? hate, bool isDark) {
    final level = hate?.level ?? 'safe';
    final confidence = hate?.confidence ?? 0.0;
    final message = hate?.message ?? '✅ Aucun contenu offensant détecté';
    final categories = hate?.categories ?? <String>[];
    final isHate = hate?.isHateSpeech ?? false;

    final Color bgColor;
    final Color iconColor;
    final Color borderColor;
    final IconData statusIcon;

    switch (level) {
      case 'danger':
        bgColor = isDark ? const Color(0xFF3A1F1F) : const Color(0xFFFFEBEE); // ✅ DARK
        iconColor = Colors.red;
        borderColor = isDark ? Colors.red.shade800 : Colors.red.shade200; // ✅ DARK
        statusIcon = Icons.dangerous_outlined;
        break;
      case 'warning':
        bgColor = isDark ? const Color(0xFF3A2F1F) : const Color(0xFFFFF8E1); // ✅ DARK
        iconColor = Colors.orange;
        borderColor = isDark ? Colors.orange.shade800 : Colors.orange.shade200; // ✅ DARK
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        bgColor = isDark ? const Color(0xFF1F3A1F) : const Color(0xFFE8F5E9); // ✅ DARK
        iconColor = Colors.green;
        borderColor = isDark ? Colors.green.shade800 : Colors.green.shade200; // ✅ DARK
        statusIcon = Icons.verified_user_outlined;
    }

    final String badge;
    switch (level) {
      case 'danger':
        badge = 'level_danger'.tr(context);
        break;
      case 'warning':
        badge = 'level_warning'.tr(context);
        break;
      default:
        badge = 'level_safe'.tr(context);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(Icons.shield_outlined, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text('detected_speech'.tr(context),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: iconColor)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: iconColor),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(statusIcon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
              child: Text(message,
                  style:
                      TextStyle(fontSize: 13, color: iconColor))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text(
            'confidence'
                .tr(context)
                .replaceAll('{percent}',
                    '${(confidence * 100).toInt()}'),
            style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: iconColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 6,
            ),
          )),
        ]),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
              spacing: 6,
              runSpacing: 4,
              children: categories
                  .map((cat) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: iconColor.withOpacity(0.3)),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 10,
                                color: iconColor,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList()),
        ],
        if (isHate) ...[
          const SizedBox(height: 10),
          Divider(color: iconColor.withOpacity(0.2), height: 1),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.visibility_off_outlined,
                size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              'censor_text'.tr(context),
              style: TextStyle(fontSize: 12, color: iconColor),
            ),
            const Spacer(),
            Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _censorOutput,
                  onChanged: (v) =>
                      setState(() => _censorOutput = v),
                  activeColor: iconColor,
                )),
          ]),
        ],
      ]),
    );
  }

  Widget _buildHateSpeechToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2530) : Colors.white, // ✅ DARK
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04), // ✅ DARK
              blurRadius: 8)
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: isDark ? Colors.red[900]?.withOpacity(0.3) : const Color(0xFFFFEBEE), // ✅ DARK
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_outlined,
                color: Color(0xFFE57373), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('hate_speech_detection'.tr(context),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2D2D2D))), // ✅ DARK
                const SizedBox(height: 2),
                Text('filter_offensive_content'.tr(context),
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : AppColors.textSecondary)), // ✅ DARK
              ])),
          Switch(
            value: _hateSpeechDetection,
            onChanged: (value) => setState(() {
              _hateSpeechDetection = value;
              if (!value) _censorOutput = false;
            }),
            activeColor: AppColors.primary,
          ),
        ]),
        if (_hateSpeechDetection)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 52),
            child: Row(children: [
              Icon(Icons.visibility_off_outlined,
                  size: 15, color: isDark ? Colors.grey[500] : AppColors.textSecondary), // ✅ DARK
              const SizedBox(width: 6),
              Text(
                'auto_censor'.tr(context),
                style: TextStyle(
                    fontSize: 12, color: isDark ? Colors.grey[500] : AppColors.textSecondary), // ✅ DARK
              ),
              const Spacer(),
              Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _censorOutput,
                    onChanged: (v) =>
                        setState(() => _censorOutput = v),
                    activeColor: AppColors.primary,
                  )),
            ]),
          ),
      ]),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    return Row(children: [
      Expanded(
          child: _buildLangButton(_sourceLanguage, isSource: true, isDark: isDark)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GestureDetector(
          onTap: () => setState(() {
            final tmp = _sourceLanguage;
            _sourceLanguage = _targetLanguage;
            _targetLanguage = tmp;
          }),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.swap_horiz,
                color: AppColors.primary, size: 24),
          ),
        ),
      ),
      Expanded(
          child: _buildLangButton(_targetLanguage, isSource: false, isDark: isDark)),
    ]);
  }

  Widget _buildLangButton(String code, {required bool isSource, required bool isDark}) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(isSource: isSource),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2530) : Colors.white, // ✅ DARK
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(Icons.language, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
            _availableLanguages[code] ?? code,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF2D2D2D)), // ✅ DARK
            overflow: TextOverflow.ellipsis,
          )),
          Icon(Icons.keyboard_arrow_down,
              size: 20, color: isDark ? Colors.grey[500] : AppColors.textSecondary), // ✅ DARK
        ]),
      ),
    );
  }

  void _showLanguagePicker({required bool isSource}) {
    final isDark = context.read<ThemeProvider>().isDark; // ✅ DARK
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, sc) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2530) : Colors.white, // ✅ DARK
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300], // ✅ DARK
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              isSource
                  ? 'select_source_language'.tr(context)
                  : 'select_target_language'.tr(context),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D2D2D)), // ✅ DARK
            ),
            const SizedBox(height: 20),
            Expanded(
                child: ListView.builder(
              controller: sc,
              itemCount: _availableLanguages.length,
              itemBuilder: (context, i) {
                final code =
                    _availableLanguages.keys.elementAt(i);
                final name = _availableLanguages[code]!;
                final sel = isSource
                    ? _sourceLanguage == code
                    : _targetLanguage == code;
                return ListTile(
                  leading: Icon(Icons.language,
                      color:
                          sel ? AppColors.primary : (isDark ? Colors.grey[600] : Colors.grey), // ✅ DARK
                      size: 28),
                  title: Text(name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: sel
                              ? AppColors.primary
                              : (isDark ? Colors.white : const Color(0xFF2D2D2D)))), // ✅ DARK
                  trailing: sel
                      ? Icon(Icons.check_circle,
                          color: AppColors.primary, size: 24)
                      : null,
                  onTap: () {
                    setState(() {
                      if (isSource) {
                        _sourceLanguage = code;
                      } else {
                        _targetLanguage = code;
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            )),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
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
    return GestureDetector(
      onTap: () {
        if (index == 0) Navigator.pushNamed(context, '/home');
        if (index == 1) Navigator.pushNamed(context, '/monuments');
        if (index == 3) Navigator.pushNamed(context, '/chatbot');
        if (index == 4) Navigator.pushNamed(context, '/profile');
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: index == 2
              ? AppColors.primary
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}