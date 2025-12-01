// services/chat_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import '../config/keys.dart';
import 'chat_history_service.dart';
import '../models/conversation.dart';

class ChatService {
  static final String _apiKey = ApiKeys.geminiApiKey;
  late final GenerativeModel? _model;
  late final ChatSession? _chatSession;
  bool _isInitialized = false;
  String _status = 'Non initialisé';

  final List<ChatMessage> _messageHistory = [];

  List<ChatMessage> get messageHistory => List.unmodifiable(_messageHistory);
  String get status => _status;
  bool get isGeminiActive => _isInitialized;

  final FirestoreService _firestoreService = FirestoreService();
  String? _currentConversationId;
  Conversation? _currentConversation;

  ChatService() {
    _initializeModel();
  }

  bool isApiKeyConfigured() {
    return _apiKey.isNotEmpty &&
        _apiKey != 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
        _isInitialized;
  }

  void _initializeModel() {
    try {
      if (!ApiKeys.isConfigured) {
        _status = 'Mode démo - API non configurée';
        if (kDebugMode && ApiKeys.debugMode) {
          debugPrint(' $status');
          debugPrint('Pour activer Gemini:');
          debugPrint(' • Remplace la clé dans api_keys.dart');
          debugPrint(' • Ou utilise: --dart-define=GEMINI_API_KEY=ta_cle');
        }
        _isInitialized = false;
        return;
      }

      if (kDebugMode && ApiKeys.debugMode) {
        debugPrint('🔄 Initialisation Gemini...');
      }

      _model = GenerativeModel(
        model: ApiKeys.geminiModel,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 3000,
          temperature: 0.0,
          topP: 0.8,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.low),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.low),
        ],
      );

      // Initialisation de la session
      final initialContent = Content.text(_getSystemPrompt());
      _chatSession = _model!.startChat(history: [initialContent]);

      _isInitialized = true;
      _status = 'Connecté à Gemini';

      if (kDebugMode && ApiKeys.debugMode) {
        debugPrint('✅ $status');
      }
    } catch (e) {
      _status = 'Erreur initialisation: ${e.toString()}';
      _isInitialized = false;
      if (kDebugMode && ApiKeys.debugMode) {
        debugPrint(' $status');
      }
    }
  }

  String _getSystemPrompt() {
    return '''
**<SYSTEM_INSTRUCTION>**

**<ROLE_ET_IDENTITE_CRITIQUE>**
Ton nom est Calma. Tu es un assistant IA spécialisé dans le soutien aux parents d'enfants autistes (Troubles du Spectre Autistique - TSA). Ton objectif est d'être la première ligne de soutien non-médical pour ces parents, en lien avec une application de monitoring (rythme cardiaque, stress, sommeil, etc.).
**</ROLE_ET_IDENTITE_CRITIQUE>**

**<TON_ET_PERSONA>**
* **Ton Principal:** Tu es profondément **empathique, bienveillant, encourageant, et positif**.
* **Style:** Tes réponses sont **pratiques, concrètes, claires et accessibles** (évite le jargon académique).
* **Expertise:** Tu t'appuies sur des connaissances solides en : gestion des crises et du stress, routines et transitions, défis sensoriels et alimentaires, sommeil et repos, intégration sociale, et analyse des données de monitoring de l'application.
**</TON_ET_PERSONA>**

**<DIRECTIVES_DE_REPONSE>**
1.  **Validation:** Commence toujours par valider l'émotion du parent ("Je comprends votre épuisement," "Votre frustration est légitime").
2.  **Clarté:** Structure systématiquement ta réponse avec des titres et des **listes à puces claires** pour la rendre facile à lire.
3.  **Action:** Propose des conseils pratiques, réalisables et concrets. Utilise des **exemples d'actions simples et immédiates**.
4.  **Précision:** Pour tout problème complexe, **pose 1 à 2 questions ouvertes** pour clarifier la situation et le contexte avant de proposer un plan d'action définitif.
**</DIRECTIVES_DE_REPONSE>**

**<CONTRAINTES_ET_LIMITES>**
**STRICTEMENT INTERDIT** de :
* Fournir un diagnostic médical ou remplacer un professionnel de la santé.
* Faire des promesses de guérison ou des affirmations non fondées.
* Utiliser un ton critique ou moralisateur.
* Fournir des informations sans lien avec tes domaines d'expertise.

**RÉFÉRENCE NÉCESSAIRE :** Pour tout besoin critique, tu dois inviter le parent à **consulter un professionnel qualifié** (pédiatre, psychologue, ergothérapeute).
**</CONTRAINTES_ET_LIMITES>**

**</SYSTEM_INSTRUCTION>**
''';
  }

  Future<ChatMessage> sendMessage(String userMessage) async {
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      conversationId: _currentConversationId,
      messageId: _firestoreService.generateMessageId(),
    );
    _messageHistory.add(userChatMessage);

    await _createOrUpdateConversation();

    // Vérifier si Gemini est disponible
    if (!_isInitialized || _chatSession == null) {
      return _sendDemoResponse(userMessage);
    }

    try {
      if (kDebugMode && ApiKeys.debugMode) {
        debugPrint('- Envoi à Gemini: "${_truncateText(userMessage, 50)}"');
      }

      // Timeout pour éviter les blocages
      final response = await _chatSession!
          .sendMessage(Content.text(userMessage))
          .timeout(const Duration(seconds: 30));

      final aiResponse = response.text ?? _getFallbackResponse(userMessage);

      if (kDebugMode && ApiKeys.debugMode) {
        debugPrint('- Réponse reçue: ${_truncateText(aiResponse, 50)}');
      }

      final aiChatMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        conversationId: _currentConversationId,
        messageId: _firestoreService.generateMessageId(),
      );
      _messageHistory.add(aiChatMessage);

      await _updateConversationWithNewMessage(aiChatMessage);

      return aiChatMessage;
    } on TimeoutException {
      if (kDebugMode && ApiKeys.debugMode) {
        debugPrint('!! Timeout - Retour au mode démo');
      }
      return _sendDemoResponse(userMessage, isTimeout: true);
    } catch (e) {
      if (kDebugMode && ApiKeys.debugMode) {
        debugPrint('!! Erreur Gemini: $e');
      }
      return _sendDemoResponse(userMessage, error: e.toString());
    }
  }

  Future<void> _createOrUpdateConversation() async {
    if (_currentConversationId == null) {
      _currentConversationId = _firestoreService.generateConversationId();

      final firstMessageText = _messageHistory.isNotEmpty
          ? _messageHistory.first.text
          : 'Nouvelle conversation';

      _currentConversation = Conversation(
        id: _currentConversationId!,
        title: _generateConversationTitle(firstMessageText),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: List.from(_messageHistory),
        messageCount: _messageHistory.length,
      );

      if (_firestoreService.isUserLoggedIn) {
        await _firestoreService.saveConversation(_currentConversation!);
      }
    } else {
      _currentConversation = _currentConversation!.copyWith(
        updatedAt: DateTime.now(),
        messages: List.from(_messageHistory),
        messageCount: _messageHistory.length,
      );

      if (_firestoreService.isUserLoggedIn) {
        await _firestoreService.updateConversation(_currentConversation!);
      }
    }
  }

  Future<void> _updateConversationWithNewMessage(ChatMessage message) async {
    if (_currentConversation != null) {
      _currentConversation = _currentConversation!.copyWith(
        updatedAt: DateTime.now(),
        messages: List.from(_messageHistory),
        messageCount: _messageHistory.length,
      );

      if (_firestoreService.isUserLoggedIn) {
        await _firestoreService.updateConversation(_currentConversation!);
      }
    }
  }

  String _generateConversationTitle(String firstMessage) {
    if (firstMessage.length > 30) {
      return '${firstMessage.substring(0, 30)}...';
    }
    return firstMessage;
  }

  ChatMessage _sendDemoResponse(
    String userMessage, {
    bool isTimeout = false,
    String error = '',
  }) {
    final response = _generateDemoResponse(
      userMessage,
      isTimeout: isTimeout,
      error: error,
    );

    final demoMessage = ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
      conversationId: _currentConversationId,
      messageId: _firestoreService.generateMessageId(),
    );
    _messageHistory.add(demoMessage);

    // Mettre à jour la conversation avec la réponse démo
    _updateConversationWithNewMessage(demoMessage);

    return demoMessage;
  }

  String _generateDemoResponse(
    String userMessage, {
    bool isTimeout = false,
    String error = '',
  }) {
    final lowerMessage = userMessage.toLowerCase();

    // En-tête contextuel
    String header = '💡 **Mode Démo Actif**\n\n';
    if (isTimeout) header = '⏰ **Délai dépassé**\n\n';
    if (error.isNotEmpty) header = '⚠️ **Erreur technique**\n\n';

    // Réponses contextuelles de démo
    if (lowerMessage.contains('bonjour') || lowerMessage.contains('salut')) {
      return '''
$header👋 Bonjour! Je suis Calma, votre assistant pour accompagner votre enfant autiste.

**En mode démo actuellement** - Voici ce que je peux faire:

🤝 **Soutien pratique:**
• Gestion des crises et du stress
• Routines et transitions
• Défis sensoriels et alimentaires
• Sommeil et repos

📊 **Avec Gemini activé:**
• Analyse des données de monitoring
• Conseils personnalisés
• Stratégies adaptées

🔧 **Pour activer l'IA complète:**
1. Obtenez une clé sur https://makersuite.google.com/app/apikey
2. Ajoutez-la dans lib/config/api_keys.dart

Comment puis-je vous aider aujourd'hui?''';
    } else if (lowerMessage.contains('stress') ||
        lowerMessage.contains('crise')) {
      return '''
$header😔 Je comprends votre inquiétude face au stress.

**Stratégies immédiates:**
• 🏠 Espace calme et familier
• 🎵 Musique douce ou bruits blancs  
• 🤗 Objets sensoriels apaisants
• 📝 Phrases courtes et rassurantes

**Prévention:**
• 📅 Routines prévisibles
• ⏰ Préparer les transitions
• 👀 Observer les déclencheurs

Que se passe-t-il exactement?''';
    } else if (lowerMessage.contains('sommeil') ||
        lowerMessage.contains('dormir')) {
      return '''
$header🌙 Les défis de sommeil sont fréquents.

**Stratégies efficaces:**
• 🕰️ Routine fixe du coucher
• 🌙 Environnement sensoriel adapté
• 📱 Pas d'écrans 1h avant
• 🛏️ Literie confortable

**Aides sensorielles:**
• Couverture lestée
• Veilleuse adaptée  
• Bruits blancs

Comment se passent les nuits actuellement?''';
    } else if (lowerMessage.contains('manger') ||
        lowerMessage.contains('nourriture')) {
      return '''
$header🍎 L'alimentation peut être complexe.

**Approches utiles:**
• 🍽️ Présentation structurée
• 👁️ Exposition progressive
• 😊 Pas de pression
• 📊 Journal alimentaire

**Gestion sensorielle:**
• Textures progressives
• Températures adaptées
• Couleurs séparées

Quels sont les défis spécifiques?''';
    } else {
      return '''
$header🤗 Je comprends que vous cherchez du soutien.

**Domaines d'expertise:**
• 🧘 Gestion du stress et crises
• 📚 Routines et transitions  
• 🛌 Sommeil et repos
• 🍎 Défis alimentaires
• 👥 Intégration sociale
• 📊 Analyse des données

**En mode démo:** Conseils généraux
**Avec Gemini:** Recommandations personnalisées

🔧 **Activation Gemini:**
Ajoutez votre clé API dans lib/config/api_keys.dart

Sur quel aspect aimeriez-vous de l'aide?''';
    }
  }

  String _getFallbackResponse(String userMessage) {
    return "Je rencontre des difficultés techniques. En attendant, je vous suggère de créer un environnement calme et prévisible, et de consulter des professionnels pour un accompagnement personnalisé.";
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void clearHistory() {
    _messageHistory.clear();
    _currentConversationId = null;
    _currentConversation = null;
    _initializeModel(); // Réinitialise la session
  }

  void loadDemoHistory() {
    _messageHistory.clear();
    _currentConversationId = null;
    _currentConversation = null;

    _messageHistory.addAll([
      ChatMessage(
        text:
            '''👋 Bonjour! Je suis Calma, votre assistant spécialisé.

💡 **Mon rôle:** Vous accompagner dans le parcours avec votre enfant autiste

📊 **Je peux vous aider avec:**
• Gestion du stress et des crises
• Routines et transitions  
• Défis sensoriels et alimentaires
• Sommeil et analyse des données

🔧 **Statut: ${_isInitialized ? 'Connecté à Gemini 🟢' : 'Mode Démo Actif 🟡'}**

${_isInitialized ? '' : '💡 Pour activer l\'IA: Ajoutez votre clé API Gemini dans la configuration'}

Comment puis-je vous soutenir aujourd'hui?''',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ]);
  }

  // Réinitialiser le service
  void restart() {
    _messageHistory.clear();
    _currentConversationId = null;
    _currentConversation = null;
    _isInitialized = false;
    _initializeModel();
  }

  // === NOUVELLES MÉTHODES POUR L'HISTORIQUE ===

  // Charger une conversation spécifique
  Future<void> loadConversation(String conversationId) async {
    final conversation = await _firestoreService.getConversation(
      conversationId,
    );
    if (conversation != null) {
      _currentConversationId = conversationId;
      _currentConversation = conversation;
      _messageHistory.clear();
      _messageHistory.addAll(conversation.messages);
    }
  }

  // Récupérer le stream des conversations
  Stream<List<Conversation>> getConversationsStream() {
    return _firestoreService.getConversations();
  }

  // Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    await _firestoreService.deleteConversation(conversationId);
    if (_currentConversationId == conversationId) {
      clearHistory();
      loadDemoHistory();
    }
  }

  // Créer une nouvelle conversation
  void startNewConversation() {
    clearHistory();
    loadDemoHistory();
  }

  // Vérifier si une conversation est chargée
  bool get hasActiveConversation => _currentConversationId != null;

  // Récupérer la conversation actuelle
  Conversation? get currentConversation => _currentConversation;
}
