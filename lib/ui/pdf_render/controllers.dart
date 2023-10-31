import 'package:pdfx/pdfx.dart';

import 'misc.dart';

typedef VoidCallback = void Function();

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
  PdfPageLoadController? _loadedPageCtrl;

  PdfLoadedCallback? _onLoaded;

  bool get isLoaded => _document != null;

  PdfDocument getDocument() => _document!;

  void load(String id) {
    loadDummyDocument().then((document) {
      _onLoaded?.call(document);
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
    _isDisposed = true;

    // Wait for page closing
    if (_loadedPageIndex == -1) {
      _closeDocument();
    }
  }

  PdfPageLoadController loadPage(int index) {
    _loadedPageIndex = index;
    _loadedPageCtrl = new PdfPageLoadController(
      _document!,
      index,
      onClose: () {
        _loadedPageIndex = -1;
        _loadedPageCtrl = null;
        if (_isDisposed) {
          _closeDocument();
        }
      },
    );

    return _loadedPageCtrl!;
  }

  void notifyOnLoaded(PdfLoadedCallback callback) {
    _onLoaded = callback;
  }
}
