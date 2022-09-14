import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/customer_info_page/customer_info.dart';
import 'package:xiaomi_billing/screens/home_page/components/empty_cart_card.dart';
import 'package:xiaomi_billing/screens/store_page/store_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xiaomi_billing/states/global_data.dart';
import '../../../states/products_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void saveCartToFile(bool mounted, BuildContext context) async {
  if (!mounted) return;
  List<int> productIds = context.read<CartModel>().getProductIds();
  List<String> serialNos = context.read<CartModel>().getSerialNos();
  var box = await Hive.openBox('cart');
  await box.clear();
  box.put('id', productIds);
  box.put('serial', serialNos);
}

Future<bool> isConnected(BuildContext context) async {
  try {
    Dio dio = await context.read<CredentialManager>().getAPIClient();
    await dio.get('/');
    return true;
  } catch (error) {
    return false;
  }
}

void retrieveProductsFromFile(BuildContext context, bool mounted) async {
  var box = await Hive.openBox('products');
  if (box.isEmpty) return;
  List<Product> productsInFile = [];
  for (int i = 0; i < box.length; i++) {
    productsInFile.add(box.getAt(i));
  }
  if (!mounted) return;
  context.read<ProductModel>().updateProductList(productsInFile);
}

Future<void> retrieveProductsFromAPI(BuildContext context, bool mounted) async {
  var dio = await context.read<CredentialManager>().getAPIClient();
  Response<String> response = await dio.get('/products');
  Iterable retrievedData = jsonDecode(response.data.toString());
  List<Product> retrievedProducts = List<Product>.from(
      retrievedData.map((e) => Product.fromJson(e)).toList());
  if (!mounted) return;
  context.read<ProductModel>().updateProductList(retrievedProducts);
}

// First time with no internet connection not handled yet

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Future<void> clearFile() async {
    var box = await Hive.openBox('products');
    await box.clear();
  }

  void writeProductsToFile() async {
    await clearFile();
    var box = await Hive.openBox('products');
    if (!mounted) return;
    for (Product product in context.read<ProductModel>().getProducts()) {
      box.add(product);
    }
  }

  Future<void> readCartFromFile() async {
    var box = await Hive.openBox('cart');
    if (box.isEmpty) return;
    var productIds = box.get('id');
    var serialNos = box.get('serial');
    for (int i = 0; i < productIds.length; i++) {
      context.read<CartModel>().addProduct(productIds[i], serialNos[i]);
    }
  }

  @override
  void initState() {
    super.initState();
    handleMount();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleMount() async {
    if (!context.read<GlobalData>().visitedCart) {
      try {
        await retrieveProductsFromAPI(context, mounted);
      } catch (error) {
        retrieveProductsFromFile(context, mounted);
      }
      writeProductsToFile();
      readCartFromFile();
      if (!mounted) return;
      context.read<GlobalData>().setVisitedCart(true);
    }
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
      onRefresh: () async {
        try {
          bool connected = await isConnected(context);
          if (connected) {
            await retrieveProductsFromAPI(context, mounted);
            showSnackBar(context, "Products updated");
          } else {
            throw Exception();
          }
        } catch (error) {
          showSnackBar(context, "Cannot connect to server");
        }
      },
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
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const CustomerInfo()));
                      },
                      child: Text('Checkout'),
                      style: getButtonStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          cartItems.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.all(size.width * 0.05),
                      child: EmptyCartCard(
                          message:
                              'Your cart is empty. Add new items to cart by visiting the store.',
                          size: size)),
                )
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
                                            saveCartToFile(mounted, context);
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
