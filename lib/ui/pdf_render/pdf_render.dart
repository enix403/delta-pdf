import 'dart:io';
import 'package:deltapdf/core/filesystem.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

Future<PdfDocument> _loadDummyDocument() async {
  await DocumentTree.ensureTreeRoot();
  final filepath = DocumentTree.resolveFromRoot(['lms.pdf']);
  final file = File(filepath);

  final bytes = await file.readAsBytes();
  final doc = await PdfDocument.openData(bytes);

  await Future.delayed(const Duration(seconds: 4));

  return doc;
}

abstract class IPdfPageLoadController {
  Future<void> close();
}

/* ================================================== */

class PdfPageLoadController implements IPdfPageLoadController {
  final VoidCallback onClose;

  PdfPageLoadController({required this.onClose});

  @override
  Future<void> close() async {
    onClose();
  }
}

/* ================================================== */

typedef PdfLoadedCallback = void Function(PdfDocument document);

class PdfLoadController {
  PdfDocument? _document;
  bool _isDisposed = false;
  int _loadedPageIndex = -1;

  PdfLoadedCallback? _onLoaded;

  bool get isLoaded => _document != null;

  PdfDocument getDocument() => _document!;

  void load(String id) {
    print('##########################################################');
    print("load");
    print('##########################################################');
    _loadDummyDocument().then((document) {
      _onLoaded?.call(document);
      print('##########################################################');
      print("load::then");
      print('##########################################################');
      if (_isDisposed) {
        document.close();
        return;
      }

      _document = document;
    });
  }

  void _closeDocument() {
    if (_document == null) return;

    _document!.close();
    _document = null;
  }

  void dispose() {
    print('##########################################################');
    print("dispose");
    print('##########################################################');

    _isDisposed = true;

    // Wait for page closing
    if (_loadedPageIndex == -1) {
      _closeDocument();
    }
  }

  IPdfPageLoadController loadPage(int index) {
    _loadedPageIndex = index;
    return new PdfPageLoadController(onClose: () {
      _loadedPageIndex = -1;
      if (_isDisposed) {
        _closeDocument();
      }
    });
  }

  void notifyOnLoaded(PdfLoadedCallback callback) {
    _onLoaded = callback;
  }
}

/* ========================================================== */
/* ========================================================== */
/* ========================================================== */

class PdfRenderView extends StatefulWidget {
  const PdfRenderView({super.key});

  @override
  State<PdfRenderView> createState() => _PdfRenderViewState();
}

class _PdfRenderViewState extends State<PdfRenderView> {
  final loadCtrl = new PdfLoadController();

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    loadCtrl
      ..load("1601")
      ..notifyOnLoaded((_) {
        setState(() {
          _loaded = true;
        });
      });
  }

  @override
  void dispose() {
    loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_loaded) {
              return PdfRenderLoadedView(loadCtrl: loadCtrl);
            }

            // Loader
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(child: CircularProgressIndicator()),
                  SizedBox(
                    height: 16,
                  ),
                  const Text("Loading Document"),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/* ============================================ */
/* ============================================ */
/* ============================================ */

class PdfRenderLoadedView extends StatefulWidget {
  final PdfLoadController loadCtrl;

  const PdfRenderLoadedView({
    super.key,
    required this.loadCtrl,
  });

  @override
  State<PdfRenderLoadedView> createState() => _PdfRenderLoadedViewState();
}

class _PdfRenderLoadedViewState extends State<PdfRenderLoadedView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow[200]!,
              offset: Offset(32, 32),
            ),
            BoxShadow(
              color: Colors.amberAccent[200]!,
              offset: Offset(16, 16),
            ),
          ],
        ),
      ),
    );
  }
}
