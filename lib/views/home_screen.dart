import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_list/models/item_model.dart';
import 'package:to_do_list/viewmodels/item_viewmodel.dart';
import 'package:to_do_list/services/notification_service.dart';
import 'package:to_do_list/views/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemModel> _items = [];
  List<ItemModel> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _initializeItems();
    _searchController.addListener(_onSearchChanged);

    // Ask permission for notifications
    NotificationService.requestPermission();
  }

  Future<void> _initializeItems() async {
    final viewModel = Provider.of<ItemViewModel>(context, listen: false);
    await viewModel.loadItems();
    setState(() {
      _items = List.from(viewModel.items);
      _filteredItems = _items;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = query.isEmpty
          ? List.from(_items)
          : _items
                .where((item) => item.task.toLowerCase().contains(query))
                .toList();
    });
  }

  void _addItem(String task, String description, DateTime? dueDate) async {
    final viewModel = Provider.of<ItemViewModel>(context, listen: false);
    await viewModel.addItem(task, description, dueDate);
    await _initializeItems();
  }

  void _deleteItem(int index, int itemId) async {
    final viewModel = Provider.of<ItemViewModel>(context, listen: false);
    await viewModel.deleteItem(itemId);
    await _initializeItems();
  }

  Future<bool?> _showConfirmDismissDialog(
    BuildContext context,
    int index,
    int id,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("To-Do"), centerTitle: true),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: const AssetImage("assets/logo.png"),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'To-Do',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Plan your day',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : isSearching
                ? ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildDismissibleItem(
                        _filteredItems[index],
                        index,
                        allowReorder: false,
                      );
                    },
                  )
                : ReorderableListView.builder(
                    itemCount: _items.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final viewModel = Provider.of<ItemViewModel>(
                        context,
                        listen: false,
                      );
                      await viewModel.reorderItems(oldIndex, newIndex);
                      await _initializeItems();
                    },
                    itemBuilder: (context, index) {
                      return _buildDismissibleItem(
                        _items[index],
                        index,
                        allowReorder: true,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDismissibleItem(
    ItemModel item,
    int index, {
    required bool allowReorder,
  }) {
    final key = ValueKey(item.id);
    final listTile = _buildListItem(item, index);

    return Container(
      key: key,
      child: Dismissible(
        key: ValueKey("dismiss-${item.id}"),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) =>
            _showConfirmDismissDialog(context, index, item.id!),
        onDismissed: (_) => _deleteItem(index, item.id!),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: listTile,
      ),
    );
  }

  Widget _buildListItem(ItemModel item, int index) {
    final now = DateTime.now();
    final hasDueDate = item.dueDate != null;
    final isOverdue = hasDueDate && item.dueDate!.isBefore(now);
    final isDueSoon =
        hasDueDate &&
        item.dueDate!.isAfter(now) &&
        item.dueDate!.isBefore(now.add(const Duration(hours: 24)));

    Color dueDateColor;
    if (item.isDone) {
      dueDateColor = Colors.green;
    } else if (isOverdue) {
      dueDateColor = Colors.red;
    } else if (isDueSoon) {
      dueDateColor = Colors.orange;
    } else {
      dueDateColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            item.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: item.isDone ? Colors.green : Colors.grey,
          ),
          onPressed: () async {
            final viewModel = Provider.of<ItemViewModel>(
              context,
              listen: false,
            );
            await viewModel.toggleItemDone(item);
            await _initializeItems();
          },
        ),
        title: Text(
          item.task,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
            color: item.isDone ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (item.description?.isNotEmpty ?? false)
                  ? item.description!
                  : "No description",
              style: TextStyle(color: item.isDone ? Colors.grey : null),
            ),
            if (item.dueDate != null)
              Text(
                "Due: ${item.dueDate!.toLocal()}".split('.').first,
                style: TextStyle(
                  fontSize: 12,
                  color: dueDateColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditTaskDialog(context, item, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, index, item.id!),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final taskController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add New Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(labelText: "Task"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Due Date: "),
                    Text(
                      selectedDate == null
                          ? "Not set"
                          : "${selectedDate!.toLocal()}".split('.')[0],
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Add"),
                onPressed: () {
                  final task = taskController.text.trim();
                  final desc = descController.text.trim();
                  if (task.isNotEmpty) {
                    _addItem(task, desc, selectedDate);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Task title cannot be empty"),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, ItemModel item, int index) {
    final taskController = TextEditingController(text: item.task);
    final descController = TextEditingController(text: item.description ?? "");
    DateTime? selectedDate = item.dueDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(labelText: "Task"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: "Description (optional)",
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Due Date: "),
                    Text(
                      selectedDate == null
                          ? "Not set"
                          : "${selectedDate!.toLocal()}".split('.')[0],
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Update"),
                onPressed: () async {
                  final task = taskController.text.trim();
                  final desc = descController.text.trim();
                  if (task.isNotEmpty) {
                    final updatedItem = ItemModel(
                      id: item.id,
                      task: task,
                      description: desc,
                      isDone: item.isDone,
                      position: item.position,
                      dueDate: selectedDate,
                    );
                    await Provider.of<ItemViewModel>(
                      context,
                      listen: false,
                    ).updateItem(updatedItem);
                    await _initializeItems();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Task title cannot be empty"),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(index, id);
            },
          ),
        ],
      ),
    );
  }
}
