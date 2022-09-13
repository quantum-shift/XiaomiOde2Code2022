import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/store_page/store_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../states/products_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Future<void> retrieveProductsFromAPI() async {
    var dio = await Provider.of<CredentialManager>(context, listen: false)
        .getAPIClient();
    Response<String> response = await dio.get('/products');
    Iterable retrievedData = jsonDecode(response.data.toString());
    List<Product> retrievedProducts = List<Product>.from(
        retrievedData.map((e) => Product.fromJson(e)).toList());
    if (!mounted) return;
    context.read<ProductModel>().updateProductList(retrievedProducts);
    context.read<CartModel>().removeAll();
  }

  // void retrieveProductsFromFile() async {
  //   var box = await Hive.openBox('cart');
  //   for (int i = 0; i < box.length; i++) {
  //     print(box.getAt(i));
  //   }
  // }

  // void clearFile() async {
  //   var box = await Hive.openBox('cart');
  //   await box.clear();
  // }

  // void writeProductsToFile() async {
  //   var box = await Hive.openBox('cart');
  //   for (Product product in context.read<CartModel>().getProducts()) {
  //     box.add(product);
  //   }
  // }

  @override
  void initState() {
    super.initState();
    retrieveProductsFromAPI();
    // retrieveProductsFromFile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Product> cartItems = [];
    for (int id in context.watch<CartModel>().getProductIds()) {
      for (Product product in context.read<ProductModel>().getProducts()) {
        if (product.productId == id) {
          cartItems.add(product);
        }
      }
    }
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: RefreshIndicator(
      onRefresh: retrieveProductsFromAPI,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: miOrange,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  semanticLabel: 'Logout',
                ),
                tooltip: 'Logout',
                onPressed: () {
                  context.read<CredentialManager>().doLogout();
                },
              ),
            ],
            expandedHeight: size.height * 0.1,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Cart'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: SizedBox(
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const StorePage()));
                      },
                      child: Text('Go To Store'),
                      style: getButtonStyle(context),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Checkout'),
                      style: getButtonStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          cartItems.isEmpty
              ? SliverToBoxAdapter(child: SizedBox())
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400.0,
                    mainAxisSpacing: 0.0,
                    crossAxisSpacing: 0.0,
                    childAspectRatio: 1.60,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 5.0),
                          child: Card(
                            child: InkWell(
                              splashColor: miOrange,
                              onTap: () {},
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Image.asset('assets/mi.svg.png'),
                                    title: Text(cartItems[index].productName),
                                    subtitle:
                                        Text(cartItems[index].productCategory),
                                    visualDensity: VisualDensity(vertical: 4),
                                  ),
                                  ListTile(
                                    title: Text(
                                        "\u{20B9} ${cartItems[index].price}"),
                                    subtitle: Text(
                                        "Serial: ${context.read<CartModel>().getSerialNos()[index]}"),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                          onPressed: () {
                                            context
                                                .read<CartModel>()
                                                .removeId(index);
                                          },
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          style: getButtonStyle(context)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ));
                    },
                    childCount: cartItems.length,
                  ),
                ),
        ],
      ),
    ));
  }
}
