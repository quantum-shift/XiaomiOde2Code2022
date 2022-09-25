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
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/screens/success_page/components/pdf_viewer_page.dart';
import 'package:xiaomi_billing/states/cart_model.dart';
import 'package:xiaomi_billing/states/credential_manager.dart';
import 'package:xiaomi_billing/states/global_data.dart';
import 'package:xiaomi_billing/states/order_model.dart';
import 'package:xiaomi_billing/states/products_model.dart';
import 'dart:developer' as developer;

import '../../constants.dart';

/// Screen confirming a successful purchase
class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key, required this.offlineOrder});
  final bool offlineOrder;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  bool _loading = true;

  /// whether the receipt PDF is currently being generated
  bool _generating = false;

  /// Clears cart information from *cart* device file
  Future<void> clearCartFile() async {
    var box = await Hive.openBox('cart');
    await box.clear();
  }

  void onMount(List<int> productIds, List<String> serialNos) async {
    var box = await Hive.openBox('on-device-orders'); // stores order backups
    if (!mounted) return;
    Order order = Order(
        orderDate: DateTime.now(),
        customerName: context.read<GlobalData>().customerName,
        customerEmail: context.read<GlobalData>().customerEmail,
        customerPhone: context.read<GlobalData>().customerPhone,
        productIds: productIds,
        serialNos: serialNos,
        operatorId: await readDataFromFile<String>('operatorId'));

    if (!widget.offlineOrder) {
      box.add(order);
    }

    if (!widget.offlineOrder) {
      // sync online order with backend
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
            data: {'user_id': order.operatorId, 'items': l});
        developer.log(
            "Online Order Complete. User-id : ${order.operatorId} , items : $l");
      } catch (error) {
        developer.log("Online order sync failed : $error", level: 5);
      }
    } else {
      // for offline order add order information to file
      var file = await Hive.openBox('offline-orders');
      file.add(order);
      try {
        // then try to sync the info with the backend
        if (!mounted) return;
        context.read<CredentialManager>().syncAllOrders();
      } catch (error) {
        developer.log("Syncing offline orders later. Failed backend query.");
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
                          children: const [
                              Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              )
                            ])
                      : Column(
                          children: [
                            SizedBox(
                                height: 550,
                                child: Image.asset(
                                    'assets/success.jpg')), // Designed by stories / Freepik
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
                            ),
                            _generating
                                ? Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        CircularProgressIndicator.adaptive(),
                                      ],
                                    ),
                                  )
                                : Container()
                          ],
                        )),
            ])),
        onWillPop: () async {
          return false;
        });
  }

  /// Creates receipt PDF and opens the file in Android and Windows
  Future<void> _createNativePDF(BuildContext context) async {
    await _createPDF(context);
    String? path;
    path = (await (Platform.isWindows
            ? getApplicationDocumentsDirectory()
            : getExternalStorageDirectory()))
        ?.path;
    OpenFile.open('$path/Output.pdf');
  }

  /// Creates the PDF receipt and stores it in a local device file
  Future<File> _createPDF(BuildContext buildContext) async {
    setState(() {
      _generating = true;
    });
    final pdf = pw.Document();

    final iconImage =
        (await rootBundle.load('assets/mi.svg.png')).buffer.asUint8List();

    final tableHeaders = ['Description', 'Serial No', 'Amount'];

    int total = 0;
    final tableData = <List<dynamic>>[];
    if (!mounted) return File("Output.pdf");
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
                      buildContext.read<GlobalData>().customerName,
                      style: pw.TextStyle(
                        fontSize: 15.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      buildContext.read<GlobalData>().customerEmail,
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
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
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

    setState(() {
      _generating = false;
    });

    return ret;
  }

  /// Save file to local storage with given [fileName] and given file information([bytes])
  Future<File> saveFile(List<int> bytes, String fileName) async {
    String? path;

    path = (await ((kIsWeb || Platform.isIOS || Platform.isWindows)
            ? getApplicationDocumentsDirectory()
            : getExternalStorageDirectory()))
        ?.path;

    final file = File('$path/$fileName');
    file.writeAsBytesSync(bytes, flush: true);

    return file;
  }
}
