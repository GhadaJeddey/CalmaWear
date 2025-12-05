// lib/services/community_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_story.dart';
import '../models/community_event.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isUserLoggedIn => _auth.currentUser != null;

  // ==================== STORIES ====================

  /// Get all stories from Firestore
  Stream<List<CommunityStory>> getStoriesStream() {
    return FirebaseFirestore.instance
        .collection('community_stories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityStory.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<CommunityStory>> getStories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('community_stories')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CommunityStory.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<CommunityEvent>> getEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('community_events')
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => CommunityEvent.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get a single story by ID
  Future<CommunityStory?> getStory(String storyId) async {
    try {
      final doc = await _firestore
          .collection('community_stories')
          .doc(storyId)
          .get();

      if (doc.exists) {
        return CommunityStory.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting story: $e');
      return null;
    }
  }

  /// Create a new story
  Future<String?> createStory({
    required String title,
    required String content,
    required String authorName,
    String? authorProfileImageUrl,
  }) async {
    if (!isUserLoggedIn) {
      print('User not logged in');
      return null;
    }

    try {
      final readTime = CommunityStory.calculateReadTime(content);

      final storyData = {
        'title': title,
        'content': content,
        'authorId': currentUserId!,
        'authorName': authorName,
        'authorProfileImageUrl': authorProfileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'readTime': readTime,
        'likedBy': [],
      };

      final docRef = await _firestore
          .collection('community_stories')
          .add(storyData);

      return docRef.id;
    } catch (e) {
      print('Error creating story: $e');
      return null;
    }
  }

  /// Toggle like on a story
  Future<void> toggleStoryLike(String storyId) async {
    if (!isUserLoggedIn) return;

    try {
      final storyRef = _firestore.collection('community_stories').doc(storyId);

      final storyDoc = await storyRef.get();
      if (!storyDoc.exists) return;

      final story = CommunityStory.fromFirestore(storyDoc.data()!, storyDoc.id);
      final hasLiked = story.likedBy.contains(currentUserId);

      if (hasLiked) {
        // Unlike
        await storyRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Like
        await storyRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  /// Delete a story (only by author)
  Future<bool> deleteStory(String storyId) async {
    if (!isUserLoggedIn) return false;

    try {
      final storyDoc = await _firestore
          .collection('community_stories')
          .doc(storyId)
          .get();

      if (!storyDoc.exists) return false;

      final story = CommunityStory.fromFirestore(storyDoc.data()!, storyDoc.id);

      // Only author can delete
      if (story.authorId != currentUserId) {
        print('Unauthorized: Only author can delete story');
        return false;
      }

      await _firestore.collection('community_stories').doc(storyId).delete();
      return true;
    } catch (e) {
      print('Error deleting story: $e');
      return false;
    }
  }

  // ==================== EVENTS ====================

  /// Get all events from Firestore
  Stream<List<CommunityEvent>> getEventsStream() {
    return FirebaseFirestore.instance
        .collection('community_events')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityEvent.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get a single event by ID
  Future<CommunityEvent?> getEvent(String eventId) async {
    try {
      final doc = await _firestore
          .collection('community_events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return CommunityEvent.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  /// Register for an event
  Future<bool> registerForEvent(String eventId) async {
    if (!isUserLoggedIn) return false;

    try {
      final eventRef = _firestore.collection('community_events').doc(eventId);

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) return false;

      final event = CommunityEvent.fromFirestore(eventDoc.data()!, eventDoc.id);
      final isRegistered = event.registeredUsers.contains(currentUserId);

      if (isRegistered) {
        // Already registered, do nothing or unregister
        print('User already registered');
        return true;
      }

      // Register user
      await eventRef.update({
        'registeredCount': FieldValue.increment(1),
        'registeredUsers': FieldValue.arrayUnion([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error registering for event: $e');
      return false;
    }
  }

  /// Unregister from an event
  Future<bool> unregisterFromEvent(String eventId) async {
    if (!isUserLoggedIn) return false;

    try {
      final eventRef = _firestore.collection('community_events').doc(eventId);

      await eventRef.update({
        'registeredCount': FieldValue.increment(-1),
        'registeredUsers': FieldValue.arrayRemove([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error unregistering from event: $e');
      return false;
    }
  }

  /// Create a new event (admin only)
  Future<String?> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String type,
    String? imageUrl,
  }) async {
    if (!isUserLoggedIn) return null;

    try {
      final eventData = {
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'time': time,
        'type': type,
        'imageUrl': imageUrl,
        'registeredCount': 0,
        'registeredUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('community_events')
          .add(eventData);

      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }
}
