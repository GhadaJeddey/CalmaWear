// providers/community_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../models/community_story.dart';
import '../models/community_event.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityService _service = CommunityService();

  List<CommunityStory> _stories = [];
  List<CommunityEvent> _events = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<CommunityStory>>? _storiesSubscription;
  StreamSubscription<List<CommunityEvent>>? _eventsSubscription;

  List<CommunityStory> get stories => _stories;
  List<CommunityEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get currentUserId => _service.currentUserId;
  bool get isUserLoggedIn => _service.isUserLoggedIn;

  void _safeNotifyListeners() {
    Future.microtask(() {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _storiesSubscription?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }

  /// Load all stories
  Future<void> loadStories() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Get initial data
      final initialStories = await _service.getStories();
      _stories = initialStories;

      // Then listen for updates
      _storiesSubscription?.cancel();
      _storiesSubscription = _service.getStoriesStream().listen((stories) {
        _stories = stories;
        _safeNotifyListeners();
      });

      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Create a new story
  Future<bool> createStory({
    required String title,
    required String content,
    required String authorName,
    String? authorProfileImageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final storyId = await _service.createStory(
        title: title,
        content: content,
        authorName: authorName,
        authorProfileImageUrl: authorProfileImageUrl,
      );

      _isLoading = false;
      _safeNotifyListeners();

      return storyId != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Toggle like on a story
  Future<void> toggleStoryLike(String storyId) async {
    try {
      await _service.toggleStoryLike(storyId);

      // Update local state
      final index = _stories.indexWhere((s) => s.id == storyId);
      if (index != -1) {
        final story = _stories[index];
        final userId = _service.currentUserId;

        if (userId != null) {
          final hasLiked = story.likedBy.contains(userId);

          _stories[index] = story.copyWith(
            likes: hasLiked ? story.likes - 1 : story.likes + 1,
            likedBy: hasLiked
                ? story.likedBy.where((id) => id != userId).toList()
                : [...story.likedBy, userId],
          );

          _safeNotifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    }
  }

  /// Get stories by user ID
  Future<List<CommunityStory>> getUserStories(String userId) async {
    try {
      return await _service.getUserStories(userId);
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return [];
    }
  }

  /// Delete a story
  Future<bool> deleteStory(String storyId) async {
    try {
      final success = await _service.deleteStory(storyId);

      if (success) {
        _stories.removeWhere((s) => s.id == storyId);
        _safeNotifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  // ==================== EVENTS ====================

  /// Load all events
  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Get initial data
      final initialEvents = await _service.getEvents();
      _events = initialEvents;

      // Then listen for updates
      _eventsSubscription?.cancel();
      _eventsSubscription = _service.getEventsStream().listen((events) {
        _events = events;
        _safeNotifyListeners();
      });

      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Register for an event
  Future<bool> registerForEvent(String eventId) async {
    try {
      final success = await _service.registerForEvent(eventId);

      if (success) {
        // Update local state
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          final event = _events[index];
          final userId = _service.currentUserId;

          if (userId != null && !event.registeredUsers.contains(userId)) {
            _events[index] = event.copyWith(
              registeredCount: event.registeredCount + 1,
              registeredUsers: [...event.registeredUsers, userId],
            );

            _safeNotifyListeners();
          }
        }
      }

      return success;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Unregister from an event
  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      final success = await _service.unregisterFromEvent(eventId);

      if (success) {
        // Update local state
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          final event = _events[index];
          final userId = _service.currentUserId;

          if (userId != null) {
            _events[index] = event.copyWith(
              registeredCount: event.registeredCount - 1,
              registeredUsers: event.registeredUsers
                  .where((id) => id != userId)
                  .toList(),
            );

            _safeNotifyListeners();
          }
        }
      }

      return success;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Create a new event (admin only)
  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String type,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final eventId = await _service.createEvent(
        title: title,
        description: description,
        date: date,
        time: time,
        type: type,
        imageUrl: imageUrl,
      );

      _isLoading = false;
      _safeNotifyListeners();

      return eventId != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Get events registered by user
  Future<List<CommunityEvent>> getUserRegisteredEvents(String userId) async {
    try {
      // Filter events where user is registered
      await loadEvents(); // Ensure events are loaded
      return _events
          .where((event) => event.registeredUsers.contains(userId))
          .toList();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}
