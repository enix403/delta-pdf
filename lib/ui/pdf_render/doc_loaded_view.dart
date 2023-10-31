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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MeasuredCanvas(canvasSize: size);
      },
    );
  }
}

class MeasuredCanvas extends StatefulWidget {
  final Size canvasSize;

  const MeasuredCanvas({
    super.key,
    required this.canvasSize,
  });

  @override
  _MeasuredCanvasState createState() => _MeasuredCanvasState();
}

class _MeasuredCanvasState extends State<MeasuredCanvas> {
  bool zooming = false;
  double _baseScaleFactor = 1.0;
  double _currentScaleFactor = 1.0;

  Offset focalPoint = Offset.zero;

  double get canvasWidth => widget.canvasSize.width;
  double get canvasHeight => widget.canvasSize.height;

  double get windowWidth => widget.canvasSize.width / _currentScaleFactor;
  double get windowHeight => widget.canvasSize.height / _currentScaleFactor;

  @override
  void initState() {
    super.initState();

    focalPoint = Offset(canvasWidth, canvasHeight) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _baseScaleFactor = _currentScaleFactor;
        zooming = true;
      },
      onScaleUpdate: (details) {
        if (details.scale == 1) {
          setState(() {
            focalPoint = focalPoint.translate(details.focalPointDelta.dx, 0);
          });
          return;
        }

        setState(() {
          focalPoint = details.localFocalPoint;
          _currentScaleFactor =
              (_baseScaleFactor * details.scale).clamp(1.0, 3.0);
        });
      },
      onScaleEnd: (_) {
        zooming = false;
      },
      child: Stack(
        children: [
          Container(
            width: canvasWidth,
            height: canvasHeight,
            color: Colors.deepPurple,
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(
                (focalPoint.dx / canvasWidth) * 2 - 1,
                (focalPoint.dy / canvasHeight) * 2 - 1,
              ),
              child: Container(
                width: windowWidth,
                height: windowHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2.0,
                    color: Colors.green[300]!,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
