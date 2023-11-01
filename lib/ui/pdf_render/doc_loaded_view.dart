import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'pipeline.dart';

class PdfDocLoadedView extends StatelessWidget {
  final RenderPipeline pipeline;

  const PdfDocLoadedView({
    super.key,
    required this.pipeline,
  });

  @override
  Widget build(BuildContext context) {
    final viewportPixelRatio = MediaQuery.of(context).devicePixelRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MeasuredCanvas(
          pipeline: pipeline,
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
  final RenderPipeline pipeline;

  const MeasuredCanvas({
    super.key,
    required this.pipeline,
    required this.canvasSize,
    required this.pixelRatio,
  });

  @override
  _MeasuredCanvasState createState() => _MeasuredCanvasState();
}

class _MeasuredCanvasState extends State<MeasuredCanvas> {
  double get canvasWidth => widget.canvasSize.width;
  double get canvasHeight => widget.canvasSize.height;

  RenderPipeline get pipeline => widget.pipeline;

  List<RenderResult?> _results = [];

  @override
  void initState() {
    super.initState();

    _results = List.filled(pipeline.totalPages, null);

    pipeline.setViewportInfo(RenderViewportInfo(
      width: canvasWidth,
      pixelRatio: widget.pixelRatio,
    ));

    pipeline.taskQueue.enqueue(PageChunk(0, 10));

    pipeline.taskQueue.stream.listen((result) {
      //print("@@@@@@");
      //print("Rendered index ${result.index}");
      setState(() {
        _results[result.index] = result;
      });
    });
  }

  PageChunk _chunkForIndex(int index) {
    const CHUNK_SIZE = 16;

    int startIndex = (index / CHUNK_SIZE).floor() * CHUNK_SIZE;

    return PageChunk(
      startIndex,
      math.min(startIndex + CHUNK_SIZE - 1, pipeline.totalPages - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFE0E0E0),
      child: ListView.builder(
        itemBuilder: (_, index) {
          //print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
          //print("Build index $index");

          if (index >= pipeline.totalPages) return null;

          final logicalSize = pipeline.logicalSizes.sizeAt(index);
          final physicalWidth =
              canvasWidth * logicalSize.width / pipeline.maxLpWidth;
          final physicalHeight = physicalWidth / logicalSize.aspectRatio;

          final result = _results[index];

          Widget child;
          if (result == null) {
            if (!pipeline.isPageVisited(index)) {
              pipeline.taskQueue.enqueue(_chunkForIndex(index));
            }

            // Empty box
            child = Container(
              color: [Colors.purple, Colors.green, Colors.red][1],
              width: physicalWidth,
              height: physicalHeight,
            );
          } else {
            child = Container(
              color: Colors.white,
              child: Image.memory(
                result.image.bytes,
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
