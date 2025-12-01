// screens/planner/planner_screen.dart
import 'package:flutter/material.dart';
import '../dashboard/home_screen.dart';
import '../chat/chat_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../../models/todo_item.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({Key? key}) : super(key: key);
  @override
  _PlannerScreenState createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  int _currentBottomNavIndex = 1;
  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _defaultTodoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure provider is initialized
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatScreen(fromScreen: 'planner'),
          ),
          (route) => false,
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => CommunityScreen()),
          (route) => false,
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Routine Planner',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stay organized and productive',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Configure Default Todos Button
                      IconButton(
                        onPressed: () => _showConfigureDefaultsDialog(context),
                        icon: const Icon(Icons.settings, color: Colors.black),
                        tooltip: 'Configure Default Todos',
                      ),
                      // Generate AI Todos Button
                      IconButton(
                        onPressed: () => _showGenerateTodosDialog(context),
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.black,
                        ),
                        tooltip: 'Generate AI Tasks',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Weekly Calendar
            _buildWeeklyCalendar(),

            // Progress Tracker
            _buildProgressTracker(),

            // Todo List Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TO DO LIST',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.read<PlannerProvider>().resetDay(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('New Day'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ],
              ),
            ),

            // Todo List
            Expanded(child: _buildTodoList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final provider = context.watch<PlannerProvider>();
    final weekDays = provider.weekDays;
    final currentDate = provider.currentDate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays.map((date) {
          final isToday =
              date.day == currentDate.day &&
              date.month == currentDate.month &&
              date.year == currentDate.year;

          return GestureDetector(
            onTap: () => provider.updateCurrentDate(date),
            child: Container(
              width: 40,
              height: 60,
              decoration: BoxDecoration(
                color: isToday ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressTracker() {
    final percentage = context.watch<PlannerProvider>().completionPercentage;
    final todos = context.watch<PlannerProvider>().allTodos;
    final totalTodos = todos.length;
    final completedTodos = todos
        .where((todo) => (todo as TodoItem).isCompleted)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Daily Task List',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                percentage > 0.5 ? 'Almost Done' : 'Keep Going',
                style: TextStyle(
                  fontSize: 14,
                  color: percentage > 0.5 ? Colors.green[600] : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Circular Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage > 0.5 ? Colors.green[600]! : Colors.orange,
                      ),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedTodos of $totalTodos completed',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage > 0.5 ? Colors.green[600]! : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    final todos = context.watch<PlannerProvider>().allTodos;

    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'All tasks completed!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showAddTaskDialog(context),
              child: const Text('Add a new task'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: todos.length + 1,
      itemBuilder: (context, index) {
        if (index == todos.length) {
          return Container(
            margin: const EdgeInsets.only(top: 16, bottom: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
            ),
          );
        }

        final todo = todos[index] as TodoItem; // CAST EXPLICITE ICI
        return _buildTodoItem(todo);
      },
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
    // TYPE EXPLICITE ICI AUSSI
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              context.read<PlannerProvider>().toggleTodo(todo.id);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: todo.isCompleted ? Colors.green : Colors.grey[300]!,
                  width: 2,
                ),
                color: todo.isCompleted ? Colors.green : Colors.transparent,
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Todo Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      todo.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: todo.isAiSuggested
                            ? Colors.purple[600]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (todo.isAiSuggested)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (todo.isUserDefault)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 16,
                    color: todo.isCompleted ? Colors.grey : Colors.black,
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.grey,
                    decorationThickness: 2.0,
                  ),
                ),
              ],
            ),
          ),
          // Delete Button
          IconButton(
            onPressed: () {
              context.read<PlannerProvider>().removeTodo(todo.id);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: _todoController,
            decoration: const InputDecoration(
              hintText: 'Enter task description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _todoController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_todoController.text.isNotEmpty) {
                  context.read<PlannerProvider>().addTodo(
                    _todoController.text,
                    'Self-Care & Well-Being',
                  );
                  Navigator.pop(context);
                  _todoController.clear();
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  void _showGenerateTodosDialog(BuildContext context) {
    final TextEditingController _localContextController =
        TextEditingController();
    final List<TodoItem> _generatedTodos = [];
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight:
                      MediaQuery.of(context).size.height *
                      0.8, // 80% de la hauteur d'écran
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (fixe)
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'Generate AI Tasks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contenu scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Context Input
                              const Text(
                                'Describe your day or needs:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _localContextController,
                                decoration: InputDecoration(
                                  hintText:
                                      'e.g., "I\'m feeling stressed and overwhelmed today"',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                maxLines: 3,
                                enabled: !_isLoading,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'AI will suggest self-care tasks based on your context',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Loading Indicator
                              if (_isLoading)
                                const Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text('Generating AI tasks...'),
                                    ],
                                  ),
                                ),

                              // Generated Todos List
                              if (_generatedTodos.isNotEmpty) ...[
                                const Text(
                                  'Select tasks to add to your list:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 300, // Hauteur max pour la liste
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(), // Le parent gère le scroll
                                    itemCount: _generatedTodos.length,
                                    itemBuilder: (context, index) {
                                      final todo = _generatedTodos[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          border:
                                              index < _generatedTodos.length - 1
                                              ? const Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        child: CheckboxListTile(
                                          title: Text(
                                            todo.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple[50]!,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'AI',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.purple[600]!,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          value:
                                              todo.isSelectedForAddition ??
                                              true,
                                          onChanged: (value) {
                                            setState(() {
                                              _generatedTodos[index] = todo
                                                  .copyWith(
                                                    isSelectedForAddition:
                                                        value,
                                                  );
                                            });
                                          },
                                          dense: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Buttons Row (fixe en bas)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel Button
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),

                          const SizedBox(width: 8),

                          // Generate/Add Selected Button
                          if (_generatedTodos.isEmpty)
                            ElevatedButton(
                              onPressed:
                                  (_isLoading ||
                                      _localContextController.text
                                          .trim()
                                          .isEmpty)
                                  ? null
                                  : () async {
                                      print('Generate button pressed!');
                                      print(
                                        'Text: ${_localContextController.text}',
                                      );

                                      setState(() => _isLoading = true);

                                      try {
                                        print(
                                          'Calling generatePersonalizedTodos...',
                                        );
                                        final generated = await context
                                            .read<PlannerProvider>()
                                            .generatePersonalizedTodos(
                                              _localContextController.text
                                                  .trim(),
                                            );

                                        print(
                                          'Generated ${generated.length} tasks',
                                        );

                                        setState(() {
                                          _generatedTodos.clear();
                                          _generatedTodos.addAll(
                                            generated.map((todo) {
                                              return TodoItem(
                                                id: todo.id,
                                                title: todo.title,
                                                category: todo.category,
                                                isCompleted: todo.isCompleted,
                                                isUserDefault:
                                                    todo.isUserDefault,
                                                isAiSuggested:
                                                    todo.isAiSuggested,
                                                createdAt: todo.createdAt,
                                                completedAt: todo.completedAt,
                                                isSelectedForAddition: true,
                                              );
                                            }),
                                          );
                                          _isLoading = false;
                                        });

                                        print(
                                          'Dialog updated with ${_generatedTodos.length} tasks',
                                        );
                                      } catch (e, stackTrace) {
                                        print('Error generating tasks: $e');
                                        print('Stack trace: $stackTrace');

                                        setState(() => _isLoading = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error generating tasks: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                              ),
                              child: const Text('Generate Tasks'),
                            ),

                          if (_generatedTodos.isNotEmpty)
                            ElevatedButton(
                              onPressed: () {
                                print('Add Selected button pressed');
                                final selectedTodos = _generatedTodos
                                    .where(
                                      (todo) =>
                                          todo.isSelectedForAddition ?? false,
                                    )
                                    .toList();

                                print('Selected ${selectedTodos.length} tasks');

                                if (selectedTodos.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select at least one task',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                context
                                    .read<PlannerProvider>()
                                    .addSelectedTodos(selectedTodos);

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added ${selectedTodos.length} task${selectedTodos.length > 1 ? 's' : ''} to your list',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Add Selected'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showConfigureDefaultsDialog(BuildContext context) {
    final defaultTodos = context.read<PlannerProvider>().userDefaultTodos;
    final isAiEnabled = context.read<PlannerProvider>().isAiEnabled;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Configure Default Daily Tasks'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),

                    // Add new default todo
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _defaultTodoController,
                            decoration: const InputDecoration(
                              hintText: 'Add a daily task...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_defaultTodoController.text.isNotEmpty) {
                              context
                                  .read<PlannerProvider>()
                                  .addUserDefaultTodo(
                                    _defaultTodoController.text,
                                  );
                              _defaultTodoController.clear();
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.add_circle),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'These tasks will appear every day:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // List of default todos
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: defaultTodos.length,
                        itemBuilder: (context, index) {
                          final todo = defaultTodos[index] as TodoItem;
                          return ListTile(
                            leading: const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            title: Text(todo.title),
                            trailing: IconButton(
                              onPressed: () {
                                context
                                    .read<PlannerProvider>()
                                    .removeUserDefaultTodo(todo.id);
                                setState(() {});
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                    // AI Activation Toggle
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AI Daily Suggestions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    isAiEnabled
                                        ? 'AI will suggest 3 tasks each day'
                                        : 'AI suggestions are disabled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAiEnabled,
                              onChanged: (value) async {
                                await context
                                    .read<PlannerProvider>()
                                    .setAiEnabled(value);
                                setState(() {});
                              },
                              activeColor: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      case 7:
        return 'SUN';
      default:
        return '';
    }
  }
}
