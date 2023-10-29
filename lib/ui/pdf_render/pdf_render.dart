import 'dart:io';
import 'package:deltapdf/core/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfRenderView extends StatefulWidget {
  //final Future<PdfDocument> documentFut;

  const PdfRenderView({
    super.key,
    //required this.documentFut,
  });

  @override
  PdfRenderViewState createState() => PdfRenderViewState();
}

class PdfRenderViewState extends State<PdfRenderView> {
  Future<PdfDocument>? documentFut = null;
  PdfDocument? document = null;
  bool pdfLoading = true;

  bool pageLoading = true;
  double pageAspectRatio = 0;
  PdfPageImage? image = null;

  @override
  void initState() {
    super.initState();
    documentFut = _loadDocument();

    initAsync() async {
      final doc = await documentFut;
      setState(() {
        document = doc;
        pdfLoading = false;
        pageLoading = true;
      });

      if (doc == null) return;

      // final page = await doc.getPage(1);
      // final image = await page.render(
      //   width: 200,
      //   height: 600,
      //   format: PdfPageImageFormat.png,
      // );
    }

    initAsync();
  }

  @override
  void dispose() {
    if (document != null) {
      if (!document!.isClosed) document!.close();
    } else if (documentFut != null) {
      documentFut!.then((doc) {
        if (!doc.isClosed) doc.close();
      });
    }

    super.dispose();
  }

  Future<PdfDocument> _loadDocument() async {
    await DocumentTree.ensureTreeRoot();
    final filepath = DocumentTree.resolveFromRoot(['lms.pdf']);

    print(filepath);

    final file = File(filepath);
    //print(file.lengthSync());
    final bytes = await file.readAsBytes();
    final doc = await PdfDocument.openData(bytes);
    return doc;
  }

  Widget _buildCore(BuildContext context) {
    if (pdfLoading) return const Center(child: CircularProgressIndicator());

    return Center(
      child: Text(
        "Loaded " + (document?.pagesCount.toString()).toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.lime,
          width: double.infinity,
          height: double.infinity,
          child: _buildCore(context),
        ),
      ),
    );
  }
}

/*
class _PdfRenderViewState extends State<PdfRenderView> {
  late Future<PdfDocument> document;

  PdfPageImage? pageImage = null;
  Size viewSize = Size(0, 0);

  @override
  void initState() {
    super.initState();
    document = _loadDocument();
    _createPageImage();
  }

  @override
  void dispose() {
    document.then((doc) {
      if (!doc.isClosed) doc.close();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget real = LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.shrink();
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.lime,
          width: double.infinity,
          height: double.infinity,
          child: real,
        ),
      ),
    );
  }

  Future<PdfDocument> _loadDocument() async {
    await DocumentTree.ensureTreeRoot();
    final filepath = DocumentTree.resolveFromRoot(['lms.pdf']);

    print(filepath);

    final file = File(filepath);
    //print(file.lengthSync());
    final bytes = await file.readAsBytes();
    final doc = await PdfDocument.openData(bytes);
    return doc;
  }

  Future<void> _createPageImage() async {
    final doc = await document;

    final page = await doc.getPage(1);

    final image = await page.render(
      width: 200,
      height: 600,
      format: PdfPageImageFormat.png,
    );

    setState(() {
      pageImage = image;
    });

    page.close();
  }
}

*/


/*

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


*/
