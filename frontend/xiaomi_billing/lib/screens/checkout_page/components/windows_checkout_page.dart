import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:url_launcher/url_launcher.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WindowsCheckoutPage extends StatefulWidget {
  late final String name, phone;
  late final int amount;

  WindowsCheckoutPage(
      {super.key,
      required this.name,
      required this.phone,
      required this.amount});

  @override
  WindowsCheckoutPageState createState() => WindowsCheckoutPageState();
}

class WindowsCheckoutPageState extends State<WindowsCheckoutPage> {
  WindowsCheckoutPageState();

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPayClick, child: const Text('Click here to complete online payment'));
  }

  void onPayClick() async {
    Dio dio = await context.read<CredentialManager>().getAPIClient();
    late final Response response;
    try {
      response = await dio.post('/order/new',
          data: {'amount': widget.amount, 'currency': 'INR'});
      final String orderId = response.data['order_id'];
      final token = await dio.post('/order/token', data: {
        'order_id': orderId,
        'amount': widget.amount,
        'name': widget.name,
        'phone': widget.phone
      });
      launchUrl(Uri.parse('$baseUrl/order/windows/$token'));
    } on DioError catch (e) {
      print("HANDLING LOL!");
      print(e);
      if (!mounted) return;
      context.read<CredentialManager>().doLogout();
      return;
    }
  }
}
