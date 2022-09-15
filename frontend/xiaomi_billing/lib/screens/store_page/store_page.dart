import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/product_details_page/product_details_page.dart';
import 'package:xiaomi_billing/states/products_model.dart';

import '../../constants.dart';
import '../../states/credential_manager.dart';
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
      child: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: miOrange,
          foregroundColor: Colors.white,
          expandedHeight: size.height * 0.1,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Store'),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        getButtonwithCategory(
                            'Phones', _selectedType, context, setType),
                        getButtonwithCategory(
                            'TV', _selectedType, context, setType),
                        getButtonwithCategory(
                            'Audio', _selectedType, context, setType),
                      ],
                    ),
                  ),
              childCount: 1),
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
                              child: Image.asset('assets/mi.svg.png'),
                              tag: currentProducts[index].productId,
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
    ));
  }
}

Widget getButtonwithCategory(String type, String currentSelected,
    BuildContext context, Function(String) setType) {
  return (ElevatedButton(
    child: Text(type),
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
  ));
}
