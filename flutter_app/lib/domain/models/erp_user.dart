import 'json_helpers.dart';

class ErpModulePermission {
  const ErpModulePermission({
    this.view = false,
    this.add = false,
    this.edit = false,
    this.delete = false,
  });

  final bool view;
  final bool add;
  final bool edit;
  final bool delete;

  bool get allSelected => view && add && edit && delete;

  ErpModulePermission copyWith({
    bool? view,
    bool? add,
    bool? edit,
    bool? delete,
  }) {
    return ErpModulePermission(
      view: view ?? this.view,
      add: add ?? this.add,
      edit: edit ?? this.edit,
      delete: delete ?? this.delete,
    );
  }

  factory ErpModulePermission.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ErpModulePermission();
    return ErpModulePermission(
      view: json['view'] == true,
      add: json['add'] == true,
      edit: json['edit'] == true,
      delete: json['delete'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view': view,
      'add': add,
      'edit': edit,
      'delete': delete,
    };
  }
}

class ErpUser {
  const ErpUser({
    required this.id,
    required this.username,
    required this.role,
    required this.status,
    this.modulePermissions = const {},
    this.allowedCategories,
  });

  final int id;
  final String username;
  final String role; // 'ADMIN' | 'STAFF' | 'REP' | 'SUPERVISOR'
  final String status; // 'Active' | 'Inactive'
  final Map<String, ErpModulePermission> modulePermissions;
  final List<String>? allowedCategories;

  bool get isActive => status.toLowerCase() != 'inactive';

  factory ErpUser.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final modules = <String, ErpModulePermission>{};
    List<String>? allowedCats;

    if (rawPerms is Map<String, dynamic>) {
      rawPerms.forEach((key, value) {
        if (key == 'allowedCategories' && value is List) {
          allowedCats = value.map((e) => e.toString()).toList();
        } else if (value is Map<String, dynamic>) {
          modules[key] = ErpModulePermission.fromJson(value);
        }
      });
    }

    return ErpUser(
      id: parseInt(json['id']),
      username: (json['username'] ?? '').toString().trim(),
      role: (json['role'] ?? 'STAFF').toString(),
      status: (json['status'] ?? 'Active').toString(),
      modulePermissions: modules,
      allowedCategories: allowedCats,
    );
  }

  Map<String, dynamic> toSavePayload({String? pin}) {
    final permsPayload = <String, dynamic>{};
    if (role == 'STAFF') {
      modulePermissions.forEach((key, perm) {
        permsPayload[key] = perm.toJson();
      });
    } else if (role == 'REP') {
      permsPayload['allowedCategories'] = allowedCategories ?? const <String>[];
    }

    return {
      if (id > 0) 'id': id,
      'username': username.trim(),
      if (pin != null && pin.trim().isNotEmpty) 'pin': pin.trim(),
      'role': role,
      'status': status,
      'permissions': permsPayload,
    };
  }
}

