import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../states/global_data.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Button that handles Razorpay payment on Windows
class WindowsCheckoutPage extends StatefulWidget {
  late final String name, phone;
  late final int amount;
  late final bool pressed;

  /// Function to be invoked in the calling widget when the payment webpage gets visited
  late final Function() parentAction;

  /// Function to be invoked when the order-id of the new order is received
  late final Function(String) parentOrderAction;

  WindowsCheckoutPage(
      {super.key,
      required this.name,
      required this.phone,
      required this.amount,
      required this.pressed,
      required this.parentAction,
      required this.parentOrderAction});

  @override
  WindowsCheckoutPageState createState() => WindowsCheckoutPageState();
}

class WindowsCheckoutPageState extends State<WindowsCheckoutPage> {
  WindowsCheckoutPageState();

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPayClick,
        child: Text('Click here to complete online payment',
            style: TextStyle(color: widget.pressed ? Colors.grey : miOrange)));
  }

  /// Function called when user presses the button
  /// 1. Creates a new order entry for the backend by calling */order/new*
  /// 2. Recieves a token to complete the payment by calling */order/token*
  /// 3. Navigates to a webpage at */order/windows/{token}* to complete the payment
  void onPayClick() async {
    if (!widget.pressed) {
      Dio dio = await context.read<CredentialManager>().getAPIClient();
      late final Response response;
      try {
        response = await dio.post('/order/new',
            data: {'amount': widget.amount, 'currency': 'INR'});
        final String orderId = response.data['order_id'];
        if (!mounted) return;
        context.read<GlobalData>().setOrderId(orderId);
        widget.parentOrderAction(orderId);
        final token = await dio.post('/order/token', data: {
          'order_id': orderId,
          'amount': widget.amount,
          'name': widget.name,
          'phone': widget.phone
        });
        launchUrl(Uri.parse('$baseUrl/order/windows/$token'));
        widget.parentAction();
      } on DioError catch (e) {
        if (!mounted) return;
        showSnackBar(context, "Payment failed. Something went wrong");
        return;
      }
    } else {
      return;
    }
  }
}
