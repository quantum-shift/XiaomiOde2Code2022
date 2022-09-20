import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/checkout_page/checkout_page.dart';
import 'package:xiaomi_billing/screens/customer_info_page/customer_info.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/screens/login_page/login_page.dart';
import 'package:xiaomi_billing/screens/product_details_page/product_details_page.dart';
import 'package:xiaomi_billing/screens/store_page/store_page.dart';
import 'package:xiaomi_billing/screens/success_page/success_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:xiaomi_billing/states/global_data.dart';
import 'package:xiaomi_billing/states/order_model.dart';
import 'package:xiaomi_billing/states/products_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

const Product dummyProduct = Product(
    productName: 'a',
    productId: 1,
    productCategory: 'a',
    price: 1,
    productImageUrl: 'a',
    productDetails: <String, dynamic>{});

void main() async {
  // setBaseUrl();
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(OrderAdapter());
  await dotenv.load(fileName: ".env");
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => CredentialManager()),
    ChangeNotifierProvider(create: (context) => CartModel()),
    ChangeNotifierProvider(create: (context) => ProductModel()),
    ChangeNotifierProvider(create: (context) => GlobalData()),
  ], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await context.read<CredentialManager>().syncAllOrders();
    });
  }

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
      home: context.watch<CredentialManager>().getToken() == ''
          ? LoginPage()
          : const HomePage(),
      // home: context.watch<CredentialManager>().getToken() == ''
      //     ? LoginPage()
      //     : WindowsCheckoutPage(
      //         name: "Arka", phone: "+911111122222", amount: 50000),
      routes: <String, WidgetBuilder>{
        'Home': (context) => const HomePage(),
        'Store': (context) => const StorePage(),
        'ProductDetails': (context) => ProductDetails(
              product: dummyProduct,
              serialNo: '',
            ),
        'CustomerInfo': (context) => const CustomerInfo(),
        'Checkout': (context) => const CheckoutPage(),
        'Success': (context) => const SuccessPage(offlineOrder: true),
      },
      // builder: (context, child) {
      //   return Stack(
      //     children: [
      //       child!,
      //       Positioned(
      //           bottom: kBottomNavigationBarHeight, right: 5, child: Cart())
      //     ],
      //   );
      // },
    );
  }
}
