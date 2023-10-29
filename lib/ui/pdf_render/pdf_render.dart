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

  //await Future.delayed(const Duration(seconds: 4));

  return doc;
}

class LoaderWithText extends StatelessWidget {
  final String label;

  const LoaderWithText(this.label, {super.key});

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

/* ================================================== */

class PdfPageLoadController {
  final VoidCallback onClose;
  final PdfDocument document;
  final int index;

  PdfPageLoadController(this.document, this.index, {required this.onClose});

  Future<PdfPageImage?> getImage() async {
    final page = await document.getPage(index);
    final image = await page.render(
        width: 200, height: 200, format: PdfPageImageFormat.png);
    await page.close();

    return image;
  }

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
    //print('##########################################################');
    //print("load");
    //print('##########################################################');
    _loadDummyDocument().then((document) {
      _onLoaded?.call(document);
      //print('##########################################################');
      //print("load::then");
      //print('##########################################################');
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
    //print('##########################################################');
    //print("dispose");
    print('##########################################################');

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
          _closeDocument();
        }
      },
    );
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
    Widget child;
    if (_loaded) {
      child = PdfRenderLoadedView(loadCtrl: loadCtrl);
    } else {
      child = const LoaderWithText("Opening Document");
    }

    return Scaffold(
      body: SafeArea(
        child: child,
      ),
    );
  }
}

/* ============================================ */
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
  static const LOADING_MAX_WIDTH = 1;
  static const LOADING_VIEWPORT_WIDTH = 2;
  static const LOADING_PAGE_RENDERS = 8;

  int loadState = 0;

  final measureKey = new GlobalKey();
  double maxPageWidth = 0;
  double viewportWidth = 0;

  double lastContrainedWidth = 0;

  List<PdfPageImage?> renderedImages = [];

  @override
  void initState() {
    super.initState();

    //_calculateViewportWidth();
    _calculateMaxPageWidth();
  }

  Future<void> _calculateMaxPageWidth() async {
    setState(() {
      loadState = loadState | LOADING_MAX_WIDTH;
    });

    final doc = widget.loadCtrl.getDocument();

    double maxW = double.negativeInfinity;

    for (int i = 0; i < doc.pagesCount; ++i) {
      final page = await doc.getPage(i + 1);
      if (page.width > maxW) maxW = page.width;
      await page.close();
    }

    setState(() {
      maxPageWidth = maxW;
      loadState = loadState & ~LOADING_MAX_WIDTH;
    });
  }

  Future<void> _onGeometryChanged() async {
    setState(() {
      loadState = loadState | LOADING_VIEWPORT_WIDTH;
    });

    await Future.delayed(Duration.zero);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject =
          measureKey.currentContext?.findRenderObject() as RenderBox?;

      final viewportWidth = renderObject?.size.width ?? 0;

      setState(() {
        this.viewportWidth = viewportWidth;
        loadState = loadState & ~LOADING_VIEWPORT_WIDTH;
      });

      _renderPages();
    });
  }

  Future<void> _renderPages() async {
    print('##########################################################');
    print('_renderPages: ${viewportWidth}');
    print('##########################################################');
    setState(() {
      loadState = loadState | LOADING_PAGE_RENDERS;
    });

    List<PdfPageImage?> renderedImages = [];
    final loadCtrl = widget.loadCtrl;
    final pagesCount = loadCtrl.getDocument().pagesCount;
    for (int i = 0; i < pagesCount; ++i) {
      final page = await loadCtrl.loadPage(i + 1);
      await page.close();
    }

    setState(() {
      loadState = loadState & ~LOADING_PAGE_RENDERS;
      this.renderedImages = renderedImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadState != 0) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        key: measureKey,
        alignment: Alignment.center,
        child: const LoaderWithText("Loading View"),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (lastContrainedWidth != constraints.maxWidth) {
        print('##########################################################');
        print("Size miss");
        print('##########################################################');
        lastContrainedWidth = constraints.maxWidth;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onGeometryChanged();
        });
      }
      return Center(
        child: Text("viewportWidth: ${viewportWidth}"),
      );
    });
  }
}
