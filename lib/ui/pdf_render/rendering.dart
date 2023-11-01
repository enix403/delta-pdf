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

class CanvasInfo {
  // Physical width of the screen
  final double width;

  final double pixelRatio;

  CanvasInfo({
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
  final int version;

  PageChunk(this.startIndex, this.endIndex, {required this.version});
}

/* ===================================== */

class ExecutorArgs {
  final SendPort sendToMain;
  final PdfDocument document;

  ExecutorArgs({
    required this.sendToMain,
    required this.document,
  });
}

class RenderController {
  final PdfDocument document;
  late final DocumentMetaData metadata;

  //late final RenderCommandExecutor _cmdExecutor;

  int _latestVersion = 0;
  final List<PageChunk> _visitedChunks = [];

  RenderController(this.document);

  final StreamController<RenderResult> _renderStreamController =
      new StreamController();
  Stream<RenderResult> get stream => _renderStreamController.stream;

  late final SendPort _sendToWorker;

  Future<void> init() async {
    await _initMetadata();
    _sendToWorker = await _initWorker();
  }

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
      } else {
        // ... snap ...
      }
    });

    Isolate.spawn(
      _workerIsolate,
      ExecutorArgs(
        sendToMain: listenFromWorker.sendPort,
        document: document,
      ),
    );

    return completer.future;
  }

  static void _workerIsolate(ExecutorArgs args) {
    final listenFromMain = ReceivePort();
    args.sendToMain.send(listenFromMain.sendPort);
  }


  void addChunk(int startIndex, int endIndex) {}
  void updateCanvas(CanvasInfo canvasInfo) {}
  void isPageVisited(int index) {}
}

/* ===================================== */

class RenderCommandExecutor {
  late final PdfDocument document;
  late final DocumentMetaData metadata;

  late int _latestVersion;
  final Queue<PageChunk> _queue = Queue();
}

/* ===================================== */

abstract class RenderCommand {}

class UpdateConfigCommand extends RenderCommand {
  final CanvasInfo canvasInfo;

  UpdateConfigCommand({
    required this.canvasInfo,
  });
}

class AddChunkCommand extends RenderCommand {
  final PageChunk chunk;

  AddChunkCommand(this.chunk);
}
