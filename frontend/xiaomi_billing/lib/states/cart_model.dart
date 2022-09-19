import 'package:flutter/material.dart';

class CartModel extends ChangeNotifier {
  final List<int> _productIds = [];
  final List<String> _serialNos = [];

  List<int> getProductIds() {
    return _productIds;
  }

  List<String> getSerialNos() {
    return _serialNos;
  }

  int getCartItemCount() {
    return _productIds.length;
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
