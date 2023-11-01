// ignore_for_file: unused_field

import 'dart:math' as math;
import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

class DocumentMetaData {
  // Number of pages in the document
  final int pageCount;

  // Logical page widths
  final List<double> widths;

  // Logical page heights
  final List<double> heights;

  // Logical width of the widest page
  final double maxWidth;

  DocumentMetaData({
    required this.pageCount,
    required this.widths,
    required this.heights,
    required this.maxWidth,
  });
}

class ViewportInfo {
  // Physical width of the screen
  final double width;

  final double pixelRatio;

  ViewportInfo({
    required this.width,
    required this.pixelRatio,
  });
}

// Represents a rendered page
class RenderResult {
  // Index of this page
  final int index;

  // Rendered image
  final Uint8List imageData;

  final int version;

  RenderResult({
    required this.index,
    required this.imageData,
    required this.version,
  });
}

class PageChunk {
  final int startIndex;
  final int endIndex;

  PageChunk(this.startIndex, this.endIndex);
}

class VersionedPageChunk {
  final PageChunk chunk;
  final int version;

  VersionedPageChunk(this.chunk, this.version);
}

/* ===================================== */

class ExecutorArgs {
  final SendPort sendToMain;
  final PdfDocument document;
  final RootIsolateToken token;

  ExecutorArgs({
    required this.sendToMain,
    required this.document,
    required this.token,
  });
}

class RenderController {
  final PdfDocument document;
  late final DocumentMetaData metadata;

  //late final RenderCommandExecutor _cmdExecutor;

  int _latestVersion = 0;
  int get latestVersion => _latestVersion;
  final List<PageChunk> _visitedChunks = [];

  RenderController(this.document);

  final StreamController<RenderResult> _renderStreamController =
      new StreamController();
  Stream<RenderResult> get outputStream => _renderStreamController.stream;

  late final SendPort _sendToWorker;

  static Future<RenderController> create(PdfDocument document) async {
    final ctrl = RenderController(document);
    await ctrl.init();
    return ctrl;
  }

  Future<void> init() async {
    await _initMetadata();
    _sendToWorker = await _initWorker();
  }

  void dispose() {}

  Future<void> _initMetadata() async {
    // Dart closures (captures) do not play well with isolates. So wrap the
    // Isolate.run(...) call in a function with all the necessary vairables passed
    // in as arguments to prevent unnecessary captures
    fire(
      RootIsolateToken token,
      PdfDocument document,
    ) =>
        Isolate.run(() async {
          BackgroundIsolateBinaryMessenger.ensureInitialized(token);
          return _constructMetaData(document);
        });

    final token = RootIsolateToken.instance!;

    metadata = await fire(token, document);
  }

  static Future<DocumentMetaData> _constructMetaData(
    PdfDocument document,
  ) async {
    int totalPages = document.pagesCount;
    List<double> widths = List.filled(totalPages, 0);
    List<double> heights = List.filled(totalPages, 0);

    double maxWidth = double.negativeInfinity;

    for (int i = 0; i < totalPages; ++i) {
      final page = await document.getPage(i + 1);

      widths[i] = page.width;
      heights[i] = page.height;

      maxWidth = math.max(maxWidth, page.width);

      await page.close();
    }

    maxWidth = maxWidth;

    return DocumentMetaData(
      pageCount: totalPages,
      widths: widths,
      heights: heights,
      maxWidth: maxWidth,
    );
  }

  Future<SendPort> _initWorker() {
    Completer<SendPort> completer = Completer();

    final listenFromWorker = ReceivePort();
    listenFromWorker.listen((data) {
      if (data is SendPort) {
        final sendToWorker = data;
        completer.complete(sendToWorker);
      } else if (data is RenderResult) {
        final result = data;
        if (result.version == _latestVersion)
          _renderStreamController.add(result);
      }
    });

    final token = RootIsolateToken.instance!;

    Isolate.spawn(
      _workerIsolate,
      ExecutorArgs(
        sendToMain: listenFromWorker.sendPort,
        document: document,
        token: token,
      ),
    );

    return completer.future;
  }

  static void _workerIsolate(ExecutorArgs args) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(args.token);

    final listenFromMain = ReceivePort();
    args.sendToMain.send(listenFromMain.sendPort);

    final cmdExecutor = RenderCommandExecutor(document: args.document);

    cmdExecutor.stream.listen((result) {
      args.sendToMain.send(result);
    });

    listenFromMain.listen((data) {
      if (data is AddChunkCommand) {
        cmdExecutor.enqueue(data.version, data.chunk);
      } else if (data is UpdateConfigCommand) {
        cmdExecutor.updateConfig(data.version, data.viewportInfo);
      }
    });
  }

  void _tickVersion() {
    _visitedChunks.clear();
    _latestVersion++;
  }

  void enqueueChunk(PageChunk chunk) {
    _visitedChunks.add(chunk);
    _sendToWorker.send(
      AddChunkCommand(
        chunk,
        version: _latestVersion,
      ),
    );
  }

  void updateViewport(ViewportInfo viewportInfo) {
    _tickVersion();
    _sendToWorker.send(
      UpdateConfigCommand(
        viewportInfo: viewportInfo,
        version: _latestVersion,
      ),
    );
  }

  bool isPageVisited(int index) {
    return _visitedChunks
        .any((chunk) => index >= chunk.startIndex && index <= chunk.endIndex);
  }
}

/* ===================================== */

class RenderCommandExecutor {
  final PdfDocument document;

  RenderCommandExecutor({
    required this.document,
  });

  late int _latestVersion;
  late ViewportInfo _viewportInfo;
  bool _processing = false;

  final Queue<VersionedPageChunk> _queue = Queue();

  final StreamController<RenderResult> _streamController = StreamController();
  Stream<RenderResult> get stream => _streamController.stream;

  void updateConfig(int version, ViewportInfo viewportInfo) {
    _latestVersion = version;
    _viewportInfo = viewportInfo;
  }

  void enqueue(int version, PageChunk chunk) {
    _queue.add(VersionedPageChunk(chunk, version));
    _startExecution();
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
      if (versionedChunk.version != _latestVersion) return;

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

      if (image == null) continue;

      _streamController.add(RenderResult(
        index: i,
        imageData: image.bytes,
        version: versionedChunk.version,
      ));
    }
  }
}

/* ===================================== */

abstract class RenderCommand {}

class UpdateConfigCommand extends RenderCommand {
  final ViewportInfo viewportInfo;
  final int version;

  UpdateConfigCommand({
    required this.viewportInfo,
    required this.version,
  });
}

class AddChunkCommand extends RenderCommand {
  final PageChunk chunk;
  final int version;

  AddChunkCommand(this.chunk, {required this.version});
}
