// ══════════════════════════════════════════════════════
// lib/presentation/providers/chatbot_provider.dart
// ══════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import '../../../data/repositories/chat_bot_repository.dart';

enum ChatBotState { initial, sending, success, error }

class ChatBotProvider with ChangeNotifier {
  final ChatBotRepository _repo = ChatBotRepository();

  ChatBotState _state = ChatBotState.initial;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? currentCity; // ✅ null — le backend détecte depuis le message
  String userId = 'default';

  // Getters
  ChatBotState get state     => _state;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading         => _isLoading;
  String? get errorMessage   => _errorMessage;
  bool get hasMessages       => _messages.isNotEmpty;

  // Envoyer message 
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _state = ChatBotState.sending;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _repo.sendMessage(
        text,
        city: currentCity, // null sauf si l'user a défini une ville
        userId: userId,
      );
      _messages.add(reply);
      _state = ChatBotState.success;
    } catch (e) {
      _messages.add(ChatMessage(
        text: ' ${e.toString().replaceAll('Exception: ', '')}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _state = ChatBotState.error;
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  //  Changer la ville 
  void setCity(String? city) {
    currentCity = city;
    notifyListeners();
  }

  // Vider le chat 
  void clearChat() {
    _messages.clear();
    _repo.clearHistory();
    _state = ChatBotState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == ChatBotState.error) _state = ChatBotState.initial;
    notifyListeners();
  }
}