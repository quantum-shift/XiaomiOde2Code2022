import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaomi_billing/constants.dart';

class CredentialManager extends ChangeNotifier {
  String _token = '';
  final Dio _dio = Dio();

  CredentialManager() {
    retrieveToken();
  }

  void retrieveToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token')?.isEmpty ?? true) {
      _token = '';
    } else {
      _token = prefs.getString('token')!;
    }
    notifyListeners();
    print("Updated token to: $_token");
  }

  String getToken() {
    return _token;
  }

  void setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('token', token);
    retrieveToken();
  }

  Future<Dio> getAPIClient() async {
    _dio.interceptors.clear();
    if (_token != '') {
      _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        options.headers["Authorization"] = "Bearer $_token";
        return handler.next(options);
      }));
    }
    _dio.options.baseUrl = baseUrl;
    return _dio;
  }

  void doRegister(String username, String password) async {
    Dio dio = await getAPIClient();
    var response = await dio
        .post('/users', data: {'mi_id': username, 'password': password});
    print(response.data);
    doLogin(username, password);
  }

  void doLogin(String username, String password) async {
    Dio dio = await getAPIClient();
    Map<String, dynamic> formMap = <String, dynamic>{};
    formMap['username'] = username;
    formMap['password'] = password;
    FormData formData = FormData.fromMap(formMap);
    var response = await dio.post('/token', data: formData);
    print(response.data);
    print("Logging in!");
    setToken(response.data['access_token']);
    // dio.get('/token')
  }

  void doLogout() async {
    print("Logging out!");
    setToken('');
  }
}
