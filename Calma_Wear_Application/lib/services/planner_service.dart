// services/planner/planner_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_item.dart';
import '../models/user.dart' as app_models;
import '../../config/keys.dart';
import 'dart:js_interop';
import 'package:js/js.dart';

class PlannerService {
  static final String _apiKey = ApiKeys.geminiApiKey;
  late final GenerativeModel? _model;
  bool _isGeminiInitialized = false;
  String _status = 'Non initialisé';

  final List<TodoItem> _todos = [];
  List<TodoItem> _userDefaultTodos = [];
  List<DateTime> _weekDays = [];
  DateTime _currentDate = DateTime.now();
  String? _currentUserId;
  app_models.User? _userData; // Store user/child data for AI context
  bool _isInitialized = false;
  bool _aiEnabled = true;

  // Firestore references
  late FirebaseFirestore _firestore;
  late CollectionReference _userTodosCollection;
  late CollectionReference _userDefaultsCollection;
  late CollectionReference _userSettingsCollection;

  static const bool _debugMode = ApiKeys.debugMode;

  PlannerService() {
    _initializeWeek();
    _initializeGemini();
  }

  void _initializeGemini() {
    try {
      if (!ApiKeys.isConfigured) {
        _status = 'Mode démo - API non configurée';
        _isGeminiInitialized = false;
        return;
      }

      if (_debugMode) debugPrint('🔄 Initialisation Gemini pour planner...');

      _model = GenerativeModel(
        model: ApiKeys.geminiModel,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 1000,
          temperature: 0.7,
          topP: 0.8,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.low),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.low),
        ],
      );

      _isGeminiInitialized = true;
      _status = 'Gemini prêt pour planner';

      if (_debugMode) debugPrint('✅ $status');
    } catch (e) {
      _status = 'Erreur initialisation Gemini: ${e.toString()}';
      _isGeminiInitialized = false;
      if (_debugMode) debugPrint('❌ $status');
    }
  }

  bool isApiKeyConfigured() {
    return _isGeminiInitialized && ApiKeys.isConfigured;
  }

  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _initFirestore();
    await _loadUserData();
    await _loadUserSettings();
    await _loadUserDefaultTodos();
    await _loadTodos();
    await _cleanupOldTodos();
    _isInitialized = true;
  }

  Future<void> _initFirestore() async {
    try {
      _firestore = FirebaseFirestore.instance;
      _userTodosCollection = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('planner_todos');
      _userDefaultsCollection = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('planner_defaults');
      _userSettingsCollection = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('planner_settings');
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur Firestore: $e');
      rethrow;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (doc.exists) {
        _userData = app_models.User.fromMap(doc.data()!);
        if (_debugMode) debugPrint('✅ User data loaded for AI context');
      }
    } catch (e) {
      if (_debugMode) debugPrint('❌ Error loading user data: $e');
    }
  }

  Future<void> _loadUserSettings() async {
    try {
      final doc = await _userSettingsCollection.doc('preferences').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _aiEnabled = data['aiEnabled'] ?? true;
      } else {
        await _userSettingsCollection.doc('preferences').set({
          'aiEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur chargement préférences: $e');
    }
  }

  Future<void> _saveUserSettings() async {
    try {
      await _userSettingsCollection.doc('preferences').set({
        'aiEnabled': _aiEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur sauvegarde préférences: $e');
    }
  }

  void _initializeWeek() {
    _weekDays = [];
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: now.weekday + 1));
    for (int i = 0; i < 7; i++) {
      _weekDays.add(startDate.add(Duration(days: i)));
    }
  }

  Future<void> _loadUserDefaultTodos() async {
    try {
      final querySnapshot = await _userDefaultsCollection.get();
      if (querySnapshot.docs.isNotEmpty) {
        _userDefaultTodos = querySnapshot.docs
            .map(
              (doc) =>
                  TodoItem.fromFirestore(doc.data() as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur chargement tâches par défaut: $e');
    }
  }

  Future<void> _saveUserDefaultTodos() async {
    try {
      final batch = _firestore.batch();
      final oldDocs = await _userDefaultsCollection.get();
      for (var doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }
      for (var todo in _userDefaultTodos) {
        final docRef = _userDefaultsCollection.doc(todo.id);
        batch.set(docRef, todo.toFirestore());
      }
      await batch.commit();
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur sauvegarde tâches par défaut: $e');
    }
  }

  Future<void> _loadTodos() async {
    try {
      final dateKey = _currentDate.toIso8601String().split('T')[0];
      final docRef = _userTodosCollection.doc(dateKey);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final todosData = data['todos'] as List<dynamic>;
        _todos.clear();
        _todos.addAll(
          todosData
              .map(
                (todoData) =>
                    TodoItem.fromFirestore(todoData as Map<String, dynamic>),
              )
              .toList(),
        );
      } else {
        await _generateNewDayTodos();
      }
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur chargement tâches: $e');
    }
  }

  Future<void> _saveTodos() async {
    try {
      final dateKey = _currentDate.toIso8601String().split('T')[0];
      final todosData = _todos.map((todo) => todo.toFirestore()).toList();
      await _userTodosCollection.doc(dateKey).set({
        'date': dateKey,
        'todos': todosData,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
      });
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur sauvegarde tâches: $e');
    }
  }

  Future<void> _cleanupOldTodos() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final cutoffKey = cutoffDate.toIso8601String().split('T')[0];
      final oldTodos = await _userTodosCollection
          .where('date', isLessThan: cutoffKey)
          .get();
      final batch = _firestore.batch();
      for (var doc in oldTodos.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur nettoyage: $e');
    }
  }

  Future<void> _generateNewDayTodos() async {
    _todos.clear();
    for (var defaultTodo in _userDefaultTodos) {
      _todos.add(
        TodoItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${defaultTodo.id}',
          title: defaultTodo.title,
          category: defaultTodo.category,
          isCompleted: false,
          isUserDefault: true,
          isAiSuggested: false,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (_aiEnabled && _todos.where((todo) => todo.isAiSuggested).isEmpty) {
      final aiTodos = await _generateAiSuggestedTodos();
      _todos.addAll(aiTodos);
    }
    await _saveTodos();
  }

  Future<void> addSelectedTodos(List<TodoItem> selectedTodos) async {
    for (var todo in selectedTodos) {
      // Créer une copie avec un nouvel ID pour éviter les conflits
      final newTodo = TodoItem(
        id: 'selected_${DateTime.now().millisecondsSinceEpoch}_${todo.id}',
        title: todo.title,
        category: todo.category,
        isCompleted: false, // Pas complétée par défaut
        isUserDefault: false, // Pas une tâche par défaut
        isAiSuggested: true, // Marqué comme suggéré par AI
        createdAt: DateTime.now(),
      );
      _todos.add(newTodo);
    }
    await _saveTodos();
  }

  Future<List<TodoItem>> _generateAiSuggestedTodos() async {
    if (!_isGeminiInitialized || _model == null) {
      if (_debugMode)
        debugPrint('🟡 Mode démo - Génération tâches AI fictives');
      return _generateFallbackAiTasks();
    }

    try {
      if (_debugMode) debugPrint('🔄 Génération tâches AI via Gemini SDK...');

      final prompt = _getPlannerSystemPrompt();
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      final text = response.text ?? _getFallbackResponse();

      final lines = text
          .split('\n')
          .where((line) => line.trim().startsWith('- '))
          .toList();
      List<TodoItem> aiTodos = [];

      for (String line in lines.take(3)) {
        final task = line.replaceFirst('- ', '').trim();
        if (task.isNotEmpty) {
          aiTodos.add(
            TodoItem(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${aiTodos.length}',
              title: task,
              category: 'AI Suggested',
              isCompleted: false,
              isUserDefault: false,
              isAiSuggested: true,
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      if (_debugMode) debugPrint('✅ ${aiTodos.length} tâches AI générées');
      return aiTodos;
    } on TimeoutException {
      if (_debugMode) debugPrint('⏰ Timeout - Retour aux tâches de secours');
      return _generateFallbackAiTasks();
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur génération AI: $e');
      return _generateFallbackAiTasks();
    }
  }

  String _getPlannerSystemPrompt() {
    // Build child context
    String childContext = '';
    if (_userData != null) {
      final childName = _userData!.childName ?? 'your child';
      final childAge = _userData!.childAge ?? 'unknown age';
      final childGender = _userData!.childGender ?? 'child';

      childContext =
          '''\n
CONTEXT ABOUT THE CHILD:
- Child's name: $childName
- Age: $childAge
- Gender: $childGender''';

      // Add trigger information if available
      if (_userData!.childTriggers.isNotEmpty) {
        final triggers = _userData!.childTriggers
            .where((t) => t.intensity > 50)
            .map((t) => '${t.name} (${t.intensity}%)')
            .join(', ');
        if (triggers.isNotEmpty) {
          childContext += '\n- Main triggers: $triggers';
        }
      }

      childContext +=
          '\n\nTake this child information into account when suggesting tasks for the parent.\n';
    }

    return '''
Tu es Calma, assistant IA spécialisé pour parents d'enfants autistes.
Génère 3 tâches quotidiennes de self-care concrètes et réalisables.$childContext
Directives:
- Chaque tâche commence par "- "
- Tâches courtes, spécifiques, adaptées à des parents occupés
- Focus sur bien-être mental et physique
- Personnalise selon le contexte de l'enfant si fourni
- Suggère des activités qui peuvent aider le parent à mieux gérer les défis spécifiques
- Pas de tâches trop longues ou complexes

Exemples:
- Prendre 10 minutes de respiration profonde
- Préparer une boisson chaude relaxante
- Noter 1 chose positive de la journée
- Pratiquer 5 minutes de méditation guidée
- Écrire une gratitude sur ${_userData?.childName ?? 'votre enfant'}

Génère 3 tâches maintenant:
''';
  }

  String _getFallbackResponse() {
    return "- Faire une pause de 5 minutes pour s'étirer\n- Boire un verre d'eau\n- Respirer profondément 3 fois";
  }

  List<TodoItem> _generateFallbackAiTasks() {
    debugPrint("🟡 Génération tâches AI de generateFallback");
    return [
      TodoItem(
        id: 'ai_fallback_1',
        title: 'Faire une pause de 5 minutes pour s\'étirer',
        category: 'AI Suggested',
        isCompleted: false,
        isUserDefault: false,
        isAiSuggested: true,
        createdAt: DateTime.now(),
      ),
      TodoItem(
        id: 'ai_fallback_2',
        title: 'Boire un grand verre d\'eau',
        category: 'AI Suggested',
        isCompleted: false,
        isUserDefault: false,
        isAiSuggested: true,
        createdAt: DateTime.now(),
      ),
      TodoItem(
        id: 'ai_fallback_3',
        title: 'Respirer profondément 3 fois',
        category: 'AI Suggested',
        isCompleted: false,
        isUserDefault: false,
        isAiSuggested: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<List<TodoItem>> generatePersonalizedTodos(String userContext) async {
    if (!_isGeminiInitialized || _model == null) {
      if (_debugMode)
        debugPrint('🟡 Mode démo - Génération tâches personnalisées fictives');
      return _generateFallbackPersonalizedTasks(userContext);
    }

    try {
      if (_debugMode) debugPrint('🔄 Génération tâches personnalisées...');
      if (_debugMode) debugPrint('📝 Contexte utilisateur: "$userContext"');

      // Build child context
      String childContext = '';
      if (_userData != null) {
        final childName = _userData!.childName ?? 'your child';
        final childAge = _userData!.childAge ?? 'unknown age';
        final childGender = _userData!.childGender ?? 'child';

        childContext =
            '''

CHILD INFORMATION:
- Child's name: $childName
- Age: $childAge
- Gender: $childGender''';

        // Add trigger information if available
        if (_userData!.childTriggers.isNotEmpty) {
          final triggers = _userData!.childTriggers
              .where((t) => t.intensity > 50)
              .map((t) => '${t.name} (${t.intensity}%)')
              .join(', ');
          if (triggers.isNotEmpty) {
            childContext += '\n- Main triggers: $triggers';
          }
        }

        childContext += '\n';
      }

      final prompt =
          '''
Tu es Calma, assistant IA spécialisé pour parents d'enfants autistes.
Génère EXACTEMENT 3 à 5 tâches quotidiennes COURTES ET CONCISES adaptées aux parents d'enfants autistes ou aux enfants en soi et au contexte suivant.
$childContext
Contexte de l'utilisateur: "$userContext"

RÈGLES IMPORTANTES:
- Génère entre 3 et 5 tâches
- Chaque tâche doit être TRÈS COURTE (maximum 5-8 mots)
- Une tâche par ligne
- Commence chaque ligne par un tiret suivi d'un espace: "- "
- Tâches réalisables et personnalisées selon l'enfant
- Prends en compte l'âge, le nom et les déclencheurs de l'enfant
- Adapte le langage et les suggestions au contexte familial
- Sois BREF et DIRECT, évite les phrases longues

Génère maintenant 3 à 5 tâches COURTES adaptées au contexte:
''';

      if (_debugMode) debugPrint('📤 Envoi de la requête à Gemini...');

      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30)); // Augmenté à 30 secondes

      final text = response.text?.trim();

      if (_debugMode) {
        debugPrint('📥 Réponse brute reçue de Gemini:');
        debugPrint('=' * 50);
        debugPrint(text ?? 'NULL RESPONSE');
        debugPrint('=' * 50);
      }

      if (text == null || text.isEmpty) {
        if (_debugMode) debugPrint('⚠️ Réponse vide de Gemini');
        return _generateFallbackPersonalizedTasks(userContext);
      }

      // Parse avec une approche plus tolérante
      List<TodoItem> generatedTodos = [];
      final lines = text.split('\n');

      if (_debugMode) debugPrint('🔍 Parsing ${lines.length} lignes...');

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();

        if (line.isEmpty) continue;

        if (_debugMode) debugPrint('  Ligne $i: "$line"');

        String? taskText;

        // Essayer différents formats de bullets
        if (line.startsWith('- ')) {
          taskText = line.substring(2).trim();
          if (_debugMode) debugPrint('    ✓ Matched "- " format');
        } else if (line.startsWith('• ')) {
          taskText = line.substring(2).trim();
          if (_debugMode) debugPrint('    ✓ Matched "• " format');
        } else if (line.startsWith('* ')) {
          taskText = line.substring(2).trim();
          if (_debugMode) debugPrint('    ✓ Matched "* " format');
        } else if (RegExp(r'^\d+[\.\)]\s+').hasMatch(line)) {
          // Format numéroté: "1. " ou "1) "
          final match = RegExp(r'^\d+[\.\)]\s+').firstMatch(line);
          if (match != null) {
            taskText = line.substring(match.end).trim();
            if (_debugMode) debugPrint('    ✓ Matched numbered format');
          }
        } else if (line.length > 10 && !line.contains(':')) {
          // Si c'est une ligne assez longue sans deux-points, considérer comme tâche
          taskText = line;
          if (_debugMode) debugPrint('    ✓ Matched plain text format');
        }

        // Nettoyer et valider la tâche
        if (taskText != null && taskText.isNotEmpty) {
          // Retirer les caractères spéciaux en début/fin
          taskText = taskText
              .replaceAll(RegExp(r'^[^\w\s]+|[^\w\s]+$'), '')
              .trim();

          // Vérifier que c'est une tâche valide (pas trop courte, pas trop longue)
          if (taskText.length >= 10 && taskText.length <= 200) {
            // Capitaliser la première lettre si besoin
            if (taskText.isNotEmpty) {
              taskText = taskText[0].toUpperCase() + taskText.substring(1);
            }

            generatedTodos.add(
              TodoItem(
                id: 'gen_${DateTime.now().millisecondsSinceEpoch}_${generatedTodos.length}',
                title: taskText,
                category: 'AI Suggested',
                isCompleted: false,
                isUserDefault: false,
                isAiSuggested: true,
                createdAt: DateTime.now(),
                isSelectedForAddition: true, // Sélectionnée par défaut
              ),
            );

            if (_debugMode) debugPrint('    ✅ Tâche ajoutée: "$taskText"');

            // Limiter à 5 tâches max
            if (generatedTodos.length >= 5) break;
          } else {
            if (_debugMode)
              debugPrint('    ⚠️ Tâche ignorée (longueur: ${taskText.length})');
          }
        }
      }

      if (_debugMode) {
        debugPrint('📊 Résumé du parsing:');
        debugPrint('  - Lignes analysées: ${lines.length}');
        debugPrint('  - Tâches générées: ${generatedTodos.length}');
      }

      // Si aucune tâche n'a été parsée, utiliser le fallback
      if (generatedTodos.isEmpty) {
        if (_debugMode) {
          debugPrint('⚠️ Aucune tâche parsée depuis la réponse Gemini');
          debugPrint('🔄 Utilisation du fallback');
        }
        return _generateFallbackPersonalizedTasks(userContext);
      }

      if (_debugMode) {
        debugPrint(
          '✅ ${generatedTodos.length} tâches personnalisées générées avec succès',
        );
      }

      return generatedTodos;
    } on TimeoutException catch (e) {
      if (_debugMode) {
        debugPrint('⏰ Timeout lors de la génération personnalisée');
        debugPrint('   Erreur: $e');
      }
      return _generateFallbackPersonalizedTasks(userContext);
    } catch (e, stackTrace) {
      if (_debugMode) {
        debugPrint('❌ Erreur génération personnalisée: $e');
        debugPrint('📚 Stack trace:');
        debugPrint(stackTrace.toString());
      }
      return _generateFallbackPersonalizedTasks(userContext);
    }
  }

  List<TodoItem> _generateFallbackPersonalizedTasks(String userContext) {
    return _generateFallbackAiTasks();
  }

  // === GETTERS ===
  List<DateTime> get weekDays => _weekDays;
  DateTime get currentDate => _currentDate;
  List<TodoItem> get allTodos => List.from(_todos)
    ..sort((a, b) {
      if (a.isCompleted == b.isCompleted)
        return a.createdAt.compareTo(b.createdAt);
      return a.isCompleted ? 1 : -1;
    });
  List<TodoItem> getUserDefaultTodos() => _userDefaultTodos;
  double get completionPercentage => _todos.isEmpty
      ? 0.0
      : _todos.where((todo) => todo.isCompleted).length / _todos.length;
  bool get isInitialized => _isInitialized;
  bool get isAiEnabled => _aiEnabled;
  String get status => _status;
  bool get isGeminiActive => _isGeminiInitialized;

  Stream<List<TodoItem>> getTodosStream() {
    final dateKey = _currentDate.toIso8601String().split('T')[0];
    return _userTodosCollection.doc(dateKey).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data() as Map<String, dynamic>;
      final todosData = data['todos'] as List<dynamic>;
      return todosData
          .map(
            (todoData) =>
                TodoItem.fromFirestore(todoData as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) {
          if (a.isCompleted == b.isCompleted)
            return a.createdAt.compareTo(b.createdAt);
          return a.isCompleted ? 1 : -1;
        });
    });
  }

  Stream<List<TodoItem>> getDefaultTodosStream() {
    return _userDefaultsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => TodoItem.fromFirestore(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Stream<bool> get aiEnabledStream {
    return _userSettingsCollection.doc('preferences').snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return true;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['aiEnabled'] ?? true;
    });
  }

  // === METHODS ===
  Future<void> addTodo(TodoItem todo) async {
    _todos.add(todo);
    await _saveTodos();
  }

  Future<void> addUserDefaultTodo(String title) async {
    final todo = TodoItem(
      id: 'user_default_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: 'Self-Care & Well-Being',
      isCompleted: false,
      isUserDefault: true,
      isAiSuggested: false,
      createdAt: DateTime.now(),
    );
    _userDefaultTodos.add(todo);
    await _saveUserDefaultTodos();
  }

  Future<void> removeUserDefaultTodo(String id) async {
    _userDefaultTodos.removeWhere((todo) => todo.id == id);
    await _saveUserDefaultTodos();
    try {
      await _userDefaultsCollection.doc(id).delete();
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur suppression tâche par défaut: $e');
    }
  }

  Future<void> removeTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
    await _saveTodos();
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final oldTodo = _todos[index];
      final newTodo = oldTodo.copyWith(
        isCompleted: !oldTodo.isCompleted,
        completedAt: !oldTodo.isCompleted ? DateTime.now() : null,
      );
      _todos[index] = newTodo;
      await _saveTodos();
    }
  }

  Future<void> updateCurrentDate(DateTime date) async {
    _currentDate = date;
    await _loadTodos();
  }

  Future<void> setAiEnabled(bool enabled) async {
    _aiEnabled = enabled;
    await _saveUserSettings();
    if (_currentDate.day == DateTime.now().day) {
      await _generateNewDayTodos();
    }
  }

  Future<void> resetDay() async {
    await _generateNewDayTodos();
  }

  Future<void> clearUserData() async {
    try {
      final todosSnapshot = await _userTodosCollection.get();
      final batch1 = _firestore.batch();
      for (var doc in todosSnapshot.docs) batch1.delete(doc.reference);
      await batch1.commit();
      final defaultsSnapshot = await _userDefaultsCollection.get();
      final batch2 = _firestore.batch();
      for (var doc in defaultsSnapshot.docs) batch2.delete(doc.reference);
      await batch2.commit();
      _userDefaultTodos.clear();
      _todos.clear();
    } catch (e) {
      if (_debugMode) debugPrint('❌ Erreur effacement données: $e');
    }
  }
}
