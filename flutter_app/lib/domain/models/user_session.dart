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

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isSupervisor => role.toUpperCase() == 'SUPERVISOR';
  bool get isRep => role.toUpperCase() == 'REP';
  bool get isStaff => role.toUpperCase() == 'STAFF';

  bool get canAccessErp =>
      isActive && (isAdmin || isSupervisor || isRep || isStaff);

  bool get canAccessSupervisorApp {
    if (isAdmin || isSupervisor) return true;
    if (isStaff) {
      return _hasPermission('production', 'view') ||
          _hasPermission('employees', 'view');
    }
    return false;
  }

  bool get canViewProduction =>
      isAdmin || isSupervisor || _hasPermission('production', 'view');
  bool get canViewEmployees =>
      isAdmin || isSupervisor || _hasPermission('employees', 'view');
  bool get canViewFactoryOrders => isAdmin || isSupervisor;

  /// Matches React Header.jsx / Dashboard.jsx RBAC semantics.
  bool canView(String module) {
    if (isAdmin) return true;
    if (isSupervisor) {
      return module == 'production' || module == 'employees';
    }
    if (isRep) return false;
    return _hasPermission(module, 'view');
  }

  bool canAdd(String module) {
    if (isAdmin) return true;
    if (isSupervisor) {
      return module == 'production' || module == 'employees' || module == 'advances';
    }
    if (isRep) return false;
    return _hasPermission(module, 'add');
  }

  bool canEdit(String module) {
    if (isAdmin) return true;
    if (isSupervisor) {
      return module == 'production' || module == 'employees';
    }
    if (isRep) return false;
    return _hasPermission(module, 'edit');
  }

  bool canDelete(String module) {
    if (isAdmin) return true;
    if (isSupervisor) return module == 'production';
    if (isRep) return false;
    return _hasPermission(module, 'delete');
  }

  /// For Sales Reps: optional list of allowed product categories/subcategories.
  List<String>? get allowedCategories {
    final raw = permissions['allowedCategories'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return null;
  }

  bool get showSalesSection =>
      isRep ||
      canView('billing') ||
      canView('customers') ||
      canView('transporters') ||
      canView('reports') ||
      canView('vehicles');

  bool get showPurchasesSection =>
      !isRep &&
      (canView('purchase') || canView('suppliers') || canView('materials'));

  bool get showGodownSection =>
      !isRep &&
      (canView('stock') ||
          canView('transfers') ||
          canView('godowns') ||
          canView('products') ||
          canView('vehicles') ||
          canView('materials'));

  bool get showProductionSection =>
      !isRep && (canView('production') || canView('machines'));

  bool get showHrSection =>
      !isRep && (isAdmin || canView('employees') || canView('payroll'));

  bool get showAdminSection => !isRep && (isAdmin || canView('reports'));

  bool _hasPermission(String module, String action) {
    final mod = permissions[module];
    if (mod is Map<String, dynamic>) {
      return mod[action] == true;
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
