import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:flutter/material.dart';

import 'package:deltapdf/core/filesystem.dart';

class LabelledSpinner extends StatelessWidget {
  final String label;

  const LabelledSpinner(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(child: CircularProgressIndicator()),
          SizedBox(
            height: 16,
          ),
          Text(label),
        ],
      ),
    );
  }
}

Future<PdfDocument> loadDummyDocument() async {
  await DocumentTree.ensureTreeRoot();
  final filepath = DocumentTree.resolveFromRoot(['calc-small.pdf']);
  final file = File(filepath);

  final bytes = await file.readAsBytes();
  final doc = await PdfDocument.openData(bytes);

  //await Future.delayed(const Duration(seconds: 4));

  return doc;
}
