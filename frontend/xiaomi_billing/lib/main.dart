import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

String baseUrl = 'http://localhost:8000';

void setBaseUrl() {
  if (Platform.isAndroid) {
    baseUrl = 'http://10.0.2.2:8000';
  }
}

void main() {
  setBaseUrl();
  runApp(ChangeNotifierProvider(
      create: (context) => CredentialManager(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Xiaomi POS',
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          appBar: AppBar(title: const Text('Xiaomi Hackathon!')),
          body: context.watch<CredentialManager>().getToken() == ''
              ? LoginPage()
              : const HomePage(),
        ));
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? formFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fields cannot be empty';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration.collapsed(hintText: 'Username'),
            validator: formFieldValidator,
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration.collapsed(hintText: 'Password'),
            validator: formFieldValidator,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logging in!')));
                  context.read<CredentialManager>().doRegister(
                      _usernameController.text, _passwordController.text);
                }
              },
              child: const Text('Register'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logging in!')));
                  context.read<CredentialManager>().doLogin(
                      _usernameController.text, _passwordController.text);
                }
              },
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: () {
          context.read<CredentialManager>().doLogout();
        },
        child: const Text('Logout'),
      ),
    ));
  }
}

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
    print("WE are here!");
    retrieveToken();
  }

  Future<Dio> getAPIClient() async {
    _dio.interceptors.clear();
    if (_token != '') {
      _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        options.headers["Authorisation"] = "Bearer $_token";
        return handler.next(options);
      }));
    }
    _dio.options.baseUrl = baseUrl;
    return _dio;
  }

  void doRegister(String username, String password) async {
    Dio dio = await getAPIClient();
    var response = await dio
        .post('/users', data: {'email': username, 'password': password});
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
