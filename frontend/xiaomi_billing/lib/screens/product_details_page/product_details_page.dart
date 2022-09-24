import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/screens/home_page/components/cart_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/products_model.dart';

import '../../constants.dart';

/// Details page of associated product
class ProductDetails extends StatefulWidget {
  const ProductDetails(
      {super.key, required this.product, required this.serialNo});

  /// [Product] whose details are to be shown
  final Product product;

  /// Pre-existing serial number
  final String serialNo;

  @override
  State<ProductDetails> createState() =>
      _ProductDetailsState(product: product, serialNo: serialNo);
}

class _ProductDetailsState extends State<ProductDetails> {
  _ProductDetailsState({required this.product, required this.serialNo});

  /// [Product] whose details are to be shown
  Product product;

  /// Pre-existing serial number
  String serialNo;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late List<TextEditingController> _detailControllers = [];
  late List<Widget> greyFields = []; // list of unchangeable fields 
  late TextEditingController _serialNoController;
  bool _selected = false; // if the item is in cart or not

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
          child: Container(
            padding: const EdgeInsets.all(20.0),
            height: 400,
            child: Hero(
              tag: product.productId,
              child: Image(
                  image: CachedNetworkImageProvider(product.productImageUrl)),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Divider(),
        ),
        SliverToBoxAdapter(
          child: Column(
              children: List.from(greyFields)
                ..addAll([
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Serial No',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                          ),
                        ),
                        controller: _serialNoController,
                        autofocus: _serialNoController.text.isEmpty,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "Field cannot be empty";
                          }
                          return null;
                        },
                      ),
                    ),
                  )
                ])),
        )
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            setState(() {
              if (_selected) {
                List<int> productList =
                    context.read<CartModel>().getProductIds();
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
          }
        },
        label: _selected
            ? const Text('Remove From Cart')
            : const Text('Add to Cart'),
        icon: _selected ? const Icon(Icons.remove) : const Icon(Icons.add),
      ),
    );
  }
}

/// Returns a [TextField] widget which is not user-editable with the given [heading]
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
      style: const TextStyle(color: Colors.grey),
    )),
  );
}
