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

  @override
  void initState() {
    super.initState();

    _results = List.filled(pageCount, null);

    renderCtrl.updateViewport(ViewportInfo(
      width: canvasWidth,
      pixelRatio: widget.pixelRatio,
    ));

    renderCtrl.enqueueChunk(_chunkForIndex(0));

    renderCtrl.outputStream.listen((result) {
      //print("@@@@@@");
      //print("Rendered index ${result.index}");
      setState(() {
        _results[result.index] = result;
      });
    });
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

  PageChunk _chunkForIndex(int index) {
    const CHUNK_SIZE = 16;

    int startIndex = (index / CHUNK_SIZE).floor() * CHUNK_SIZE;

    return PageChunk(
      startIndex,
      math.min(startIndex + CHUNK_SIZE - 1, pageCount - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFE0E0E0),
      child: ListView.builder(
        itemBuilder: (_, index) {
          print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
          print("Build index $index");

          if (index >= pageCount) return null;

          if (!renderCtrl.isPageVisited(index)) {
            renderCtrl.enqueueChunk(_chunkForIndex(index));
          }

          final result = _results[index];

          Widget child;
          if (result == null) {
            // Empty box
            child = Container(
              color: [Colors.purple, Colors.green, Colors.red][2],
              width: canvasWidth,
              height: 400,
            );
          } else {

            final physicalWidth = canvasWidth;
            final physicalHeight = physicalWidth * result.invAspectRatio;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                child: child,
              ),
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
