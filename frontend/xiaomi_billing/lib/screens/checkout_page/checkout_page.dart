import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/checkout_page/components/razorpay_checkout.dart';
import 'package:xiaomi_billing/screens/checkout_page/components/windows_checkout_page.dart';
import 'package:xiaomi_billing/screens/success_page/success_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/global_data.dart';

import '../../constants.dart';
import '../../states/products_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutState();
}

class _CheckoutState extends State<CheckoutPage> {
  int _index = 0;
  int amount = 0;
  List<String> paymentOptions = ['Offline', 'Razorpay'];
  late String? chosenPaymentOption;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController paymentController;

  @override
  void initState() {
    super.initState();
    for (int id in context.read<CartModel>().getProductIds()) {
      for (Product product in context.read<ProductModel>().getProducts()) {
        if (id == product.productId) {
          amount += product.price;
        }
      }
    }
    chosenPaymentOption = paymentOptions[0];
    paymentController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = 0;
    for (int id in context.watch<CartModel>().getProductIds()) {
      for (Product product in context.watch<ProductModel>().getProducts()) {
        if (product.productId == id) {
          totalPrice += product.price;
        }
      }
    }
    totalPrice = totalPrice * 115;  // to convert to paise
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: miOrange,
        foregroundColor: Colors.white,
        expandedHeight: size.height * 0.1,
        flexibleSpace: const FlexibleSpaceBar(
          title: Text('Checkout'),
        ),
      ),
      SliverToBoxAdapter(
          child: Stepper(
        currentStep: _index,
        onStepCancel: () {
          if (_index > 0) {
            setState(() {
              _index -= 1;
            });
          }
        },
        onStepContinue: () async {
          if (_index <= 1) {
            setState(() {
              _index += 1;
            });
          } else if (_index == 2 && chosenPaymentOption == paymentOptions[0]) {
            if (_formKey.currentState!.validate()) {
              return showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text("Payment Confirmation"),
                  content: const Text(
                      "Are you sure you want to complete the transaction ?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const SuccessPage()));
                        },
                        child: Text('Yes')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, 'No'),
                        child: const Text('No'))
                  ],
                ),
              );
            }
          }
        },
        onStepTapped: (int index) {
          setState(() {
            _index = index;
          });
        },
        steps: [
          Step(
              title: const Text('Payable Amount'),
              content: Container(
                  width: size.width,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 100,
                                child: Text("Amount :",
                                    style: TextStyle(fontSize: 16))),
                            Container(
                              width: 100,
                              child: Text(
                                  "\u{20B9}${(amount * 1.0).toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                                width: 100,
                                child: Text("Tax :",
                                    style: TextStyle(fontSize: 16))),
                            Container(
                              width: 100,
                              child: Text(
                                  "\u{20B9}${(amount * 0.15).toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                                width: 100,
                                child: Text("Total :",
                                    style: TextStyle(fontSize: 16))),
                            Container(
                              width: 100,
                              child: Text(
                                  "\u{20B9}${(amount * 1.15).toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        )
                      ]))),
          Step(
              title: const Text('Payment Method'),
              content: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(paymentOptions[0]),
                    leading: Radio<String>(
                      activeColor: miOrange,
                      value: paymentOptions[0],
                      groupValue: chosenPaymentOption,
                      onChanged: (String? value) {
                        setState(() {
                          chosenPaymentOption = value;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(paymentOptions[1]),
                    leading: Radio<String>(
                      activeColor: miOrange,
                      value: paymentOptions[1],
                      groupValue: chosenPaymentOption,
                      onChanged: (String? value) {
                        setState(() {
                          chosenPaymentOption = value;
                        });
                      },
                    ),
                  ),
                ],
              )),
          Step(
              title: const Text('Payment Completion'),
              content: chosenPaymentOption == paymentOptions[0]
                  ? Container(
                      padding: EdgeInsets.all(8.0),
                      child: Form(
                        key: _formKey,
                        child: TextFormField(
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                              ),
                              suffixIcon: Icon(Icons.currency_rupee),
                              labelText: "Amount Payed"),
                          controller: paymentController,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "Field cannot be empty";
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                        ),
                      ))
                  : Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      (kIsWeb || Platform.isWindows ||
                              Platform.isMacOS ||
                              Platform.isLinux)
                          ? WindowsCheckoutPage(
                              name: context.read<GlobalData>().customerName,
                              phone: context.read<GlobalData>().customerPhone,
                              amount: totalPrice)
                          : RazorpayCheckout(amount: totalPrice)
                    ])),
        ],
      )),
    ]));
  }
}
