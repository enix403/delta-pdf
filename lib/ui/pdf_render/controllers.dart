import 'dart:io';
import 'package:deltapdf/core/filesystem.dart';
import 'package:pdfx/pdfx.dart';

typedef VoidCallback = void Function();

Future<PdfDocument> _loadDummyDocument() async {
  await DocumentTree.ensureTreeRoot();
  final filepath = DocumentTree.resolveFromRoot(['calc-small.pdf']);
  final file = File(filepath);

  final bytes = await file.readAsBytes();
  final doc = await PdfDocument.openData(bytes);

  //await Future.delayed(const Duration(seconds: 4));

  return doc;
}

/* ================================================== */

class PdfPageLoadController {
  final VoidCallback onClose;
  final PdfDocument document;
  final int index;

  PdfPage? page;

  PdfPageLoadController(this.document, this.index, {required this.onClose});

  Future<PdfPage> getOrInit() async {
    page ??= await document.getPage(index);
    return page!;
  }

  Future<void> close() async {
    await page?.close();
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
    _loadDummyDocument().then((document) {
      _onLoaded?.call(document);
      if (_isDisposed) {
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        print("dispose v1");
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        document.close();
        return;
      }

      _document = document;
    });
  }

  void _closeDocument() {
    if (_document == null) return;

    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    print("dispose v2");
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");

    _document!.close();
    _document = null;
  }

  void dispose() {
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    print("dispose v3");
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    _isDisposed = true;

    // Wait for page closing
    if (_loadedPageIndex == -1) {
      _closeDocument();
    }
  }

  PdfPageLoadController loadPage(int index) {
    _loadedPageIndex = index;
    return new PdfPageLoadController(
      _document!,
      index,
      onClose: () {
        _loadedPageIndex = -1;
        if (_isDisposed) {
          print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
          print("dispose v4");
          print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
          _closeDocument();
        }
      },
    );
  }

  void notifyOnLoaded(PdfLoadedCallback callback) {
    _onLoaded = callback;
  }
}
