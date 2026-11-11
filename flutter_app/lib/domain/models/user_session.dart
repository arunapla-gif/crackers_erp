import 'json_helpers.dart';

class UserAccount {
  const UserAccount({
    required this.id,
    required this.username,
    required this.role,
    required this.status,
    required this.permissions,
  });

  final int id;
  final String username;
  final String role;
  final String status;
  final Map<String, dynamic> permissions;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isSupervisor => role.toUpperCase() == 'SUPERVISOR';
  bool get isRep => role.toUpperCase() == 'REP';
  bool get isStaff => role.toUpperCase() == 'STAFF';

  bool get canAccessSupervisorApp {
    if (isAdmin || isSupervisor) return true;
    if (isStaff) {
      return _hasView('production') || _hasView('employees');
    }
    return false;
  }

  bool get canViewProduction => isAdmin || isSupervisor || _hasView('production');
  bool get canViewEmployees => isAdmin || isSupervisor || _hasView('employees');
  bool get canViewFactoryOrders => isAdmin || isSupervisor;

  bool _hasView(String module) {
    final mod = permissions[module];
    if (mod is Map<String, dynamic>) {
      return mod['view'] == true;
    }
    return false;
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    return UserAccount(
      id: parseInt(json['id']),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? 'STAFF').toString(),
      status: (json['status'] ?? 'Active').toString(),
      permissions: rawPerms is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawPerms)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'status': status,
      'permissions': permissions,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final UserAccount user;
}

