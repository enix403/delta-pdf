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

  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    pipeline.setViewportInfo(RenderViewportInfo(
      width: canvasWidth,
      pixelRatio: widget.pixelRatio,
    ));
    
    pipeline.taskQueue.enqueue(PageChunk(startIndex: 0, endIndex: 10));

    pipeline.taskQueue.stream.listen((value) {
      print("@@@@@@");
      print("Rendered index ${value.index}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (_, index) {
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        print("Build index $index");
        if (index >= pipeline.totalPages) return null;

        final logicalSize = pipeline.logicalSizes.sizeAt(index);
        final physicalWidth =
            canvasWidth * logicalSize.width / pipeline.maxLpWidth;
        final physicalHeight = physicalWidth / logicalSize.aspectRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _colorIndex = (_colorIndex + 1) % 3;
                });
              },
              child: Container(
                color: [Colors.purple, Colors.green, Colors.red][_colorIndex],
                width: physicalWidth,
                height: physicalHeight,
              ),
            ),
            const SizedBox(
              height: 8,
            )
          ],
        );
      },
    );
  }
}
