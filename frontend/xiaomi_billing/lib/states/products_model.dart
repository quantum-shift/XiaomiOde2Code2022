import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'products_model.g.dart';

/// Serializable class representing the info associated with each purchasable product
@HiveType(typeId: 0)
class Product {
  const Product(
      {required this.productName,
      required this.productId,
      required this.productCategory,
      required this.price,
      required this.productImageUrl,
      required this.productDetails});

  /// Retreives a [Product] object from the json response obtained from backend API
  factory Product.fromJson(dynamic json) {
    return Product(
        productName: json['name'] as String,
        productId: json['id'] as int,
        productCategory: json['category'] as String,
        price: json['price'] as int,
        productImageUrl: json['img_url'] as String,
        productDetails: json['details']);
  }

  /// Name of the product
  @HiveField(0)
  final String productName;

  /// Unique id associated with each product
  @HiveField(1)
  final int productId;

  /// Category of the product
  @HiveField(2)
  final String productCategory;

  /// Price of the product
  @HiveField(3)
  final int price;

  /// Image url of the display image of the product
  @HiveField(4)
  final String productImageUrl;

  /// Map representing additional information associated with the product. Eg: {'color' : 'red'}
  @HiveField(5)
  final Map<String, dynamic> productDetails;

  @override
  String toString() {
    return "productId: $productId , productCategory: $productCategory , productName: $productName , price: $price , productImageUrl: $productImageUrl , productDetails: $productDetails";
  }
}

/// Stores all [Product] states in the app
class ProductModel extends ChangeNotifier {
  /// List of procucts purchasable by the customer
  List<Product> _products = [];

  /// Returns reference to [_products]
  List<Product> getProducts() {
    return _products;
  }

  /// Returns all unique categories associated with the purchasable products
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

  /// Updates reference to [_products]
  void updateProductList(List<Product> newProductList) {
    _products = newProductList;
    notifyListeners();
  }
}
