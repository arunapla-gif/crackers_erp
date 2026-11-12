import 'dart:convert';

import 'customer.dart';
import 'json_helpers.dart';

class SalesOrderLeadCustomer {
  const SalesOrderLeadCustomer({
    required this.name,
    this.mobile = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.idNumber = '',
    this.gstin = '',
    this.type = 'UNREGISTERED',
  });

  final String name;
  final String mobile;
  final String city;
  final String state;
  final String pincode;
  final String idNumber;
  final String gstin;
  final String type; // 'GST' | 'UNREGISTERED'

  factory SalesOrderLeadCustomer.fromJson(Map<String, dynamic> json) {
    return SalesOrderLeadCustomer(
      name: (json['name'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      idNumber: (json['id_number'] ?? '').toString(),
      gstin: (json['gstin'] ?? '').toString(),
      type: (json['type'] ?? 'UNREGISTERED').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'city': city,
      'state': state,
      'pincode': pincode,
      'id_number': idNumber,
      'gstin': gstin,
      'type': type,
    };
  }
}

class SalesOrderItem {
  const SalesOrderItem({
    this.id,
    this.productId,
    required this.product,
    required this.qty,
    required this.rate,
    required this.total,
  });

  final int? id;
  final int? productId;
  final String product;
  final int qty; // Cases
  final double rate;
  final double total;

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      id: json['id'] == null ? null : parseInt(json['id']),
      productId: json['productId'] == null ? null : parseInt(json['productId']),
      product: (json['product'] ?? '').toString(),
      qty: parseInt(json['qty'], fallback: 1),
      rate: parseDouble(json['rate']),
      total: parseDouble(json['total']),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'productId': productId,
      'product': product,
      'qty': qty,
      'rate': rate,
      'total': total,
    };
  }
}

class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.repId,
    this.repUsername,
    this.customerId,
    this.customer,
    this.newCustomerData,
    required this.status,
    required this.subtotal,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int repId;
  final String? repUsername;
  final int? customerId;
  final Customer? customer;
  final SalesOrderLeadCustomer? newCustomerData;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final double subtotal;
  final List<SalesOrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isNewLead => customerId == null && newCustomerData != null;

  String get displayCustomerName {
    if (customer != null && customer!.name.isNotEmpty) return customer!.name;
    if (newCustomerData != null && newCustomerData!.name.isNotEmpty) {
      return newCustomerData!.name;
    }
    return 'New Customer';
  }

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    final repRaw = json['rep'];
    final custRaw = json['customer'];
    final rawLead = json['newCustomerData'];

    SalesOrderLeadCustomer? lead;
    if (rawLead is Map<String, dynamic>) {
      lead = SalesOrderLeadCustomer.fromJson(rawLead);
    } else if (rawLead is String && rawLead.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLead);
        if (decoded is Map<String, dynamic>) {
          lead = SalesOrderLeadCustomer.fromJson(decoded);
        }
      } catch (_) {}
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SalesOrderItem.fromJson)
              .toList()
        : const <SalesOrderItem>[];

    return SalesOrder(
      id: parseInt(json['id']),
      repId: parseInt(json['repId']),
      repUsername: repRaw is Map<String, dynamic>
          ? parseOptionalString(repRaw['username'])
          : null,
      customerId: json['customerId'] == null ? null : parseInt(json['customerId']),
      customer: custRaw is Map<String, dynamic>
          ? Customer.fromJson(custRaw)
          : null,
      newCustomerData: lead,
      status: (json['status'] ?? 'PENDING').toString(),
      subtotal: parseDouble(json['subtotal']),
      items: items,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}

class RepRecentOrder {
  const RepRecentOrder({
    required this.id,
    required this.customerName,
    required this.status,
    required this.subtotal,
    required this.date,
  });

  final int id;
  final String customerName;
  final String status;
  final double subtotal;
  final DateTime date;

  factory RepRecentOrder.fromJson(Map<String, dynamic> json) {
    return RepRecentOrder(
      id: parseInt(json['id']),
      customerName: (json['customerName'] ?? 'New Customer').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      subtotal: parseDouble(json['subtotal']),
      date: parseDateTime(json['date']),
    );
  }
}

class RepDashboardStats {
  const RepDashboardStats({
    required this.totalSales,
    required this.pendingOrdersCount,
    required this.totalCustomers,
    required this.recentOrders,
  });

  final double totalSales;
  final int pendingOrdersCount;
  final int totalCustomers;
  final List<RepRecentOrder> recentOrders;

  factory RepDashboardStats.fromJson(Map<String, dynamic> json) {
    final rawRecent = json['recentOrders'];
    final recent = rawRecent is List
        ? rawRecent
              .whereType<Map<String, dynamic>>()
              .map(RepRecentOrder.fromJson)
              .toList()
        : const <RepRecentOrder>[];
    return RepDashboardStats(
      totalSales: parseDouble(json['totalSales']),
      pendingOrdersCount: parseInt(json['pendingOrdersCount']),
      totalCustomers: parseInt(json['totalCustomers']),
      recentOrders: recent,
    );
  }
}

class VerifyCustomerLeadArgs {
  const VerifyCustomerLeadArgs({
    required this.orderId,
    required this.leadData,
  });

  final int orderId;
  final SalesOrderLeadCustomer leadData;
}
