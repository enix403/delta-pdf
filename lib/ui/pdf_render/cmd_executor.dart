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

    print("===================================");
    print("RENDERING CHUNK");
    print(chunk.startIndex);
    print(chunk.focusIndex);
    print(chunk.endIndex);

    int leftSize = chunk.focusIndex - chunk.startIndex + 1;
    int rightSize = chunk.endIndex - chunk.focusIndex;

    int len = leftSize + rightSize;

    List<int> indices = [chunk.focusIndex, chunk.focusIndex + 1];
    List<int> steps = [-1, 1];
    List<int> rem = [leftSize, rightSize];

    bool vibrate = true;
    int valueIndex = 0;

    for (int i = 0; i < len; ++i) {
      if (_closed) {
        afterClosed();
        return false;
      }

      if (versionedChunk.version != _latestVersion) return true;

      int fetchIndex = valueIndex;
      if (vibrate) {
        if (rem[valueIndex] == 0) {
          vibrate = false;
          valueIndex = 1 - valueIndex;
          fetchIndex = valueIndex;
        } else {
          fetchIndex = valueIndex;
          valueIndex = 1 - valueIndex;
        }
      }

      final int currentIndex = indices[fetchIndex];
      indices[fetchIndex] += steps[fetchIndex];
      rem[fetchIndex]--;

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
