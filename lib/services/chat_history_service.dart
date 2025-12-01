// services/chat_history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Sauvegarder une conversation
  Future<void> saveConversation(Conversation conversation) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(conversation.id)
          .set(conversation.toJson());
    } catch (e) {
      print('Erreur sauvegarde conversation: $e');
      throw e;
    }
  }

  // Récupérer toutes les conversations
  Stream<List<Conversation>> getConversations() {
    if (!isUserLoggedIn) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('conversations')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Conversation.fromJson({...doc.data(), 'id': doc.id});
          }).toList(),
        );
  }

  // Récupérer une conversation spécifique
  Future<Conversation?> getConversation(String conversationId) async {
    if (!isUserLoggedIn) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(conversationId)
          .get();

      return doc.exists
          ? Conversation.fromJson({...doc.data()!, 'id': doc.id})
          : null;
    } catch (e) {
      print('Erreur récupération conversation: $e');
      return null;
    }
  }

  // Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(conversationId)
          .delete();
    } catch (e) {
      print('Erreur suppression conversation: $e');
      throw e;
    }
  }

  // Mettre à jour une conversation
  Future<void> updateConversation(Conversation conversation) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(conversation.id)
          .update({
            'title': conversation.title,
            'updatedAt': conversation.updatedAt.toIso8601String(),
            'messages': conversation.messages
                .map((msg) => msg.toJson())
                .toList(),
            'messageCount': conversation.messageCount,
          });
    } catch (e) {
      print('Erreur mise à jour conversation: $e');
      throw e;
    }
  }

  // Générer un ID unique
  String generateConversationId() {
    return _firestore.collection('conversations').doc().id;
  }

  String generateMessageId() {
    return _firestore.collection('messages').doc().id;
  }
}
