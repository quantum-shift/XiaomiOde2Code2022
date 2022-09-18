import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:xiaomi_billing/states/global_data.dart';
import 'package:xiaomi_billing/states/order_model.dart';
import 'package:xiaomi_billing/states/products_model.dart';

import '../../constants.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key, required this.offlineOrder});
  final bool offlineOrder;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  double _imageHeight = 400;
  bool _loading = true;

  Future<void> clearCartFile() async {
    var box = await Hive.openBox('cart');
    await box.clear();
  }

  void onMount(List<int> productIds, List<String> serialNos) async {
    var box = await Hive.openBox('on-device-orders');
    // Remove later
    // await box.clear();
    Order order = Order(
        orderDate: DateTime.now(),
        customerName: context.read<GlobalData>().customerName,
        customerEmail: context.read<GlobalData>().customerEmail,
        customerPhone: context.read<GlobalData>().customerPhone,
        productIds: productIds,
        serialNos: serialNos,
        operatorId: await readDataFromFile<String>('operatorId'));
    box.add(order);

    if (!widget.offlineOrder) {
      try {
        Dio dio = await context.read<CredentialManager>().getAPIClient();
        List<Map<String, String>> l = [];
        for (int i = 0;
            i < context.read<CartModel>().getProductIds().length;
            i++) {
          Map<String, String> m = {
            'product_id':
                context.read<CartModel>().getProductIds()[i].toString(),
            'serial': context.read<CartModel>().getSerialNos()[i]
          };
          l.add(m);
        }
        await dio.post("/order/${context.read<GlobalData>().orderId}/complete",
            data: {'items': l});
      } catch (error) {
        ;
      }
    } else {
      var file = await Hive.openBox('offline-orders');
      file.add(order);
      // remove later
      await file.clear();
    }

    await clearCartFile();
    setState(() {
      _loading = false;
    });
    Timer(const Duration(seconds: 0), () {
      setState(() {
        _imageHeight = 550;
      });
    });
  }

  @override
  void initState() {
    List<int> productIds = (context.read<CartModel>().getProductIds());
    List<String> serialNos = (context.read<CartModel>().getSerialNos());
    super.initState();
    onMount(List<int>.from(productIds), List<String>.from(serialNos));
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false, backgroundColor: miOrange),
            backgroundColor: Colors.white,
            body: ListView(children: [
              Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: _imageHeight,
                          child: Image.asset('assets/success.jpg')),
                      Container(
                        margin: EdgeInsetsDirectional.all(0),
                        child: TextButton(
                          child: Text('Back to Home',
                              style: TextStyle(fontSize: 18.5)),
                          onPressed: () async {
                            if (!_loading) {
                              context.read<CartModel>().removeAll();
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const HomePage()));
                            }
                          },
                        ),
                      )
                    ],
                  )),
            ])),
        onWillPop: () async {
          return false;
        });
  }
}
