import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/success_page/success_page.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xiaomi_billing/states/global_data.dart';

class RazorpayCheckout extends StatefulWidget {
  const RazorpayCheckout({super.key, required this.amount});
  final int amount;
  @override
  RazorpayCheckoutState createState() => RazorpayCheckoutState();
}

class RazorpayCheckoutState extends State<RazorpayCheckout> {
  late Razorpay _razorpay;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: openCheckout,
        child: const Text('Click here to complete online payment'));
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void openCheckout() async {
    Dio dio = await context.read<CredentialManager>().getAPIClient();
    int amount = widget.amount;
    late final Response response;
    try {
      response = await dio
          .post('/order/new', data: {'amount': amount, 'currency': 'INR'});
    } on DioError catch (e) {
      showSnackBar(context, "Please check your internet connection.");
      return;
    }
    final String receiptId = response.data['receipt_id'],
        orderId = response.data['order_id'];
    final String? API_KEY_ID = dotenv.env['API_KEY_ID'];
    var options = {
      'key': API_KEY_ID,
      'amount': amount,
      'name': 'Xiaomi',
      'order_id': orderId,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': context.read<GlobalData>().customerPhone,
        'email': context.read<GlobalData>().customerEmail
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Success Response: $response');
    if (!mounted) return;
    Dio dio = await context.read<CredentialManager>().getAPIClient();
    await dio.post('/order/success', data: {
      'order_id': response.orderId,
      'payment_id': response.paymentId,
      'signature': response.signature
    });
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SuccessPage()));
    /*Fluttertoast.showToast(
        msg: "SUCCESS: " + response.paymentId!,
        toastLength: Toast.LENGTH_SHORT); */
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Error Response: $response');
    showSnackBar(context, "Payment failed. Something went wrong");
    /* Fluttertoast.showToast(
        msg: "ERROR: " + response.code.toString() + " - " + response.message!,
        toastLength: Toast.LENGTH_SHORT); */
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External SDK Response: $response');
    /* Fluttertoast.showToast(
        msg: "EXTERNAL_WALLET: " + response.walletName!,
        toastLength: Toast.LENGTH_SHORT); */
  }
}
