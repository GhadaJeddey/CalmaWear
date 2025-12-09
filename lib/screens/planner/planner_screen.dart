// screens/planner/planner_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        context.go('/home');
        break;
      case 1: // Planner (current screen)
        break;
      case 2:
        context.go('/community');
        break;
      case 3:
        context.go('/chat');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fond plus doux
      body: SafeArea(
        child: Column(
          children: [
            // Header modernisé
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Routine Planner',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Configure Default Todos Button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF0F4FF),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              _showConfigureDefaultsDialog(context),
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Color(0xFF0066FF),
                          ),
                          tooltip: 'Configure Default Todos',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Generate AI Todos Button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF0F4FF),
                        ),
                        child: IconButton(
                          onPressed: () => _showGenerateTodosDialog(context),
                          icon: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF0066FF),
                          ),
                          tooltip: 'Generate AI Tasks',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Weekly Calendar modernisé
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0D000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildWeeklyCalendar(),
            ),
            SizedBox(height: 8),
            // Progress Tracker modernisé
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBBDEFB).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildProgressTracker(),
            ),
            SizedBox(height: 8),
            // Todo List Header modernisé
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'To Do List',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF0F4FF),
                    ),
                    child: TextButton.icon(
                      onPressed: () =>
                          context.read<PlannerProvider>().resetDay(),
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: Color(0xFF0066FF),
                      ),
                      label: const Text(
                        'New Day',
                        style: TextStyle(
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Todo List
            Expanded(child: _buildTodoList()),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066FF).withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context),
          backgroundColor: const Color(0xFF0066FF),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((date) {
        final isToday =
            date.day == currentDate.day &&
            date.month == currentDate.month &&
            date.year == currentDate.year;

        return GestureDetector(
          onTap: () => provider.updateCurrentDate(date),
          child: Container(
            width: 48,
            height: 60,
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF0066FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday ? Colors.transparent : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getDayName(date.weekday),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isToday
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isToday ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressTracker() {
    final percentage = context.watch<PlannerProvider>().completionPercentage;
    final todos = context.watch<PlannerProvider>().allTodos;
    final totalTodos = todos.length;
    final completedTodos = todos
        .where((todo) => (todo as TodoItem).isCompleted)
        .length;

    return Column(
      children: [
        Row(
          children: [
            // Circular Progress Indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Première ligne avec les deux textes alignés
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedTodos of $totalTodos completed',
                        style: const TextStyle(
                          fontSize: 16, // Légèrement réduit pour l'harmonie
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          percentage == 1.0
                              ? 'Done'
                              : percentage > 0.5
                              ? 'Almost Done'
                              : 'Keep Going',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Text(
                    'Complete all tasks to unlock achievements',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodoList() {
    final todos = context.watch<PlannerProvider>().allTodos;

    if (todos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF0F4FF),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Color(0xFF0066FF),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'All tasks completed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Time to relax or add more tasks',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF0066FF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index] as TodoItem;
        return _buildTodoItem(todo);
      },
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<PlannerProvider>().toggleTodo(todo.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: todo.isCompleted
                      ? const Color(0xFF0066FF) // Changé en bleu
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: todo.isCompleted
                    ? const Color(0xFF0066FF)
                    : Colors.transparent,
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Todo Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne avec catégorie et badges
                if (todo.category.isNotEmpty ||
                    todo.isAiSuggested ||
                    todo.isUserDefault)
                  Row(
                    children: [
                      // Afficher la catégorie seulement si le todo est AI
                      if (todo.isAiSuggested && todo.category.isNotEmpty)
                        Text(
                          todo.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: const Color(0xFF0066FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                      // Badge AI (uniquement si c'est généré par AI)
                      if (todo.isAiSuggested)
                        Container(
                          margin: EdgeInsets.only(
                            left: todo.category.isNotEmpty ? 6 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF0066FF),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                      // Badge DEFAULT
                      if (todo.isUserDefault)
                        Container(
                          margin: EdgeInsets.only(
                            left:
                                (todo.isAiSuggested || todo.category.isNotEmpty)
                                ? 6
                                : 0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF0066FF),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),

                if (todo.category.isNotEmpty ||
                    todo.isAiSuggested ||
                    todo.isUserDefault)
                  const SizedBox(height: 6),

                // Titre de la tâche
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: todo.isCompleted
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: const Color(0xFF9CA3AF),
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
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 219, 219, 219),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Color(0xFF0066FF)),
                    SizedBox(width: 12),
                    Text(
                      'Add New Task',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _todoController,
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0066FF)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _todoController.clear();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF0066FF),
                      ),
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0066FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Generate AI Tasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _localContextController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'e.g., "I\'m feeling stressed and overwhelmed today"',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0066FF),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
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
                                  'AI will suggest tasks based on your context',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Loading Indicator
                                if (_isLoading)
                                  Center(
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFF0066FF)),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Generating AI tasks...',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Generated Todos List
                                if (_generatedTodos.isNotEmpty) ...[
                                  const Text(
                                    'Select tasks to add to your list:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 300,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _generatedTodos.length,
                                      itemBuilder: (context, index) {
                                        final todo = _generatedTodos[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            border:
                                                index <
                                                    _generatedTodos.length - 1
                                                ? const Border(
                                                    bottom: BorderSide(
                                                      color: Color(0xFFE5E7EB),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: CheckboxListTile(
                                              title: Text(
                                                todo.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF3E8FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'AI',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: const Color(
                                                          0xFF0066FF,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w800,
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
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                              activeColor: const Color(
                                                0xFF0066FF,
                                              ),
                                            ),
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

                        const SizedBox(height: 20),

                        // Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Cancel Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Generate/Add Selected Button
                            if (_generatedTodos.isEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFF0066FF),
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      (_isLoading ||
                                          _localContextController.text
                                              .trim()
                                              .isEmpty)
                                      ? null
                                      : () async {
                                          setState(() => _isLoading = true);

                                          try {
                                            final generated = await context
                                                .read<PlannerProvider>()
                                                .generatePersonalizedTodos(
                                                  _localContextController.text
                                                      .trim(),
                                                );

                                            setState(() {
                                              _generatedTodos.clear();
                                              _generatedTodos.addAll(
                                                generated.map((todo) {
                                                  return TodoItem(
                                                    id: todo.id,
                                                    title: todo.title,
                                                    category: todo.category,
                                                    isCompleted:
                                                        todo.isCompleted,
                                                    isUserDefault:
                                                        todo.isUserDefault,
                                                    isAiSuggested:
                                                        todo.isAiSuggested,
                                                    createdAt: todo.createdAt,
                                                    completedAt:
                                                        todo.completedAt,
                                                    isSelectedForAddition: true,
                                                  );
                                                }),
                                              );
                                              _isLoading = false;
                                            });
                                          } catch (e) {
                                            setState(() => _isLoading = false);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error generating tasks: $e',
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFDC2626,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Generate Tasks',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            if (_generatedTodos.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFF10B981),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    final selectedTodos = _generatedTodos
                                        .where(
                                          (todo) =>
                                              todo.isSelectedForAddition ??
                                              false,
                                        )
                                        .toList();

                                    if (selectedTodos.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please select at least one task',
                                          ),
                                          backgroundColor: Color(0xFFF59E0B),
                                          behavior: SnackBarBehavior.floating,
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
                                        backgroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Selected',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: const Color(0xFFE3F2FD),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_outlined, color: Color(0xFF0066FF)),
                        SizedBox(width: 12),
                        Text(
                          'Configure Default Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Add new default todo
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _defaultTodoController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a daily task...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
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
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0066FF),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'These tasks will appear every day:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List of default todos
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: defaultTodos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star_outline,
                                    size: 48,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No default tasks yet',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: defaultTodos.length,
                              itemBuilder: (context, index) {
                                final todo = defaultTodos[index] as TodoItem;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFFF59E0B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          todo.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          context
                                              .read<PlannerProvider>()
                                              .removeUserDefaultTodo(todo.id);
                                          setState(() {});
                                        },
                                        icon: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFFEE2E2),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),

                    // AI Activation Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD8BFD8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI Daily Suggestions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  isAiEnabled
                                      ? '3 personalized tasks each day'
                                      : 'Enable for daily AI-powered task suggestions',
                                  style: TextStyle(
                                    fontSize: 13,
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
                            activeColor: const Color(0xFF9676AE),
                            trackColor: MaterialStateProperty.all(
                              const Color(0xFFD8BFD8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF0066FF),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 10,
                              ),
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
