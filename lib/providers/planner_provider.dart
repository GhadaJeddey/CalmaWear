// providers/planner_provider.dart
import 'package:flutter/material.dart';
import '../services/planner_service.dart';
import '../models/todo_item.dart';

class PlannerProvider extends ChangeNotifier {
  late PlannerService _service;
  String? _currentUserId;

  PlannerProvider() {
    _service = PlannerService();
  }

  bool get isAiEnabled => _service.isAiEnabled;
  Stream<bool> get aiEnabledStream => _service.aiEnabledStream;

  Future<void> setAiEnabled(bool enabled) async {
    await _service.setAiEnabled(enabled);
    notifyListeners();
  }

  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _service.initialize(userId);
    notifyListeners();
  }

  List<DateTime> get weekDays => _service.weekDays;
  DateTime get currentDate => _service.currentDate;
  List<TodoItem> get allTodos => _service.allTodos;
  List<TodoItem> get userDefaultTodos => _service.getUserDefaultTodos();
  double get completionPercentage => _service.completionPercentage;
  bool get isInitialized => _service.isInitialized;

  Stream<List<TodoItem>> get todosStream => _service.getTodosStream();
  Stream<List<TodoItem>> get defaultTodosStream =>
      _service.getDefaultTodosStream();

  Future<void> updateCurrentDate(DateTime date) async {
    await _service.updateCurrentDate(date);
    notifyListeners();
  }

  Future<List<TodoItem>> generatePersonalizedTodos(String userContext) async {
    final todos = await _service.generatePersonalizedTodos(userContext);
    notifyListeners();
    return todos;
  }

  Future<void> addSelectedTodos(List<TodoItem> selectedTodos) async {
    await _service.addSelectedTodos(selectedTodos);
    notifyListeners();
  }

  Future<void> addTodo(
    String title,
    String category, {
    bool isAiSuggested = false,
  }) async {
    final todo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      isCompleted: false,
      isUserDefault: false,
      isAiSuggested: isAiSuggested,
      createdAt: DateTime.now(),
    );
    await _service.addTodo(todo);
    notifyListeners();
  }

  Future<void> addUserDefaultTodo(String title) async {
    await _service.addUserDefaultTodo(title);
    notifyListeners();
  }

  Future<void> removeUserDefaultTodo(String id) async {
    await _service.removeUserDefaultTodo(id);
    notifyListeners();
  }

  Future<void> removeTodo(String id) async {
    await _service.removeTodo(id);
    notifyListeners();
  }

  Future<void> toggleTodo(String id) async {
    await _service.toggleTodo(id);
    notifyListeners();
  }

  Future<void> resetDay() async {
    await _service.resetDay();
    notifyListeners();
  }

  Future<void> clearUserData() async {
    await _service.clearUserData();
    notifyListeners();
  }
}
