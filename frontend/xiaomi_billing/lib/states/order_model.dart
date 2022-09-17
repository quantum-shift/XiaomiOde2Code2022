import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'order_model.g.dart';

@HiveType(typeId: 1)
class Order {
  Order(
      {required this.orderDate,
      required this.customerName,
      required this.customerEmail,
      required this.customerPhone,
      required this.amountPaid,
      required this.productIds,
      required this.serialNos});

  @HiveField(0)
  final DateTime orderDate;
  @HiveField(1)
  final String customerName;
  @HiveField(2)
  final String customerEmail;
  @HiveField(3)
  final String customerPhone;
  @HiveField(4)
  final int amountPaid;
  @HiveField(5)
  final List<int> productIds;
  @HiveField(6)
  final List<String> serialNos;

  @override
  String toString() {
    return "{ orderDate: $orderDate , customerName: $customerName , customerEmail: $customerEmail , customerPhone: $customerPhone , amountPaid: $amountPaid , productIds: $productIds , serialNos: $serialNos }";
  }
}
