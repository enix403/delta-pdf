import 'dart:io';
import 'package:deltapdf/core/filesystem.dart';
import 'package:flutter/material.dart';

import 'package:pdfx/pdfx.dart';

class RecentsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () async {
          _openPDF(context);
        },
        child: const Text("Open PDF"),
      ),
    );
  }

  Future<PdfDocument> _loadFile() async {
    await DocumentTree.ensureTreeRoot();
    final filepath = DocumentTree.resolveFromRoot(['lms.pdf']);

    print(filepath);

    final file = File(filepath);
    //print(file.lengthSync());
    final bytes = await file.readAsBytes();
    final doc = await PdfDocument.openData(bytes);
    return doc;
  }

  Future<void> _showPDFView(BuildContext context, PdfDocument doc) async {
    final page = await doc.getPage(1);
    final image = await page.render(
      width: 200,
      height: 600,
      format: PdfPageImageFormat.png,

    );
    await page.close();

    if (image == null)
      return;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => Container(
          color: Colors.red,
          child: Image.memory(image.bytes)
        ),
      ),
    );
  }

  void _openPDF(BuildContext context) async {
    final doc = await _loadFile();
    //print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

    if (context.mounted) {
      await _showPDFView(context, doc);
    }

    await doc.close();
  }
}
