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
      if (!shouldContinue) break;
    }

    _processing = false;
  }

  // Returns true if the processing should continue, false otherwise
  Future<bool> _processChunk(_VersionedPageChunk versionedChunk) async {
    final chunk = versionedChunk.chunk;

    int len = chunk.endIndex - chunk.startIndex + 1;

    int move = 0;
    int delta = 0;

    bool endReached = false;

    print("===================================");
    print("RENDERING CHUNK");
    print(chunk.startIndex);
    print(chunk.focusIndex);
    print(chunk.endIndex);

    for (int i = 0; i < len; ++i) {
      if (_closed) {
        afterClosed();
        return false;
      }

      if (versionedChunk.version != _latestVersion) return true;

      int currentIndex;

      if (endReached) {
        // If either of the two ends have been visited, then we visit the remaning
        // indices in the opposite direction linearly
        delta += move;
        currentIndex = chunk.focusIndex + delta;
      } else {
        // This makes the variable `delta` generate the
        // sequence 0, +1, -1, +2, -2, ...
        delta = move - delta;
        move = 1 - move;
        // Oscillates around the focusIndex so that pages nearest to
        // focusIndex get rendered first
        currentIndex = chunk.focusIndex + delta;

        if (currentIndex == chunk.startIndex) {
          delta = -delta + 1;
          move = 1;
          endReached = true;
        } else if (currentIndex == chunk.endIndex) {
          delta = -delta;
          move = -1;
          endReached = true;
        }
      }

      print("+++++++++ => ${delta}");

      final page = await document.getPage(currentIndex + 1);
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
        index: currentIndex,
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
