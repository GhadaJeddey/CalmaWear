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
  // Add stream subscriptions
  StreamSubscription<List<CommunityStory>>? _storiesSubscription;
  StreamSubscription<List<CommunityEvent>>? _eventsSubscription;

  List<CommunityStory> get stories => _stories;
  List<CommunityEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Expose current user information from the internal service
  String? get currentUserId => _service.currentUserId;
  bool get isUserLoggedIn => _service.isUserLoggedIn;
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
    notifyListeners();

    try {
      // Get initial data
      final initialStories = await _service.getStories();
      _stories = initialStories;

      // Then listen for updates
      _storiesSubscription?.cancel();
      _storiesSubscription = _service.getStoriesStream().listen((stories) {
        _stories = stories;
        // Defer notifications so they don't run synchronously during a build.
        Future.microtask(() => notifyListeners());
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new story
  Future<bool> createStory({
    required String title,
    required String content,
    required String authorName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storyId = await _service.createStory(
        title: title,
        content: content,
        authorName: authorName,
      );

      _isLoading = false;
      notifyListeners();

      return storyId != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
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

          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a story
  Future<bool> deleteStory(String storyId) async {
    try {
      final success = await _service.deleteStory(storyId);

      if (success) {
        _stories.removeWhere((s) => s.id == storyId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== EVENTS ====================

  /// Load all events
  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get initial data
      final initialEvents = await _service.getEvents();
      _events = initialEvents;

      // Then listen for updates
      _eventsSubscription?.cancel();
      _eventsSubscription = _service.getEventsStream().listen((events) {
        _events = events;
        // Defer notifications so they don't run synchronously during a build.
        Future.microtask(() => notifyListeners());
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
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

            notifyListeners();
          }
        }
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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

            notifyListeners();
          }
        }
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final eventId = await _service.createEvent(
        title: title,
        description: description,
        date: date,
        time: time,
        type: type,
      );

      _isLoading = false;
      notifyListeners();

      return eventId != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
