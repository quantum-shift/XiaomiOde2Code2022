import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xiaomi_billing/screens/home_page/home_page.dart';
import 'package:xiaomi_billing/screens/success_page/components/PDFViewerPage.dart';
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
  double _imageHeight = 400;
  bool _loading = true;

  Future<void> clearCartFile() async {
    var box = await Hive.openBox('cart');
    await box.clear();
  }

  void onMount(List<int> productIds, List<String> serialNos) async {
    var box = await Hive.openBox('on-device-orders');
    // Remove later
    // await box.clear();
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
        Dio dio = await context.read<CredentialManager>().getAPIClient();
        List<Map<String, String>> l = [];
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
      // remove later
      await file.clear();
    }

    await clearCartFile();
    setState(() {
      _loading = false;
    });
    Timer(const Duration(seconds: 0), () {
      setState(() {
        _imageHeight = 550;
      });
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
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false, backgroundColor: miOrange),
            backgroundColor: Colors.white,
            body: ListView(children: [
              Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: _imageHeight,
                          child: Image.asset('assets/success.jpg')),
                      Container(
                        margin: EdgeInsetsDirectional.all(0),
                        child: TextButton(
                          child: Text('Back to Home',
                              style: TextStyle(fontSize: 18.5)),
                          onPressed: () async {
                            if (!_loading) {
                              context.read<CartModel>().removeAll();
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const HomePage()));
                            }
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsetsDirectional.all(10),
                        child: TextButton(
                          child: Text('Generate PDF',
                              style: TextStyle(fontSize: 18.5)),
                          onPressed: () async {
                            if (!_loading) {
                              if (kIsWeb || Platform.isIOS) {
                                File file = await _createPDF();
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        PDFViewerPage(file: file)));
                              } else {
                                await _createNativePDF();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  )),
            ])),
        onWillPop: () async {
          return false;
        });
  }
}

Future<void> _createNativePDF() async {
  await _createPDF();
  String? path;
  path = (await getExternalStorageDirectory())?.path;
  OpenFile.open('$path/Output.pdf');
}

Future<File> _createPDF() async {
  final pdf = pw.Document();

  final iconImage =
      (await rootBundle.load('assets/mi.svg.png')).buffer.asUint8List();

  final tableHeaders = [
    'Description',
    'Quantity',
    'Unit Price',
    'VAT',
    'Total',
  ];

  final tableData = [
    [
      'Coffee',
      '7',
      '\$ 5',
      '1 %',
      '\$ 35',
    ],
    [
      'Blue Berries',
      '5',
      '\$ 10',
      '2 %',
      '\$ 50',
    ],
    [
      'Water',
      '1',
      '\$ 3',
      '1.5 %',
      '\$ 3',
    ],
    [
      'Apple',
      '6',
      '\$ 8',
      '2 %',
      '\$ 48',
    ],
    [
      'Lunch',
      '3',
      '\$ 90',
      '12 %',
      '\$ 270',
    ],
    [
      'Drinks',
      '2',
      '\$ 15',
      '0.5 %',
      '\$ 30',
    ],
    [
      'Lemon',
      '4',
      '\$ 7',
      '0.5 %',
      '\$ 28',
    ],
  ];

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
                    'Customer Name',
                    style: pw.TextStyle(
                      fontSize: 15.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'john@gmail.com',
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
            'Dear John,\nLorem ipsum dolor sit amet consectetur adipisicing elit. Maxime mollitia, molestiae quas vel sint commodi repudiandae consequuntur voluptatum laborum numquam blanditiis harum quisquam eius sed odit fugiat iusto fuga praesentium optio, eaque rerum! Provident similique accusantium nemo autem. Veritatis obcaecati tenetur iure eius earum ut molestias architecto voluptate aliquam nihil, eveniet aliquid culpa officia aut! Impedit sit sunt quaerat, odit, tenetur error',
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
                  flex: 4,
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
                            '\$ 464',
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
                              'Vat 19.5 %',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            '\$ 90.48',
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
                            '\$ 554.48',
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
              'Flutter Approach',
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
                  'Merul Badda, Anandanagor, Dhaka 1212',
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
                  'flutterapproach@gmail.com',
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
