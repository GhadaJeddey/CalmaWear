import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'chat_history_screen.dart';
import '../dashboard/home_screen.dart';
import '../planner/planner_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String? fromScreen; // Pour savoir d'où on vient

  const ChatScreen({Key? key, this.fromScreen}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentBottomNavIndex = 3;

  @override
  void initState() {
    super.initState();
    // Charger la conversation de démo
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.chatService.loadDemoHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la conversation'),
        content: const Text(
          'Voulez-vous vraiment effacer tout l\'historique de chat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
              chatProvider.clearChat();
            },
            child: const Text('Effacer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildApiStatusBanner() {
    final chatProvider = Provider.of<ChatProvider>(context);
    final chatService = chatProvider.chatService;
    final isApiConfigured = chatService.isApiKeyConfigured();

    if (isApiConfigured) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode démo - Configurez Gemini API pour des réponses IA réelles',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    switch (index) {
      case 0: // Accueil
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1: // Chat (déjà sur ChatScreen)
        break;
      case 2: // Planner
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PlannerScreen()),
          (route) => false,
        );
        break;
      case 3: // Communauté
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreen()),
          (route) => false,
        );
        break;
      case 4: // Profil
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (route) => false,
        );
        break;
    }
  }

  void _handleBackButton() {
    // Retour à l'écran d'où on vient
    switch (widget.fromScreen) {
      case 'home':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 'planner':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PlannerScreen()),
          (route) => false,
        );
        break;
      case 'community':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreen()),
          (route) => false,
        );
        break;
      case 'profile':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (route) => false,
        );
        break;
      default:
        // Par défaut, retour à HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final chatService = chatProvider.chatService;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Calma - Assistant'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackButton,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationHistoryScreen(),
                ),
              );
            },
            tooltip: 'Historique des conversations',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Effacer la conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // API Status Banner
          _buildApiStatusBanner(),

          // Chat messages
          Expanded(child: _buildMessagesList(chatService)),

          // Typing indicator
          if (_isLoading) _buildTypingIndicator(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatService chatService) {
    final messages = chatService.messageHistory;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety,
                color: const Color(AppConstants.primaryColor),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Text(
                    'Calma',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Message bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(AppConstants.primaryColor)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                  ),
                  child: _buildMessageText(message.text, isUser: isUser),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 8,
                    right: isUser ? 8 : 0,
                  ),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 12),
            // User Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: const Color(AppConstants.primaryColor),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, {required bool isUser}) {
    try {
      return MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
            height: 1.4,
            fontFamily: 'Roboto',
          ),
          strong: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
          em: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontStyle: FontStyle.italic,
            fontFamily: 'Roboto',
          ),
          blockquote: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontStyle: FontStyle.italic,
            fontFamily: 'Roboto',
          ),
          listBullet: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
            fontFamily: 'Roboto',
          ),
        ),
        onTapLink: (text, href, title) {
          // Gérer les liens cliquables
        },
        builders: {'code': CodeElementBuilder()},
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur rendu Markdown: $e');
      }
      return Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.4,
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.health_and_safety,
              color: const Color(AppConstants.primaryColor),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calma',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTypingDot(0),
                      _buildTypingDot(1),
                      _buildTypingDot(2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColor),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  if (_messageController.text.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: () {
                        _messageController.clear();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Send button
          Container(
            decoration: BoxDecoration(
              color: _messageController.text.trim().isNotEmpty && !_isLoading
                  ? const Color(AppConstants.primaryColor)
                  : Colors.grey[400],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_messageController.text.trim().isNotEmpty && !_isLoading
                              ? const Color(AppConstants.primaryColor)
                              : Colors.grey[400]!)
                          .withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed:
                  _messageController.text.trim().isNotEmpty && !_isLoading
                  ? _sendMessage
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDay == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Hier ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var textContent = element.textContent;

    final bool isInlineCode = element.attributes['class'] == null;

    // For inline code (backticks)
    if (isInlineCode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          textContent,
          style: preferredStyle?.copyWith(
            fontFamily: 'RobotoMono',
            backgroundColor: Colors.grey[100],
            color: Colors.purple[800],
          ),
        ),
      );
    }

    // For code blocks (triple backticks / fenced code)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          textContent,
          style: preferredStyle?.copyWith(
            fontFamily: 'RobotoMono',
            fontSize: 14,
            color: Colors.purple[800],
          ),
        ),
      ),
    );
  }
}
