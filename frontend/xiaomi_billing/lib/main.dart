import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/screens/login_page/login_page.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'constants.dart';

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
