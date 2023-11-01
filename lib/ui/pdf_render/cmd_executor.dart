import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import 'render_dto.dart';

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
