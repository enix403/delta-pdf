import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

class DimesionList {
  // Logical page widths
  List<double> widths = [];

  // Logical page heights
  List<double> heights = [];

  // Widest page
  double maxWidth = 0;

  Size sizeAt(int i) => new Size(widths[i], heights[i]);
}

class RenderPipeline {
  final PdfDocument document;

  // Number of pages
  int get totalPages => document.pagesCount;

  // Logical sizes each page
  late final DimesionList logicalSizes;

  // Width of widest page
  double get maxLpWidth => logicalSizes.maxWidth;

  RenderPipeline(this.document);

  static Future<RenderPipeline> create(PdfDocument document) async {
    final pipeline = RenderPipeline(document);
    await pipeline._init();
    return pipeline;
  }

  static Future<DimesionList> _calculateLogicalWidths(
    PdfDocument document,
  ) async {
    DimesionList dmList = DimesionList();

    int totalPages = document.pagesCount;
    dmList.widths = List.filled(totalPages, 0);
    dmList.heights = List.filled(totalPages, 0);

    double maxWidth = double.negativeInfinity;

    for (int i = 0; i < totalPages; ++i) {
      final page = await document.getPage(i + 1);

      dmList.widths[i] = page.width;
      dmList.heights[i] = page.height;

      maxWidth = math.max(maxWidth, page.width);

      await page.close();
    }

    dmList.maxWidth = maxWidth;

    return dmList;
  }

  Future<void> _init() async {
    final token = RootIsolateToken.instance!;
    logicalSizes = await Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      return _calculateLogicalWidths(document);
    });
  }

  void dispose() {
    // TODO close the document
  }
}
