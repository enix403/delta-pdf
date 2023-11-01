import 'dart:async';
import 'dart:collection';
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

  ChunksRenderTaskQueue? _taskQueue;
  ChunksRenderTaskQueue get taskQueue => _taskQueue!;

  void setViewportInfo(RenderViewportInfo info) {
    if (_taskQueue == null)
      _taskQueue = ChunksRenderTaskQueue(
        document: document,
        viewportInfo: info,
      );
    else
      _taskQueue!.updateViewportInfo(info);
  }

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

  bool isPageVisited(int index) {
    if (_taskQueue == null) return false;

    return _taskQueue!._visitedChunks
        .any((chunk) => index >= chunk.startIndex && index <= chunk.endIndex);
  }
}

class RenderViewportInfo {
  final double width;
  final double pixelRatio;

  RenderViewportInfo({
    required this.width,
    required this.pixelRatio,
  });
}

class RenderResult {
  final int index;
  final PdfPageImage image;
  final int version;

  RenderResult({
    required this.index,
    required this.image,
    required this.version,
  });
}

class PageChunk {
  final int startIndex;
  final int endIndex;

  PageChunk(
    this.startIndex,
    this.endIndex,
  );
}

class VersionedPageChunk {
  final PageChunk chunk;
  final int version;

  VersionedPageChunk(this.chunk, this.version);
}

class ChunksRenderTaskQueue {
  final PdfDocument document;
  RenderViewportInfo _viewportInfo;

  final Queue<VersionedPageChunk> _queue = Queue();
  final List<PageChunk> _visitedChunks = [];
  bool _processing = false;

  final StreamController<RenderResult> _streamController = StreamController();
  Stream<RenderResult> get stream => _streamController.stream;

  int _latestVersion = 0;
  int get latestVersion => _latestVersion;

  ChunksRenderTaskQueue({
    required this.document,
    required RenderViewportInfo viewportInfo,
  }) : _viewportInfo = viewportInfo;


  void tickVersion() {
    _latestVersion++;
    _visitedChunks.clear();
    _queue.clear();
  }

  void enqueue(PageChunk chunk) {
    _queue.add(VersionedPageChunk(chunk, _latestVersion));
    _visitedChunks.add(chunk);
    _startExecution();
  }

  void updateViewportInfo(RenderViewportInfo viewportInfo) {
    _viewportInfo = viewportInfo;
  }

  void _startExecution() async {
    if (_queue.isEmpty || _processing) return;

    _processing = true;

    while (_queue.isNotEmpty) {
      await _processChunk(_queue.removeFirst());
    }

    _processing = false;
  }

  Future<void> _processChunk(VersionedPageChunk versionedChunk) async {
    final chunk = versionedChunk.chunk;
    for (int i = chunk.startIndex; i <= chunk.endIndex; ++i) {
      if (versionedChunk.version != _latestVersion)
        return;

      final page = await document.getPage(i + 1);
      double aspectRatio = page.height / page.width;

      final physicalSize =
          Size(_viewportInfo.width, aspectRatio * _viewportInfo.width) *
              _viewportInfo.pixelRatio;

      final image = await page.render(
        width: physicalSize.width,
        height: physicalSize.height,
        format: PdfPageImageFormat.jpeg,
      );

      await page.close();

      //await Future.delayed(Duration(seconds: 2));

      _streamController.add(RenderResult(
        index: i,
        image: image!,
        version: versionedChunk.version,
      ));
    }
  }
}
