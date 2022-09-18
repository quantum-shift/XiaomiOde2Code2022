import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:xiaomi_billing/constants.dart';

class PDFViewerPage extends StatefulWidget {
  const PDFViewerPage({super.key, required this.file});

  final File file;

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: miOrange,
        title: const Text('Invoice'),
        foregroundColor: Colors.white,
      ),
      body: PDFView(
        filePath: widget.file.path,
      ),
    );
  }
}
