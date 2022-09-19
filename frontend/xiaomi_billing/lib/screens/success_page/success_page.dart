import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:xiaomi_billing/main.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/screens/product_details_page/product_details_page.dart';
import 'package:xiaomi_billing/screens/success_page/components/pdf_viewer_page.dart';
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
  bool _loading = true;

  Future<void> clearCartFile() async {
    var box = await Hive.openBox('cart');
    await box.clear();
  }

  void onMount(List<int> productIds, List<String> serialNos) async {
    var box = await Hive.openBox('on-device-orders');
    // Remove later
    // await box.clear();
    if (!mounted) return;
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
        if (!mounted) return;
        Dio dio = await context.read<CredentialManager>().getAPIClient();
        List<Map<String, String>> l = [];
        if (!mounted) return;
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
      try {
        if (!mounted) return;
        context.read<CredentialManager>().syncAllOrders();
      } catch (error) {
        ;
      }
    }

    await clearCartFile();
    setState(() {
      _loading = false;
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
    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false, backgroundColor: miOrange),
            backgroundColor: Colors.white,
            body: ListView(children: [
              Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          )])
                      : Column(
                          children: [
                            Container(
                                height: 550,
                                child: Image.asset('assets/success.jpg')),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  margin: const EdgeInsetsDirectional.all(0),
                                  child: TextButton(
                                    child: const Text('Back to Home',
                                        style: TextStyle(fontSize: 16)),
                                    onPressed: () async {
                                      if (!_loading) {
                                        context.read<CartModel>().removeAll();
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const HomePage()));
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsetsDirectional.all(5),
                                  child: TextButton(
                                    child: const Text('Generate Invoice',
                                        style: TextStyle(fontSize: 16)),
                                    onPressed: () async {
                                      if (!_loading) {
                                        if (kIsWeb || Platform.isIOS) {
                                          File file = await _createPDF(context);
                                          if (!mounted) return;
                                          Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PDFViewerPage(
                                                          file: file)));
                                        } else {
                                          await _createNativePDF(context);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        )),
            ])),
        onWillPop: () async {
          return false;
        });
  }
}

Future<void> _createNativePDF(BuildContext context) async {
  await _createPDF(context);
  String? path;
  path = (await getExternalStorageDirectory())?.path;
  OpenFile.open('$path/Output.pdf');
}

Future<File> _createPDF(BuildContext buildContext) async {
  final pdf = pw.Document();

  final iconImage =
      (await rootBundle.load('assets/mi.svg.png')).buffer.asUint8List();

  final tableHeaders = ['Description', 'Serial No', 'Amount'];

  int total = 0;
  final tableData = <List<dynamic>>[];
  for (int i = 0;
      i < buildContext.read<CartModel>().getProductIds().length;
      i++) {
    for (Product product in buildContext.read<ProductModel>().getProducts()) {
      if (product.productId ==
          buildContext.read<CartModel>().getProductIds()[i]) {
        final itemInfo = [];
        itemInfo.add(product.productName);
        itemInfo.add(buildContext.read<CartModel>().getSerialNos()[i]);
        itemInfo.add("INR ${product.price}");
        total += product.price;
        tableData.add(itemInfo);
      }
    }
  }

  pdf.addPage(
    pw.MultiPage(
      build: (context) {
        return [
          pw.Row(
            children: [
              pw.Image(
                pw.MemoryImage(iconImage),
                height: 72,
                width: 72,
              ),
              pw.SizedBox(width: 1 * PdfPageFormat.mm),
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 17.0,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Xiaomi Store',
                    style: const pw.TextStyle(
                      fontSize: 15.0,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "${buildContext.read<GlobalData>().customerName}",
                    style: pw.TextStyle(
                      fontSize: 15.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "${buildContext.read<GlobalData>().customerEmail}",
                  ),
                  pw.Text(
                    DateTime.now().toString(),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Divider(),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Text(
            'Dear ${buildContext.read<GlobalData>().customerName},\n Thank you for your purchase at Xiaomi. Please find the attached receipt.',
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 5 * PdfPageFormat.mm),

          ///
          /// PDF Table Create
          ///
          pw.Table.fromTextArray(
            headers: tableHeaders,
            data: tableData,
            border: null,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30.0,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
          ),
          pw.Divider(),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Row(
              children: [
                pw.Spacer(flex: 6),
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'Net total',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            'INR ${total.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'GST 15 %',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            'INR ${(total * 0.15).toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'Total amount due',
                              style: pw.TextStyle(
                                fontSize: 14.0,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            'INR ${(total * 1.15).toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2 * PdfPageFormat.mm),
                      pw.Container(height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 0.5 * PdfPageFormat.mm),
                      pw.Container(height: 1, color: PdfColors.grey400),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      footer: (context) {
        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Divider(),
            pw.SizedBox(height: 2 * PdfPageFormat.mm),
            pw.Text(
              'Xiaomi',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 1 * PdfPageFormat.mm),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Address: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Bangalore, Karnataka',
                ),
              ],
            ),
            pw.SizedBox(height: 1 * PdfPageFormat.mm),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Email: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'service.in@xiaomi.com',
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  final bytes = await pdf.save();

  File ret = await saveFile(bytes, 'Output.pdf');

  return ret;
}

Future<File> saveFile(List<int> bytes, String fileName) async {
  String? path;

  path = (await ((kIsWeb || Platform.isIOS)
          ? getApplicationDocumentsDirectory()
          : getExternalStorageDirectory()))
      ?.path;

  final file = File('$path/$fileName');
  file.writeAsBytesSync(bytes, flush: true);

  return file;
}
