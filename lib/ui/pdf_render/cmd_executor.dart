import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import 'render_dto.dart';

class _VersionedPageChunk {
  final PageChunk chunk;
  final int version;

  _VersionedPageChunk(this.chunk, this.version);
}

class RenderCommandExecutor {
  final PdfDocument document;
  final VoidCallback afterClosed;

  RenderCommandExecutor({
    required this.document,
    required this.afterClosed,
  });

  late int _latestVersion;
  late ViewportInfo _viewportInfo;
  bool _processing = false;

  final Queue<_VersionedPageChunk> _queue = Queue();

  final StreamController<RenderResult> _streamController = StreamController();
  Stream<RenderResult> get stream => _streamController.stream;

  bool _closed = false;

  void updateConfig(int version, ViewportInfo viewportInfo) {
    _latestVersion = version;
    _viewportInfo = viewportInfo;
  }

  void enqueue(int version, PageChunk chunk) {
    _queue.add(_VersionedPageChunk(chunk, version));
    _startExecution();
  }

  void _startExecution() async {
    if (_queue.isEmpty || _processing) return;

    _processing = true;

    while (_queue.isNotEmpty) {
      final shouldContinue = await _processChunk(_queue.removeFirst());
      if (!shouldContinue)
        break;
    }

    _processing = false;
  }

  // Returns true if the processing should continue, false otherwise
  Future<bool> _processChunk(_VersionedPageChunk versionedChunk) async {
    final chunk = versionedChunk.chunk;
    for (int i = chunk.startIndex; i <= chunk.endIndex; ++i) {
      if (_closed) {
        afterClosed();
        return false;
      }

      if (versionedChunk.version != _latestVersion) return true;

      final page = await document.getPage(i + 1);
      double invAspectRatio = page.height / page.width;

      final physicalSize =
          Size(_viewportInfo.width, invAspectRatio * _viewportInfo.width) *
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
        invAspectRatio: invAspectRatio,
        version: versionedChunk.version,
      ));
    }

    return true;
  }

  void close() {
    _closed = true;
    if (!_processing) {
      afterClosed();
    }
  }
}
