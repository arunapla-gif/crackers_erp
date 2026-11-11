import 'package:crackers_erp/domain/models/daily_production.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/employee_advance.dart';
import 'package:crackers_erp/domain/models/factory_order.dart';
import 'package:crackers_erp/domain/models/user_session.dart';
import 'package:crackers_erp/domain/models/wip_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Models', () {
    test('UserAccount role checks authorize Supervisor & Admin, block Rep', () {
      final supervisor = UserAccount.fromJson({
        'id': 1,
        'username': 'sup1',
        'role': 'SUPERVISOR',
        'status': 'Active',
        'permissions': <String, dynamic>{},
      });
      expect(supervisor.canAccessSupervisorApp, isTrue);
      expect(supervisor.canViewProduction, isTrue);
      expect(supervisor.canViewEmployees, isTrue);
      expect(supervisor.canViewFactoryOrders, isTrue);

      final rep = UserAccount.fromJson({
        'id': 2,
        'username': 'rep1',
        'role': 'REP',
        'status': 'Active',
        'permissions': <String, dynamic>{},
      });
      expect(rep.canAccessSupervisorApp, isFalse);

      final prodStaff = UserAccount.fromJson({
        'id': 3,
        'username': 'staff1',
        'role': 'STAFF',
        'status': 'Active',
        'permissions': {
          'production': {'view': true},
        },
      });
      expect(prodStaff.canAccessSupervisorApp, isTrue);
      expect(prodStaff.canViewProduction, isTrue);
      expect(prodStaff.canViewEmployees, isFalse);
      expect(prodStaff.canViewFactoryOrders, isFalse);
    });

    test('Employee parses Prisma Decimal string & never includes salary in payload', () {
      final emp = Employee.fromJson({
        'id': 10,
        'name': 'Karthik ',
        'mobile': '9999988888',
        'role': 'Rolling',
        'paymentType': 'Contractual',
        'unit': 'Unit 1',
        'status': 'Active',
        'advanceBalance': '1250.50',
        'salary': null,
      });

      expect(emp.name, equals('Karthik'));
      expect(emp.advanceBalance, closeTo(1250.50, 0.001));
      expect(emp.isContractual, isTrue);

      final payload = emp.toSupervisorPayload();
      expect(payload.containsKey('salary'), isFalse);
      expect(payload['name'], equals('Karthik'));
      expect(payload['paymentType'], equals('Contractual'));
    });

    test('WipProduct handles rate-free factory WIP payload', () {
      final prod = WipProduct.fromJson({
        'id': 4,
        'code': 'WIP04',
        'name': '10cm Colour Sparklers',
        'type': 'WIP',
        'category': 'Sparklers',
        'unit': 'Pcs',
        'boxesPerCase': '12',
        'status': 'Active',
      });
      expect(prod.isWip, isTrue);
      expect(prod.boxesPerCase, equals(12));
      expect(prod.displayGroup, equals('Sparklers'));
    });

    test('EmployeeAdvance parses Decimal amount & employee projection', () {
      final adv = EmployeeAdvance.fromJson({
        'id': 5,
        'employeeId': 10,
        'date': '2026-11-11T00:00:00.000Z',
        'type': 'GIVEN',
        'amount': '500.00',
        'description': 'Cash Advance',
        'employee': {
          'id': 10,
          'name': 'Karthik',
          'role': 'Rolling',
          'advanceBalance': '1750.00',
        },
      });
      expect(adv.isGiven, isTrue);
      expect(adv.amount, equals(500.0));
      expect(adv.employeeName, equals('Karthik'));
      expect(adv.employeeBalance, equals(1750.0));
    });

    test('DailyProductionRecord ignores 0 quantity items and sums quantities', () {
      final rec = DailyProductionRecord.fromJson({
        'id': 9,
        'date': '2026-11-11T00:00:00.000Z',
        'employeeId': 10,
        'employee': {'id': 10, 'name': 'Karthik', 'role': 'Rolling'},
        'items': [
          {'itemName': '12cm Electric', 'quantity': 200},
          {'itemName': 'Empty Row', 'quantity': 0},
          {'itemName': 'Chakkar', 'quantity': '50'},
        ],
      });
      expect(rec.items.length, equals(2));
      expect(rec.totalPieces, equals(250));
      expect(rec.isoDate, equals('2026-11-11'));
    });

    test('FactoryOrder calculates case and box quantities without prices', () {
      final order = FactoryOrder.fromJson({
        'id': 88,
        'status': 'APPROVED',
        'createdAt': '2026-11-11T07:00:00.000Z',
        'updatedAt': '2026-11-11T09:00:00.000Z',
        'customer': {
          'name': 'Lakshmi Traders',
          'city': 'Coimbatore',
          'state': 'TN',
        },
        'rep': {'username': 'rep_west'},
        'items': [
          {'productId': 1, 'product': 'Sparkler Box', 'qty': 5, 'boxesPerCase': 20},
          {'productId': 2, 'product': 'Chakkar Box', 'qty': 3, 'boxesPerCase': 10},
        ],
      });
      expect(order.totalCases, equals(8));
      expect(order.items[0].totalBoxes, equals(100));
      expect(order.items[1].totalBoxes, equals(30));
      expect(order.locationLabel, equals('Coimbatore, TN'));
    });
  });
}

