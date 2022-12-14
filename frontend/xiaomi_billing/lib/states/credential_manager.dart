import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/states/products_model.dart';
import 'dart:developer' as developer;

import 'order_model.dart';

/// Functions handling login / logout
class CredentialManager extends ChangeNotifier {
  String _token = '';
  final Dio _dio = Dio();

  CredentialManager() {
    retrieveToken();
  }

  /// Retrieves JWT token stored locally
  void retrieveToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token')?.isEmpty ?? true) {
      _token = '';
    } else {
      _token = prefs.getString('token')!;
    }
    notifyListeners();
    developer.log("Updated token to: $_token");
  }

  String getToken() {
    return _token;
  }

  /// Set new value of locally stored token
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('token', token);
    retrieveToken();
  }

  /// Returns a [Dio] client object with JWT token included in the header
  Future<Dio> getAPIClient() async {
    _dio.interceptors.clear();
    if (_token != '') {
      _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        options.headers["Authorization"] = "Bearer $_token";
        return handler.next(options);
      }));
    }
    _dio.options.baseUrl = baseUrl!;
    return _dio;
  }

  /// Registers new user to the backend. Throws [DioError].
  Future<void> doRegister(String username, String password) async {
    Dio dio = await getAPIClient();
    await dio.post('/users', data: {'mi_id': username, 'password': password});
    await doLogin(username, password);
  }

  /// Logs in an exisiting user. Throws [DioError].
  Future<void> doLogin(String username, String password) async {
    Dio dio = await getAPIClient();
    Map<String, dynamic> formMap = <String, dynamic>{};
    formMap['username'] = username;
    formMap['password'] = password;
    FormData formData = FormData.fromMap(formMap);
    var response = await dio.post('/token', data: formData);
    developer.log("Logging in!");
    setToken(response.data['access_token']);
    // dio.get('/token')
  }

  /// Logs out an already logged in user.
  Future<void> doLogout() async {
    developer.log("Logging out!");
    await setToken('');
    notifyListeners();
  }

  /// Syncs orders stored in *offline-orders* device file with the backend
  Future<void> syncAllOrders() async {
    var box = await Hive.openBox(
        'offline-orders'); // orders that have not yet synced with the backend
    var onDeviceBox =
        await Hive.openBox('on-device-orders'); // orders that have been synced
    if (box.isNotEmpty) {
      List<Order> orderList = [];
      for (int i = 0; i < box.length; i++) {
        orderList.add(box.getAt(i));
      }
      List<Product> productList = [];
      var productBox = await Hive.openBox('products');
      if (productBox.isNotEmpty) {
        for (int i = 0; i < productBox.length; i++) {
          productList.add(productBox.getAt(i));
        }
      }
      await box.clear();
      for (Order order in orderList) {
        try {
          Dio dio = await getAPIClient();
          await dio.post("/customer", data: {
            'phone': order.customerPhone,
            'email': order.customerEmail,
            'name': order.customerName
          });
          int total = 0;
          List<Map<String, String>> l = [];
          for (int i = 0; i < order.productIds.length; i++) {
            int id = order.productIds[i];
            String serial = order.serialNos[i];
            for (Product product in productList) {
              if (product.productId == id) {
                Map<String, String> m = {
                  'product_id': id.toString(),
                  'serial': serial
                };
                l.add(m);
                total += product.price;
              }
            }
          }
          await dio.post("/order/offline", data: {
            'amount': total,
            'currency': 'INR',
            'user_id': order.operatorId,
            'phone': order.customerPhone,
            'items': l
          });
          onDeviceBox.add(order);
        } catch (error) {
          box.add(order);
        }
      }
    }
  }
}
