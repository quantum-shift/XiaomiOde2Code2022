import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Stores global app state info
class GlobalData extends ChangeNotifier {
  /// Whether the cart page has been loaded before
  bool visitedCart = false;
  /// OperatorId of the operator of the app
  String operatorId = '';
  /// Store type
  String storeType = 'Mi Home';
  /// Customer name
  String customerName = '';
  /// Customer email
  String customerEmail = '';
  /// Phone no of customer
  String customerPhone = '';
  /// Unique id associated with each order
  String orderId = '';
  /// Communication preference of the customer : email / whatsapp
  String preferredCommunication = '';

  void setVisitedCart(bool visitedCart) {
    this.visitedCart = visitedCart;
    notifyListeners();
  }

  void setOperatorId(String operatorId) {
    this.operatorId = operatorId;
    notifyListeners();
  }

  void setStoreType(String storeType) {
    this.storeType = storeType;
    notifyListeners();
  }

  void setCustomerName(String customerName) {
    this.customerName = customerName;
    notifyListeners();
  }

  void setCustomerEmail(String customerEmail) {
    this.customerEmail = customerEmail;
    notifyListeners();
  }

  void setCustomerPhone(String customerPhone) {
    this.customerPhone = customerPhone;
    notifyListeners();
  }

  void setOrderId(String orderId) {
    this.orderId = orderId;
    notifyListeners();
  }

  void setPreferredCommunication(String preferredCommunication) {
    this.preferredCommunication = preferredCommunication;
    notifyListeners();
  }
}

/// Saves a [key]-[value] pair to local file
void saveDataToFile<T>(String key, T value) async {
  var box = await Hive.openBox('global');
  box.put(key, value);
}

/// Retrieve value for associated [key] from local file
Future<T> readDataFromFile<T>(String key) async {
  var box = await Hive.openBox('global');
  return box.get(key);
}
