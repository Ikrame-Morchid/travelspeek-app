import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/repositories/voice_translation_repository.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/chatbot_drawer.dart';
import '../../../data/models/conversation_model.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceTranslationRepository _voiceRepo = VoiceTranslationRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().loadConversations();
    });
  }

  @override
  void dispose() {
    // ✅ Fermer la conversation courante quand on quitte le chat
    context.read<ConversationProvider>().closeConversation();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await context.read<ConversationProvider>().sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      try {
        final audioFile = await _voiceRepo.stopRecording();
        if (audioFile == null) return;
        final result = await _voiceRepo.translateAudio(
          audioFilePath: audioFile.path,
          targetLang: 'fr',
          sourceLang: 'auto',
        );
        if (result != null && result.originalText.isNotEmpty) {
          await context.read<ConversationProvider>().sendMessage(result.originalText);
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'error_prefix'.tr(context)}${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        await _voiceRepo.startRecording();
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _openMaps(Map<String, dynamic> location) async {
    final lat = location['lat'];
    final lon = location['lon'];
    final mapsUrl = lat != null && lon != null
        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lon'
        : location['maps_url'] ?? '';
    final uri = Uri.parse(mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F4F8);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ChatBotDrawer(),
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark),
      body: Consumer<ConversationProvider>(
        builder: (context, provider, _) {
          final messages = provider.currentConversation?.messages ?? [];
          if (messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        itemCount: messages.length + (provider.isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && provider.isSending) {
                            return _buildTypingIndicator(isDark);
                          }
                          return _buildMessageBubble(messages[index], isDark);
                        },
                      ),
              ),
              _buildQuickActions(isDark),
              _buildInputBar(provider, isDark),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF0F1923) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return AppBar(
      backgroundColor: bgColor,
      elevation: isDark ? 0 : 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer<ConversationProvider>(
        builder: (context, provider, _) {
          final title = provider.currentConversation?.title ?? 'TravelBot';
          return Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  title.length > 25 ? '${title.substring(0, 25)}...' : title,
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('ai_tourist_guide'.tr(context), style: TextStyle(color: subtitleColor, fontSize: 11)),
              ]),
            ),
          ]);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: isDark ? Colors.white : const Color(0xFF2D2D2D)),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final chipBg = isDark ? const Color(0xFF1A2530) : Colors.white;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
        child: Column(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text('chatbot_greeting'.tr(context),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('chatbot_description'.tr(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: subtitleColor, height: 1.5)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10, runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _startChip('chip_hassan_mosque'.tr(context), chipBg),
              _startChip('chip_weather_fes'.tr(context), chipBg),
              _startChip('chip_medina_marrakech'.tr(context), chipBg),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _startChip(String label, Color bg) {
    return GestureDetector(
      onTap: () => _sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildMessageBubble(ConversationMessage message, bool isDark) {
    final botBubbleBg = isDark ? const Color(0xFF1A2530) : Colors.white;
    final botTextColor = isDark ? Colors.white : const Color(0xFF2D2D2D);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.text.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: message.isUser ? AppColors.primary : botBubbleBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 18),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Text(message.text,
                        style: TextStyle(
                            fontSize: 15,
                            color: message.isUser ? Colors.white : botTextColor,
                            height: 1.4)),
                  ),
                if (message.weather != null) ...[
                  const SizedBox(height: 8),
                  _buildWeatherCard(message.weather!),
                ],
                if (message.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(message.imageUrl!,
                        width: MediaQuery.of(context).size.width * 0.65,
                        height: 160, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                ],
                if (message.location != null) ...[
                  const SizedBox(height: 8),
                  _buildLocationButton(message.location!),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: const Center(child: Icon(Icons.person, color: Colors.white, size: 18)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> weather) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.85), AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Text('🌤', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(weather['city'] ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis),
            Text('${weather['temp']}°C — ${weather['description']}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLocationButton(Map<String, dynamic> location) {
    return GestureDetector(
      onTap: () => _openMaps(location),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[300]!),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 6),
          Text('view_on_google_maps'.tr(context),
              style: TextStyle(fontSize: 13, color: Colors.blue[700], fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    final bubbleBg = isDark ? const Color(0xFF1A2530) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 32, height: 32,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => _buildDot(i))),
        ),
      ]),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 150),
      builder: (context, double value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3 + value * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () { if (mounted) setState(() {}); },
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F4F8);
    final textColor = isDark ? Colors.white70 : const Color(0xFF2D2D2D);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      color: bgColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _quickChip(icon: Icons.wb_sunny_outlined, label: 'quick_weather'.tr(context),
              bg: const Color(0xFFFFF8E1), iconColor: Colors.orange, textColor: textColor,
              onTap: () => _sendMessage('quick_weather_question'.tr(context))),
          const SizedBox(width: 8),
          _quickChip(icon: Icons.account_balance_outlined, label: 'quick_monuments'.tr(context),
              bg: const Color(0xFFE0F2F1), iconColor: AppColors.primary, textColor: textColor,
              onTap: () => _sendMessage('quick_monuments_question'.tr(context))),
          const SizedBox(width: 8),
          _quickChip(icon: Icons.explore_outlined, label: 'quick_culture'.tr(context),
              bg: const Color(0xFFEDE7F6), iconColor: Colors.purple, textColor: textColor,
              onTap: () => _sendMessage('quick_culture_question'.tr(context))),
        ]),
      ),
    );
  }

  Widget _quickChip({
    required IconData icon, required String label, required Color bg,
    required Color iconColor, required Color textColor, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildInputBar(ConversationProvider provider, bool isDark) {
    final barBg = isDark ? const Color(0xFF1A2530) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F4F8);
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final hintColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(children: [
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: _isRecording ? Border.all(color: Colors.red, width: 1.5) : null,
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isRecording ? Colors.red : AppColors.primary, size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(30)),
              child: Center(
                child: TextField(
                  controller: _messageController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'chatbot_hint'.tr(context),
                    hintStyle: TextStyle(fontSize: 15, color: hintColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(fontSize: 15, color: textColor),
                  onSubmitted: (text) => _sendMessage(text),
                  enabled: !provider.isSending && !_isRecording,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: provider.isSending ? null : () => _sendMessage(_messageController.text),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: provider.isSending ? AppColors.primary.withOpacity(0.4) : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: provider.isSending
                  ? const Padding(padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}