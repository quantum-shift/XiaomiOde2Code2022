import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'products_model.g.dart';

@HiveType(typeId: 0)
class Product {
  const Product(
      {required this.productName,
      required this.productId,
      required this.productCategory,
      required this.price,
      required this.productImageUrl,
      required this.productDetails});

  factory Product.fromJson(dynamic json) {
    return Product(
        productName: json['name'] as String,
        productId: json['id'] as int,
        productCategory: json['category'] as String,
        price: json['price'] as int,
        productImageUrl: json['img_url'] as String,
        productDetails: json['details']);
  }

  @HiveField(0)
  final String productName;
  @HiveField(1)
  final int productId;
  @HiveField(2)
  final String productCategory;
  @HiveField(3)
  final int price;
  @HiveField(4)
  final String productImageUrl;
  @HiveField(5)
  final Map<String, dynamic> productDetails;

  @override
  String toString() {
    return "productId: $productId , productCategory: $productCategory , productName: $productName , price: $price , productImageUrl: $productImageUrl , productDetails: $productDetails";
  }
}

class ProductModel extends ChangeNotifier {
  List<Product> _products = [];

  List<Product> getProducts() {
    return _products;
  }

  List<String> getCategories() {
    final List<String> categories = [];
    final Set<String> distinctCategories = {};
    for (final product in _products) {
      if (distinctCategories.contains(product.productCategory) == false) {
        categories.add(product.productCategory);
        distinctCategories.add(product.productCategory);
      }
    }
    return categories;
  }

  void updateProductList(List<Product> newProductList) {
    _products = newProductList;
    notifyListeners();
  }
}
