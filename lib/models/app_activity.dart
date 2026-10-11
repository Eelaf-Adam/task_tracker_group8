class AppActivity {
  final String id;
  final String userName;
  final String action;
  final String targetTitle;
  final DateTime timestamp;
  final String? taskId;

  const AppActivity({
    required this.id,
    required this.userName,
    required this.action,
    required this.targetTitle,
    required this.timestamp,
    this.taskId,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'action': action,
        'targetTitle': targetTitle,
        'timestamp': timestamp.toIso8601String(),
        if (taskId != null) 'taskId': taskId,
      };

  factory AppActivity.fromJson(Map<String, dynamic> json) => AppActivity(
        id: json['id'] as String? ?? '',
        userName: json['userName'] as String? ?? 'Team Member',
        action: json['action'] as String? ?? 'updated',
        targetTitle: json['targetTitle'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        taskId: json['taskId'] as String?,
      );
}
