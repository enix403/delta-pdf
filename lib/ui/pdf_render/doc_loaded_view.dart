import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'render_controller.dart';

class PdfDocLoadedView extends StatelessWidget {
  final RenderController renderCtrl;

  const PdfDocLoadedView({
    super.key,
    required this.renderCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final viewportPixelRatio = MediaQuery.of(context).devicePixelRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MeasuredCanvas(
          renderCtrl: renderCtrl,
          canvasSize: size,
          pixelRatio: viewportPixelRatio,
        );
      },
    );
  }
}

class MeasuredCanvas extends StatefulWidget {
  final Size canvasSize;
  final double pixelRatio;
  final RenderController renderCtrl;

  const MeasuredCanvas({
    super.key,
    required this.renderCtrl,
    required this.canvasSize,
    required this.pixelRatio,
  });

  @override
  _MeasuredCanvasState createState() => _MeasuredCanvasState();
}

class _MeasuredCanvasState extends State<MeasuredCanvas> {
  double get canvasWidth => widget.canvasSize.width;
  double get canvasHeight => widget.canvasSize.height;

  RenderController get renderCtrl => widget.renderCtrl;
  int get pageCount => renderCtrl.document.pagesCount;

  List<RenderResult?> _results = [];

  Timer? _pageReceivedDebouce;
  double _estimatedPageHeight = 400;

  @override
  void initState() {
    super.initState();

    _results = List.filled(pageCount, null);

    renderCtrl.updateViewport(ViewportInfo(
      width: canvasWidth,
      pixelRatio: widget.pixelRatio,
    ));

    renderCtrl.enqueueChunk(_generateChunk(0)!);

    renderCtrl.outputStream.listen((result) {
      //print("@@@@@@");
      //print("Rendered index ${result.index}");
      _results[result.index] = result;

      if (_pageReceivedDebouce?.isActive ?? false)
        _pageReceivedDebouce!.cancel();
      _pageReceivedDebouce = Timer(const Duration(milliseconds: 116), () {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _pageReceivedDebouce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MeasuredCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.canvasSize != widget.canvasSize ||
        oldWidget.pixelRatio != widget.pixelRatio) {
      renderCtrl.updateViewport(ViewportInfo(
        width: canvasWidth,
        pixelRatio: widget.pixelRatio,
      ));
    }
  }

  // Returns null if a chunk could not be generated (which happens if
  // there exists a chunk fot the index already)
  PageChunk? _generateChunk(int index) {
    int endOfLeft = -1;
    int startOfRight = pageCount;

    for (int i = 0; i < renderCtrl.visitedChunks.length; ++i) {
      final chunk = renderCtrl.visitedChunks[i];

      if (index >= chunk.startIndex && index <= chunk.endIndex)
        return null;

      if (index > chunk.endIndex)
        endOfLeft = math.max(endOfLeft, chunk.endIndex);
      else if (index < chunk.startIndex)
        startOfRight = math.min(chunk.startIndex, startOfRight);
    }

    const HALF_CHUNK_SIZE = 8;

    final int startIndex = math.max(endOfLeft + 1, index - HALF_CHUNK_SIZE);
    final int endIndex = math.min(startOfRight - 1, index + HALF_CHUNK_SIZE);

    return PageChunk(startIndex, index, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFE0E0E0),
      child: ListView.builder(
        itemBuilder: (_, index) {
          //print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
          //print("Build index $index");

          if (index >= pageCount) return null;

          final chunk = _generateChunk(index);

          if (chunk != null) {
            renderCtrl.enqueueChunk(chunk);
          }

          final result = _results[index];

          Widget child;
          if (result == null) {
            // Empty box
            child = Container(
              //color: [Colors.purple, Colors.green, Colors.red][2],
              color: Colors.white,
              width: canvasWidth,
              height: _estimatedPageHeight,
            );
          } else {
            final physicalWidth = canvasWidth;
            final physicalHeight = physicalWidth * result.invAspectRatio;
            _estimatedPageHeight = physicalHeight;

            child = Container(
              color: Colors.white,
              child: Image.memory(
                result.imageData,
                width: physicalWidth,
                height: physicalHeight,
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(
                height: 6,
              )
            ],
          );
        },
      ),
    );
  }
}
