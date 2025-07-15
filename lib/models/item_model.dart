class ItemModel {
  int? id;
  String task;
  String? description;
  bool isDone;
  int position;
  DateTime? dueDate;

  ItemModel({
    this.id,
    required this.task,
    this.description,
    this.isDone = false,
    required this.position,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'description': description ?? '',
      'isDone': isDone ? 1 : 0,
      'position': position,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      task: map['task'],
      description: map['description'],
      isDone: map['isDone'] == 1,
      position: map['position'],
      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'])
          : null,
    );
  }
}
