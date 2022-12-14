import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/main.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:xiaomi_billing/states/global_data.dart';
import 'package:xiaomi_billing/states/order_model.dart';
import 'package:intl/intl.dart';
import 'package:xiaomi_billing/states/products_model.dart';
import 'dart:developer' as developer;

import '../../../constants.dart';

/// Page showing all orders in the application
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _loading = true;

  /// list of recent orders
  final List<Order> _orderList = [];

  /// whether the accordion of the order has been expanded or not
  final List<bool> _isOpen = [];

  void onMount() async {
    var box = await Hive.openBox(
        'offline-orders'); // first read orders not yet synced with the backend
    if (!mounted) return;
    String operatorId = context.read<GlobalData>().operatorId;
    if (box.isNotEmpty) {
      for (int i = 0; i < box.length; i++) {
        Order order = box.getAt(i);
        if (order.operatorId == operatorId) {
          developer.log("Offline on-device orders : $order");
          _orderList.add(order);
          _isOpen.add(false);
        }
      }
    }

    try {
      // if internet connection is there retrieve orders from backend
      // query /orders
      if (!mounted) return;
      Dio dio = await context.read<CredentialManager>().getAPIClient();
      Response response = await dio.get('/orders');
      for (Map<String, dynamic> m in response.data) {
        developer.log("Backend saved orders : $m");
        List<int> productIds = [];
        List<String> serialNos = [];
        for (Map<String, dynamic> itemMap in m['items']) {
          productIds.add(int.tryParse(itemMap['product_id'])!);
          serialNos.add(itemMap['serial'].toString());
        }
        _orderList.add(Order(
            orderDate: DateTime.now(), // change later
            customerName: m['customer']['name'].toString(),
            customerEmail: m['customer']['email'].toString(),
            customerPhone: m['customer']['phone'].toString(),
            productIds: productIds,
            serialNos: serialNos,
            operatorId: m['user_id'].toString()));
        _isOpen.add(false);
      }
    } catch (error) {
      // without internet connection read order info from device file
      // read from on-device-orders
      var box = await Hive.openBox('on-device-orders');
      if (box.isNotEmpty) {
        for (int i = 0; i < box.length; i++) {
          Order order = box.getAt(i);
          developer.log("Online on-device orders : $order");
          if (order.operatorId == operatorId) {
            _orderList.add(order);
            _isOpen.add(false);
          }
        }
      }
    }

    _orderList.sort((a, b) => a.orderDate.compareTo(b.orderDate));

    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    onMount();
  }

  /// Given a list of [productIds] returns the total cost associated (including tax)
  int cartAmount(List<int> productIds) {
    int amount = 0;
    for (int id in productIds) {
      for (Product product in context.read<ProductModel>().getProducts()) {
        if (product.productId == id) {
          amount += product.price;
        }
      }
    }
    return int.tryParse((amount * 1.15).toStringAsFixed(0))!;
  }

  /// Returns the corresponding [Product] given the [productId]
  Product getProductFromId(int productId) {
    for (Product product in context.read<ProductModel>().getProducts()) {
      if (product.productId == productId) {
        return product;
      }
    }
    return dummyProduct;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverAppBar(
        automaticallyImplyLeading: false,
        pinned: true,
        backgroundColor: miOrange,
        foregroundColor: Colors.white,
        expandedHeight: size.height * 0.1,
        flexibleSpace: const FlexibleSpaceBar(
          title: Text('Orders'),
        ),
      ),
      SliverToBoxAdapter(
        child: _loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.all(40),
                      child: const CircularProgressIndicator.adaptive()),
                ],
              )
            : Container(
                padding: EdgeInsets.symmetric(
                    vertical: 20, horizontal: size.width * 0.025),
                child: ExpansionPanelList(
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isOpen[panelIndex] = !isExpanded;
                    });
                  },
                  children: _orderList
                      .asMap()
                      .entries
                      .map((orderItem) => ExpansionPanel(
                          canTapOnHeader: true,
                          headerBuilder: (context, isExpanded) => SizedBox(
                                width: size.width * 0.8,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 10, 0, 0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.date_range),
                                              Text(
                                                  DateFormat('d MMM kk:mm')
                                                      .format(orderItem
                                                          .value.orderDate),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 10, 0, 0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.currency_rupee),
                                              Text(
                                                  cartAmount(orderItem
                                                          .value.productIds)
                                                      .toString(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.fromLTRB(
                                          size.width * 0.025, 10, 0, 10),
                                      width: size.width * 0.45,
                                      child: Column(
                                        children: [
                                          Text(orderItem.value.customerName,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 15)),
                                          Text(orderItem.value.customerPhone,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 127, 127, 127),
                                                  fontSize: 13)),
                                          Text(orderItem.value.customerEmail,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 127, 127, 127),
                                                  fontSize: 13))
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                          body: Column(children: [
                            const Divider(thickness: 2),
                            SizedBox(
                              width: size.width * 0.95,
                              child: DataTable(
                                sortColumnIndex: 2,
                                sortAscending: true,
                                showBottomBorder: true,
                                columns: const [
                                  DataColumn(
                                      label: Text('Purchase'),
                                      tooltip: 'Purchase'),
                                  DataColumn(
                                      label: Text('Serial'), tooltip: 'Serial'),
                                  DataColumn(
                                      label: Text('Price'),
                                      tooltip: 'Price(\u{20B9})',
                                      numeric: true),
                                ],
                                rows: orderItem.value.productIds
                                    .asMap()
                                    .entries
                                    .map((productId) => DataRow(
                                            color: MaterialStateProperty
                                                .resolveWith<Color?>(
                                                    (Set<MaterialState>
                                                        states) {
                                              if (productId.key.isEven) {
                                                return Colors.grey
                                                    .withOpacity(0.3);
                                              }
                                              return null;
                                            }),
                                            cells: [
                                              DataCell(Text(
                                                getProductFromId(
                                                        productId.value)
                                                    .productName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                              DataCell(Text(orderItem.value
                                                  .serialNos[productId.key])),
                                              DataCell(Text(
                                                  "${getProductFromId(productId.value).price}"))
                                            ]))
                                    .toList(),
                              ),
                            )
                          ]),
                          isExpanded: _isOpen[orderItem.key]))
                      .toList(),
                ),
              ),
      )
    ]));
  }
}
