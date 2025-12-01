// providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../models/conversation.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  String? _currentView;
  ChatService get chatService => _chatService;

  // Vous pouvez exposer les méthodes dont vous avez besoin
  Future<void> sendMessage(String message) async {
    await _chatService.sendMessage(message);
    notifyListeners();
  }

  Stream<List<Conversation>> getConversationsStream() {
    return _chatService.getConversationsStream();
  }

  Future<void> loadConversation(String conversationId) async {
    await _chatService.loadConversation(conversationId);
    notifyListeners();
  }

  Future<void> deleteConversation(String conversationId) async {
    await _chatService.deleteConversation(conversationId);
    notifyListeners();
  }

  void startNewConversation() {
    _chatService.startNewConversation();
    notifyListeners();
  }

  String? get currentView => _currentView;
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  void clearChat() {
    _chatService.clearHistory();
    notifyListeners();
  }
}
