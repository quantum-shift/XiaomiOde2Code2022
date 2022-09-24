import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/success_page/success_page.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xiaomi_billing/states/global_data.dart';

/// Button that handles Razorpay payment on Android and iOS
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

  /// Function called when user presses the button
  /// 1. Creates a new order entry for the backend by calling */order/new*
  /// 2. Interacts with [_razorpay.open] to provide a native widget for completing payment
  void openCheckout() async {
    Dio dio = await context.read<CredentialManager>().getAPIClient();
    int amount = widget.amount;
    late final Response response;
    try {
      response = await dio
          .post('/order/new', data: {'amount': amount, 'currency': 'INR'});
    } on DioError catch (e) {
      if (!mounted) return;
      showSnackBar(context, "Please check your internet connection.");
      return;
    }
    final String orderId = response.data['order_id'];
    if (!mounted) return;
    context.read<GlobalData>().setOrderId(orderId);
    final String? apiKeyId = dotenv.env['API_KEY_ID'];
    var options = {
      'key': apiKeyId,
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
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const SuccessPage(offlineOrder: false)));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Error Response: $response');
    print(response.message);
    showSnackBar(context, "Payment failed. Something went wrong");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External SDK Response: $response');
  }
}
