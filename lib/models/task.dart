class Task {
  String id;
  String title;
  String description;
  String assignedTo;
  DateTime dueDate;
  String priority; // 'Low', 'Medium', 'High'
  String status;   // 'To Do', 'In Progress', 'Done'
  bool isCompleted;
  String? startTime; // e.g. '9:30 am'
  String? endTime;   // e.g. '3:30 pm'
  DateTime? createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.isCompleted = false,
    this.startTime,
    this.endTime,
    this.createdAt,
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
        'startTime': startTime,
        'endTime': endTime,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        assignedTo: json['assignedTo'] as String? ?? '',
        dueDate: json['dueDate'] != null
            ? (DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now())
            : DateTime.now(),
        priority: json['priority'] as String? ?? 'Medium',
        status: json['status'] as String? ?? 'To Do',
        isCompleted: json['isCompleted'] as bool? ?? false,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}