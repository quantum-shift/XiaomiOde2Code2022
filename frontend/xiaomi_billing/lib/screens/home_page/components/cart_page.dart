import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/constants.dart';
import 'package:xiaomi_billing/screens/customer_info_page/customer_info.dart';
import 'package:xiaomi_billing/screens/home_page/components/cart_icon.dart';
import 'package:xiaomi_billing/screens/home_page/components/empty_cart_card.dart';
import 'package:xiaomi_billing/screens/login_page/login_page.dart';
import 'package:xiaomi_billing/screens/store_page/store_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xiaomi_billing/states/global_data.dart';
import '../../../states/products_model.dart';

/// Saves cart information to *cart* device file
void saveCartToFile(bool mounted, BuildContext context) async {
  if (!mounted) return;
  List<int> productIds = context.read<CartModel>().getProductIds();
  List<String> serialNos = context.read<CartModel>().getSerialNos();
  var box = await Hive.openBox('cart');
  await box.clear();
  box.put('id', productIds);
  box.put('serial', serialNos);
}

/// Determines if there is an internet connection by attempting to connect to the backend
Future<bool> isConnected(BuildContext context) async {
  try {
    Dio dio = await context.read<CredentialManager>().getAPIClient();
    await dio.get('/');
    return true;
  } catch (error) {
    return false;
  }
}

/// Retreives all available products by reading *products* device file
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

/// Retrieves all available products by calling */products* at the backend
Future<void> retrieveProductsFromAPI(BuildContext context, bool mounted) async {
  var dio = await context.read<CredentialManager>().getAPIClient();
  Response<String> response = await dio.get('/products');
  Iterable retrievedData = jsonDecode(response.data.toString());
  List<Product> retrievedProducts = List<Product>.from(
      retrievedData.map((e) => Product.fromJson(e)).toList());
  if (!mounted) return;
  context.read<ProductModel>().updateProductList(retrievedProducts);
}

/// Cart Page in the application
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _loading = true;

  /// Clears the *products* device file
  Future<void> clearFile() async {
    var box = await Hive.openBox('products');
    await box.clear();
  }

  /// Writes product information stored in [ProductModel] to *products* device file
  void writeProductsToFile() async {
    await clearFile();
    var box = await Hive.openBox('products');
    if (!mounted) return;
    for (Product product in context.read<ProductModel>().getProducts()) {
      box.add(product);
    }
  }

  /// Reads cart information from *cart* device file
  Future<void> readCartFromFile() async {
    var box = await Hive.openBox('cart');
    if (box.isEmpty) return;
    var productIds = box.get('id');
    var serialNos = box.get('serial');
    for (int i = 0; i < productIds.length; i++) {
      if (!mounted) return;
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
      // run only once in app life cycle
      try {
        await retrieveProductsFromAPI(context, mounted);
      } catch (error) {
        retrieveProductsFromFile(context, mounted);
      }
      writeProductsToFile();
      await readCartFromFile();
      if (!mounted) return;
      context.read<GlobalData>().setVisitedCart(true);
    }
    setState(() {
      _loading = false;
    });
  }

  /// Function invoked when the user refreshes the page by pulling down on mobile or by using the refresh button on Windows
  void handlerefresh() async {
    try {
      bool connected = await isConnected(context);
      if (connected) {
        if (!mounted) return;
        await retrieveProductsFromAPI(context, mounted);
        if (!mounted) return;
        showSnackBar(context, "Products updated");
      } else {
        throw Exception();
      }
    } catch (error) {
      showSnackBar(context, "Cannot connect to server");
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
    return Stack(
      children: [
        Scaffold(
            body: RefreshIndicator(
          onRefresh: () async {
            handlerefresh();
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: miOrange,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  (Platform.isIOS || Platform.isAndroid)
                      ? Container()
                      : IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            semanticLabel: 'Refresh',
                          ),
                          tooltip: 'Refresh',
                          onPressed: () async {
                            handlerefresh();
                          },
                        ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      semanticLabel: 'Logout',
                    ),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await context.read<CredentialManager>().doLogout();
                      if (!mounted) return;
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const LoginPage()));
                    },
                  ),
                ],
                expandedHeight: size.height * 0.1,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text('Cart'),
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
                          style: getButtonStyle(context),
                          child: const Text('Go To Store'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const CustomerInfo()));
                          },
                          style: getButtonStyle(context),
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _loading
                  ? SliverToBoxAdapter(
                      child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator.adaptive(),
                        ],
                      ),
                    ))
                  : cartItems.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.all(size.width * 0.05),
                              child: EmptyCartCard(
                                  message:
                                      'Your cart is empty. Add new items to cart by visiting the store.',
                                  size: size)),
                        )
                      : SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400.0,
                                  mainAxisSpacing: 0.0,
                                  crossAxisSpacing: 0.0,
                                  mainAxisExtent: 250),
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 5.0),
                                  child: Card(
                                    child: InkWell(
                                      splashColor: miOrange,
                                      onTap: () {},
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: Image(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        cartItems[index]
                                                            .productImageUrl)),
                                            title: Text(
                                                cartItems[index].productName,
                                                maxLines: 3,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            subtitle: Text(cartItems[index]
                                                .productCategory),
                                            visualDensity: const VisualDensity(
                                                vertical: 4),
                                          ),
                                          ListTile(
                                            title: Text(
                                                "\u{20B9} ${cartItems[index].price}"),
                                            subtitle: Text(
                                                "Serial: ${context.read<CartModel>().getSerialNos()[index]}"),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    context
                                                        .read<CartModel>()
                                                        .removeId(index);
                                                    saveCartToFile(
                                                        mounted, context);
                                                  },
                                                  style:
                                                      getButtonStyle(context),
                                                  child: const Icon(
                                                    Icons.delete,
                                                    color: Colors.redAccent,
                                                  )),
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
        )),
        const Positioned(bottom: 5, right: 5, child: Cart())
      ],
    );
  }
}
