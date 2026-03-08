import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/conversation_model.dart';
import '../../data/database/conversation_database.dart';
import '../../data/repositories/chat_bot_repository.dart';

class ConversationProvider with ChangeNotifier {
  final ConversationDatabase _db = ConversationDatabase.instance;
  final ChatBotRepository _chatRepo = ChatBotRepository();

  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String _searchQuery = '';

  List<Conversation> get conversations => _searchQuery.isEmpty
      ? _conversations
      : _conversations.where((c) {
          return c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.messages.any((m) =>
                  m.text.toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList();

  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasConversations => _conversations.isNotEmpty;

  // ✅ Fermer la conversation courante sans effacer la liste
  // NE PAS appeler notifyListeners ici pour éviter rebuild inutile au dispose
  // Appelé dans dispose() de ChatBotScreen
  void closeConversation() {
    _currentConversation = null;
    _chatRepo.clearHistory();
    notifyListeners();
  }

  // ✅ Vider tout en mémoire (appelé au login autre user)
  void clearConversations() {
    _conversations = [];
    _currentConversation = null;
    _chatRepo.clearHistory();
    notifyListeners();
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _db.readAll();
      debugPrint('✅ ${_conversations.length} conversations chargées');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur chargement conversations : $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createNewConversation() async {
    final now = DateTime.now();
    final newConv = Conversation(
      id: const Uuid().v4(),
      title: _generateTitle(now),
      createdAt: now,
      updatedAt: now,
      messages: [],
    );

    try {
      await _db.create(newConv);
      _conversations.insert(0, newConv);
      _currentConversation = newConv;
      _chatRepo.clearHistory();
      debugPrint('Nouvelle conversation créée : ${newConv.id}');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur création conversation : $e');
    }
  }

  Future<void> selectConversation(String conversationId) async {
    try {
      final conv = await _db.read(conversationId);
      if (conv != null) {
        _currentConversation = conv;
        _chatRepo.clearHistory();
        debugPrint('Conversation sélectionnée : ${conv.title}');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur sélection conversation : $e');
    }
  }

  Future<void> renameConversation(String id, String newTitle) async {
    try {
      final conv = _conversations.firstWhere((c) => c.id == id);
      final updated = conv.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );

      await _db.update(updated);

      final index = _conversations.indexWhere((c) => c.id == id);
      if (index != -1) _conversations[index] = updated;

      if (_currentConversation?.id == id) _currentConversation = updated;

      debugPrint('Conversation renommée : $newTitle');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur renommage : $e');
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _db.delete(id);
      _conversations.removeWhere((c) => c.id == id);

      if (_currentConversation?.id == id) {
        _currentConversation = null;
        _chatRepo.clearHistory();
      }

      debugPrint('Conversation supprimée : $id');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur suppression : $e');
    }
  }

  Future<void> deleteAllConversations() async {
    try {
      await _db.deleteAll();
      _conversations.clear();
      _currentConversation = null;
      _chatRepo.clearHistory();
      debugPrint('Toutes les conversations supprimées');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur suppression totale : $e');
    }
  }

  Future<void> sendMessage(String text, {String? city}) async {
    if (text.trim().isEmpty) return;

    if (_currentConversation == null) {
      await createNewConversation();
    }

    final userMessage = ConversationMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ConversationMessage>.from(
      _currentConversation!.messages,
    )..add(userMessage);

    _currentConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final chatMessage = await _chatRepo.sendMessage(
        text,
        city: city,
        userId: 'default',
      );

      final botMessage = ConversationMessage(
        text: chatMessage.text,
        isUser: false,
        timestamp: chatMessage.timestamp,
        imageUrl: chatMessage.imageUrl,
        weather: chatMessage.weather,
        monument: chatMessage.monument,
        location: chatMessage.location,
        source: chatMessage.source,
      );

      final finalMessages = List<ConversationMessage>.from(
        _currentConversation!.messages,
      )..add(botMessage);

      _currentConversation = _currentConversation!.copyWith(
        messages: finalMessages,
        updatedAt: DateTime.now(),
      );

      if (finalMessages.length == 2) {
        _currentConversation = _currentConversation!.copyWith(
          title: _generateSmartTitle(text),
        );
      }

      await _db.update(_currentConversation!);

      final index = _conversations.indexWhere(
        (c) => c.id == _currentConversation!.id,
      );
      if (index != -1) {
        _conversations[index] = _currentConversation!;
        _conversations.removeAt(index);
        _conversations.insert(0, _currentConversation!);
      }

      debugPrint('Message envoyé et sauvegardé');
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur envoi message : $e');

      final errorMessage = ConversationMessage(
        text: e.toString().replaceAll('Exception: ', ''),
        isUser: false,
        timestamp: DateTime.now(),
      );

      final messagesWithError = List<ConversationMessage>.from(
        _currentConversation!.messages,
      )..add(errorMessage);

      _currentConversation = _currentConversation!.copyWith(
        messages: messagesWithError,
      );
    }

    _isSending = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  String _generateTitle(DateTime date) {
    final hour = date.hour;
    if (hour < 12) return 'Conversation du matin';
    if (hour < 18) return 'Conversation de l\'après-midi';
    return 'Conversation du soir';
  }

  String _generateSmartTitle(String firstMessage) {
    if (firstMessage.length <= 40) return firstMessage;
    final words = firstMessage.split(' ');
    String title = '';
    for (final word in words) {
      if ((title + word).length > 40) break;
      title += '$word ';
    }
    return '${title.trim()}...';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}