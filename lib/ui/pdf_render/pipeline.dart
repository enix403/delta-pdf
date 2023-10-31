import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

class DimesionList {
  // Logical page widths
  List<double> widths = [];

  // Logical page heights
  List<double> heights = [];

  Size sizeAt(int i) => new Size(widths[i], heights[i]);
}

class RenderPipeline {
  final PdfDocument document;

  // Number of pages
  int get totalPages => document.pagesCount;

  // Logical sizes each page
  late final DimesionList logicalSizes;

  // Logical width of the widest page
  double maxLpWidth = double.negativeInfinity;

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

    for (int i = 0; i < totalPages; ++i) {
      final page = await document.getPage(i + 1);

      dmList.widths[i] = page.width;
      dmList.heights[i] = page.height;

      await page.close();
    }

    return dmList;
  }

  Future<void> _init() async {
    final token = RootIsolateToken.instance!;
    logicalSizes = await Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      return _calculateLogicalWidths(document);
    });

    maxLpWidth = double.negativeInfinity;

    for (int i = 0; i < totalPages; ++i)
      maxLpWidth = math.max(maxLpWidth, logicalSizes.widths[i]);

    // print("====================================");
    // print("init completed");
    // print("$logicalSizes");
    // print("$totalPages AND ${logicalSizes.widths.length} AND ${logicalSizes.heights.length}");
    // print("$maxLpWidth");
    // print("====================================");
  }
}
