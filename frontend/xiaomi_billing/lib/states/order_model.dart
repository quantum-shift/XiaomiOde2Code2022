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
      required this.productIds,
      required this.serialNos,
      required this.operatorId});

  @HiveField(0)
  final DateTime orderDate;
  @HiveField(1)
  final String customerName;
  @HiveField(2)
  final String customerEmail;
  @HiveField(3)
  final String customerPhone;
  @HiveField(4)
  final List<int> productIds;
  @HiveField(5)
  final List<String> serialNos;
  @HiveField(6)
  final String operatorId;

  @override
  String toString() {
    return "{ orderDate: $orderDate , customerName: $customerName , customerEmail: $customerEmail , customerPhone: $customerPhone , productIds: $productIds , serialNos: $serialNos , operatorId: $operatorId }";
  }
}
