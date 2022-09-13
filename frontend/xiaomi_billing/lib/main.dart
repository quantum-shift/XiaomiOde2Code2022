import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/checkout_page/checkout_page.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/screens/login_page/login_page.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';

void main() async {
  setBaseUrl();
  await dotenv.load(fileName: ".env");
  runApp(ChangeNotifierProvider(
      create: (context) => CredentialManager(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xiaomi POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: miOrange,
          )),
      // home: context.watch<CredentialManager>().getToken() == ''
      //     ? LoginPage()
      //     : const HomePage(),
      home: context.watch<CredentialManager>().getToken() == ''
          ? LoginPage()
          : CheckoutPage(),
      routes: <String, WidgetBuilder>{
        'Cart': (context) => const HomePage(),
        'Hello': (context) => const MyWidget(),
      },
    );
  }
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test'),
      ),
      body: Text('Hello World'),
    );
  }
}
