import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/home_page/components/cart_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/products_model.dart';

import '../../constants.dart';

class ProductDetails extends StatefulWidget {
  ProductDetails({super.key, required this.product, required this.serialNo});

  Product product;
  String serialNo;

  @override
  State<ProductDetails> createState() =>
      _ProductDetailsState(product: product, serialNo: serialNo);
}

class _ProductDetailsState extends State<ProductDetails> {
  _ProductDetailsState({required this.product, required this.serialNo});
  Product product;
  String serialNo;

  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late List<TextEditingController> _detailControllers = [];
  late List<Widget> greyFields = [];
  late TextEditingController _serialNoController;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _categoryController.text = product.productCategory;
    greyFields.add(getFixedTextField(_categoryController, 'Category'));
    _priceController = TextEditingController();
    _priceController.text = "\u{20B9} ${product.price}";
    greyFields.add(getFixedTextField(_priceController, 'Price'));
    product.productDetails.forEach((key, value) {
      _detailControllers.add(TextEditingController());
      _detailControllers[_detailControllers.length - 1].text = value;
      greyFields.add(getFixedTextField(
          _detailControllers[_detailControllers.length - 1],
          key[0].toUpperCase() + key.substring(1, key.length)));
    });
    _serialNoController = TextEditingController();
    _serialNoController.text = serialNo;
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
          flexibleSpace: FlexibleSpaceBar(
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Text(
                product.productName,
                maxLines: 5,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Hero(
              child: Image.asset(
                'assets/mi.svg.png',
                height: 150,
              ),
              tag: product.productId,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Divider(),
        ),
        SliverToBoxAdapter(
          child: Column(
              children: List.from(greyFields)
                ..addAll([
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Serial No',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                      controller: _serialNoController,
                      autofocus: _serialNoController.text.isEmpty,
                    ),
                  )
                ])),
        )
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            if (_selected) {
              List<int> productList = context.read<CartModel>().getProductIds();
              context.read<CartModel>().removeId(productList.length - 1);
              saveCartToFile(mounted, context);
            } else {
              context
                  .read<CartModel>()
                  .addProduct(product.productId, _serialNoController.text);
              saveCartToFile(mounted, context);
            }
            _selected = !_selected;
          });
        },
        label: _selected
            ? const Text('Remove From Cart')
            : const Text('Add to Cart'),
        icon: _selected ? Icon(Icons.remove) : Icon(Icons.add),
      ),
    );
  }
}

Widget getFixedTextField(TextEditingController controller, String heading) {
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: (TextField(
      decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          labelText: heading),
      enabled: false,
      controller: controller,
      style: TextStyle(color: Colors.grey),
    )),
  );
}
