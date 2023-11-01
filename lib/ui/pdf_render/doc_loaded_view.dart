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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MeasuredCanvas(canvasSize: size, pipeline: pipeline);
      },
    );
  }
}

class MeasuredCanvas extends StatefulWidget {
  final Size canvasSize;
  final RenderPipeline pipeline;

  const MeasuredCanvas({
    super.key,
    required this.canvasSize,
    required this.pipeline,
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
