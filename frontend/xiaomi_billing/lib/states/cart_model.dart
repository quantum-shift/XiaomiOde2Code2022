import 'package:flutter/material.dart';

/// Defines the state of the cart
class CartModel extends ChangeNotifier {
  /// List of product-ids of items in the cart
  final List<int> _productIds = [];
  /// List of serial-nos of items in the cart
  final List<String> _serialNos = [];

  /// Returns reference to [_productIds]
  List<int> getProductIds() {
    return _productIds;
  }

  /// Returns reference to [_serialNos]
  List<String> getSerialNos() {
    return _serialNos;
  }

  /// Returns no of items in the cart
  int getCartItemCount() {
    return _productIds.length;
  }

  /// Adds a product with input [productId] and [serialNo] to the cart
  void addProduct(int productId, String serialNo) {
    _productIds.add(productId);
    _serialNos.add(serialNo);
    notifyListeners();
  }

  /// Removes all items from the cart
  void removeAll() {
    _productIds.clear();
    _serialNos.clear();
    notifyListeners();
  }

  /// Removes the item at given [index] from the cart
  void removeId(int index) {
    _productIds.removeAt(index);
    _serialNos.removeAt(index);
    notifyListeners();
  }
}
