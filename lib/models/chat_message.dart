import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // À remplacer plus tard
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent';

  final List<ChatMessage> _messageHistory = [];

  List<ChatMessage> get messageHistory => List.unmodifiable(_messageHistory);

  // Envoyer un message à Gemini
  Future<ChatMessage> sendMessage(String userMessage) async {
    // Ajouter le message utilisateur à l'historique
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messageHistory.add(userChatMessage);

    try {
      // Pour le prototype, on simule Gemini
      // Plus tard: intégration réelle avec l'API
      final aiResponse = await _simulateGeminiResponse(userMessage);

      final aiChatMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messageHistory.add(aiChatMessage);

      return aiChatMessage;
    } catch (e) {
      final errorMessage = ChatMessage(
        text:
            "Désolé, je rencontre des difficultés techniques. Pouvez-vous réessayer?",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messageHistory.add(errorMessage);
      return errorMessage;
    }
  }

  // Simuler les réponses de Gemini pour le prototype
  Future<String> _simulateGeminiResponse(String userMessage) async {
    await Future.delayed(const Duration(seconds: 1)); // Simuler délai réseau

    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('bonjour') || lowerMessage.contains('salut')) {
      return "Bonjour! Je suis Calma, votre assistant pour accompagner votre enfant autiste. Comment puis-je vous aider aujourd'hui?";
    } else if (lowerMessage.contains('stress') ||
        lowerMessage.contains('crise')) {
      return "Je comprends votre inquiétude. En cas de signes de stress ou de crise, je vous recommande:\n\n"
          "1. 🏠 Créer un environnement calme et familier\n"
          "2. 🔊 Réduire les stimuli sensoriels (lumière, bruit)\n"
          "3. 🤗 Utiliser des techniques de pression profonde si votre enfant les apprécie\n"
          "4. 📱 Consulter les données de monitoring pour identifier les déclencheurs\n\n"
          "Voulez-vous que je vous guide avec des exercices de relaxation spécifiques?";
    } else if (lowerMessage.contains('sommeil') ||
        lowerMessage.contains('dormir')) {
      return "Pour améliorer le sommeil, essayez:\n\n"
          "• 🕰️ Routine du coucher régulière\n"
          "• 🌙 Environnement sombre et calme\n"
          "• 📱 Éviter les écrans 1h avant le coucher\n"
          "• 🛌 Literie confortable et weighted blanket si utile\n\n"
          "Le monitoring montre des patterns particuliers pour le sommeil?";
    } else if (lowerMessage.contains('nourriture') ||
        lowerMessage.contains('manger')) {
      return "Les défis alimentaires sont courants. Suggestions:\n\n"
          "• 🍽️ Présenter les aliments de manière structurée\n"
          "• 👀 Exposition progressive aux nouveaux aliments\n"
          "• 😊 Rester positif et éviter la pression\n"
          "• 📊 Noter les préférences et aversions\n\n"
          "Avez-vous remarqué des patterns spécifiques?";
    } else if (lowerMessage.contains('merci')) {
      return "Je suis là pour vous aider! N'hésitez pas à me poser d'autres questions sur le bien-être de votre enfant. 😊";
    } else {
      return "Je comprends que vous cherchez des conseils pour accompagner votre enfant. "
          "En tant qu'assistant spécialisé, je peux vous aider avec:\n\n"
          "• 🤔 Gestion du stress et des crises\n"
          "• 🛌 Routines de sommeil\n"
          "• 🍎 Défis alimentaires\n"
          "• 🎯 Activités adaptées\n"
          "• 📊 Analyse des données de monitoring\n\n"
          "Sur quel aspect aimeriez-vous que je vous aide plus spécifiquement?";
    }
  }

  // Vider l'historique des conversations
  void clearHistory() {
    _messageHistory.clear();
  }

  // Charger un historique de démo
  void loadDemoHistory() {
    _messageHistory.clear();
    _messageHistory.addAll([
      ChatMessage(
        text:
            "Bonjour! Je suis Calma, votre assistant pour accompagner votre enfant autiste. Comment puis-je vous aider aujourd'hui?",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ]);
  }
}
