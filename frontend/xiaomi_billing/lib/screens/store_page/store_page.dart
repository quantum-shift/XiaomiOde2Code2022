import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/home_page/components/cart.dart';
import 'package:xiaomi_billing/screens/product_details_page/product_details_page.dart';
import 'package:xiaomi_billing/states/products_model.dart';

import '../../constants.dart';
import '../home_page/components/cart_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String _selectedType = 'Phones';

  void setType(String type) {
    setState(() {
      _selectedType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Product> currentProducts = context
        .watch<ProductModel>()
        .getProducts()
        .where((element) => element.productCategory == _selectedType)
        .toList();
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Scaffold(
            body: RefreshIndicator(
          onRefresh: () async {
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
          },
          child: CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: miOrange,
              foregroundColor: Colors.white,
              expandedHeight: size.height * 0.1,
              flexibleSpace: const FlexibleSpaceBar(
                title: Text('Store'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Container(
                  height: 60.0,
                  child: Scrollbar(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      children: context
                          .watch<ProductModel>()
                          .getCategories()
                          .map((e) => Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: getButtonwithCategory(
                                    e, _selectedType, context, setType),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) => Card(
                          child: InkWell(
                            splashColor: miOrange,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ProductDetails(
                                      product: currentProducts[index],
                                      serialNo: '')));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              child: ListTile(
                                leading: Hero(
                                  tag: currentProducts[index].productId,
                                  child: Image(
                                      image: CachedNetworkImageProvider(
                                          currentProducts[index]
                                              .productImageUrl)),
                                ),
                                title: Text(currentProducts[index].productName),
                                subtitle: Text(
                                    "\u{20B9} ${currentProducts[index].price}"),
                              ),
                            ),
                          ),
                        ),
                    childCount: currentProducts.length))
          ]),
        )),
        const Positioned(bottom: 5, right: 5, child: Cart())
      ],
    );
  }
}

Widget getButtonwithCategory(String type, String currentSelected,
    BuildContext context, Function(String) setType) {
  return (ElevatedButton(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return Theme.of(context).colorScheme.primary.withOpacity(0.5);
          }
          return type == currentSelected
              ? Colors.orange[100]
              : null; // Use the component's default.
        },
      ),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      )),
    ),
    onPressed: () {
      setType(type);
    },
    child: Text(type),
  ));
}
