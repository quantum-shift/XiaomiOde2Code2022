import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/customer_info_page/components/customer_info_form.dart';
import 'package:xiaomi_billing/screens/home_page/components/empty_cart_card.dart';
import 'package:xiaomi_billing/screens/product_details_page/product_details_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';

import '../../constants.dart';
import '../../states/global_data.dart';

class CustomerInfo extends StatefulWidget {
  const CustomerInfo({super.key});

  @override
  State<CustomerInfo> createState() => _CustomerInfoState();
}

class _CustomerInfoState extends State<CustomerInfo> {
  late TextEditingController _operatorIdController;
  late TextEditingController _storeTypeController;

  void onMount() async {
    _operatorIdController.text = await readDataFromFile<String>('operatorId');
  }

  @override
  void initState() {
    super.initState();
    _operatorIdController = TextEditingController();
    _operatorIdController.text = context.read<GlobalData>().operatorId;
    if (_operatorIdController.text.isEmpty) {
      onMount();
    }
    _storeTypeController = TextEditingController();
    _storeTypeController.text = context.read<GlobalData>().storeType;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: miOrange,
        foregroundColor: Colors.white,
        expandedHeight: size.height * 0.1,
        flexibleSpace: const FlexibleSpaceBar(
          title: Text('Customer Info'),
        ),
      ),
      context.watch<CartModel>().getProductIds().isEmpty
          ? SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: EmptyCartCard(
                  message:
                      'Your cart cannot be empty during checkout. Please add items to cart.',
                  size: size,
                ),
              ),
            )
          : SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: size.width * 0.45,
                          height: 100,
                          child: Center(
                              child: getFixedTextField(
                                  _operatorIdController, 'Operator ID')),
                        ),
                        Container(
                          width: size.width * 0.45,
                          height: 100,
                          child: Center(
                              child: getFixedTextField(
                                  _storeTypeController, 'Store Type')),
                        )
                      ],
                    ),
                    Divider(thickness: 3),
                  ],
                ),
              ),
            ),
      context.watch<CartModel>().getProductIds().isEmpty
          ? SliverToBoxAdapter(child: Container())
          : SliverToBoxAdapter(
              child: CustomerInfoForm(),
            )
    ]));
  }
}
