import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ItemViewModel extends ChangeNotifier {
  List<ItemModel> _items = [];
  List<ItemModel> get items => _items;

  final DatabaseService _db = DatabaseService();

  Future<void> loadItems() async {
    _items = await _db.getItems();
    notifyListeners();
  }

  Future<void> addItem(String task, String desc, DateTime? dueDate) async {
    final newItem = ItemModel(
      task: task,
      description: desc,
      isDone: false,
      position: _items.length,
      dueDate: dueDate,
    );

    newItem.id = await _db.addItem(newItem);
    _items.add(newItem);
    notifyListeners();

    // Schedule reminder if due date is provided
    if (dueDate != null && newItem.id != null) {
      await NotificationService.scheduleNotification(
        id: newItem.id!,
        title: task,
        dateTime: dueDate,
      );
    }
  }

  Future<void> updateItem(ItemModel updated) async {
    await _db.updateItem(updated);
    final index = _items.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      _items[index] = updated;
      notifyListeners();

      // Reschedule notification if due date changed
      if (updated.dueDate != null && updated.id != null) {
        await NotificationService.cancelNotification(updated.id!);
        await NotificationService.scheduleNotification(
          id: updated.id!,
          title: updated.task,
          dateTime: updated.dueDate!,
        );
      }
    }
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    _items.removeWhere((item) => item.id == id);
    await _db.updatePositions(_items);
    notifyListeners();

    // Cancel the scheduled notification
    await NotificationService.cancelNotification(id);
  }

  Future<void> toggleItemDone(ItemModel item) async {
    final updated = ItemModel(
      id: item.id,
      task: item.task,
      description: item.description,
      isDone: !item.isDone,
      position: item.position,
      dueDate: item.dueDate,
    );
    await updateItem(updated);
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    await _db.updatePositions(_items);
    notifyListeners();
  }
}
