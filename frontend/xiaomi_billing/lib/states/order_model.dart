import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'order_model.g.dart';

/// Serializable class storing the info associated with each order
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

  /// Date of the order
  @HiveField(0)
  final DateTime orderDate;
  /// Name of the customer
  @HiveField(1)
  final String customerName;
  /// Email id of customer
  @HiveField(2)
  final String customerEmail;
  /// Phone number of customer
  @HiveField(3)
  final String customerPhone;
  /// List of products purchased (represented by their product ids)
  @HiveField(4)
  final List<int> productIds;
  /// Serial numbers of products purchased
  @HiveField(5)
  final List<String> serialNos;
  /// Id of the operator who completed the order
  @HiveField(6)
  final String operatorId;

  @override
  String toString() {
    return "{ orderDate: $orderDate , customerName: $customerName , customerEmail: $customerEmail , customerPhone: $customerPhone , productIds: $productIds , serialNos: $serialNos , operatorId: $operatorId }";
  }
}
