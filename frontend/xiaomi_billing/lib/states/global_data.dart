import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GlobalData extends ChangeNotifier {
  bool visitedCart = false;
  String operatorId = '';
  String storeType = 'Mobile Store';
  String customerName = '';
  String customerEmail = '';
  String customerPhone = '';
  String orderId = '';
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

void saveDataToFile<T>(String key, T value) async {
  var box = await Hive.openBox('global');
  box.put(key, value);
}

Future<T> readDataFromFile<T>(String key) async {
  var box = await Hive.openBox('global');
  return box.get(key);
}
