class Task {
  String id;
  String title;
  String description;
  String assignedTo;
  DateTime dueDate;
  String priority; // 'Low', 'Medium', 'High'
  String status;   // 'To Do', 'In Progress', 'Done'
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority,
        'status': status,
        'isCompleted': isCompleted,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        assignedTo: json['assignedTo'],
        dueDate: DateTime.parse(json['dueDate']),
        priority: json['priority'],
        status: json['status'],
        isCompleted: json['isCompleted'],
      );
}