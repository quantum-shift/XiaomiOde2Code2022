import 'package:flutter/material.dart';
import 'package:xiaomi_billing/states/products_model.dart';

class CartModel extends ChangeNotifier {
  final List<int> _productIds = [];
  final List<String> _serialNos = [];
  bool visited = false;

  List<int> getProductIds() {
    return _productIds;
  }

  List<String> getSerialNos() {
    return _serialNos;
  }

  void addProduct(int productId, String serialNo) {
    _productIds.add(productId);
    _serialNos.add(serialNo);
    notifyListeners();
  }

  void removeAll() {
    _productIds.clear();
    _serialNos.clear();
    notifyListeners();
  }

  void removeId(int index) {
    _productIds.removeAt(index);
    _serialNos.removeAt(index);
    notifyListeners();
  }
}
