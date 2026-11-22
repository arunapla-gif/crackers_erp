class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.module,
    required this.action,
    required this.username,
    required this.userRole,
    required this.summary,
    required this.isBackdated,
    required this.createdAt,
    this.recordId,
    this.targetDate,
    this.employeeId,
    this.employeeName,
    this.userId,
    this.beforeData,
    this.afterData,
    this.ipAddress,
  });

  final int id;
  final String module;
  final String action;
  final int? recordId;
  final String? targetDate;
  final int? employeeId;
  final String? employeeName;
  final int? userId;
  final String username;
  final String userRole;
  final String summary;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final bool isBackdated;
  final String? ipAddress;
  final DateTime createdAt;

  bool get isFlagged => isBackdated || action == 'DELETE';

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      module: (json['module'] ?? '').toString(),
      action: (json['action'] ?? '').toString().toUpperCase(),
      recordId: (json['recordId'] as num?)?.toInt(),
      targetDate: json['targetDate']?.toString(),
      employeeId: (json['employeeId'] as num?)?.toInt(),
      employeeName: json['employeeName']?.toString(),
      userId: (json['userId'] as num?)?.toInt(),
      username: (json['username'] ?? 'unknown').toString(),
      userRole: (json['userRole'] ?? 'Unknown').toString(),
      summary: (json['summary'] ?? '').toString(),
      beforeData: json['beforeData'] is Map<String, dynamic>
          ? json['beforeData'] as Map<String, dynamic>
          : null,
      afterData: json['afterData'] is Map<String, dynamic>
          ? json['afterData'] as Map<String, dynamic>
          : null,
      isBackdated: json['isBackdated'] == true,
      ipAddress: json['ipAddress']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class AuditLogPageData {
  const AuditLogPageData({required this.logs, required this.users});

  final List<AuditLogEntry> logs;
  final List<String> users;
}

