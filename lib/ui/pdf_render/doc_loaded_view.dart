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

class _MeasuredCanvasState extends State<MeasuredCanvas>
    with TickerProviderStateMixin {
  /* ============ Getters ============ */
  double get canvasWidth => widget.canvasSize.width;
  double get canvasHeight => widget.canvasSize.height;

  RenderController get renderCtrl => widget.renderCtrl;
  int get pageCount => renderCtrl.document.pagesCount;

  /* ============ Rendering ============ */

  List<RenderResult?> _results = [];

  Timer? _pageReceivedDebouce;
  double _estimatedPageHeight = 400;

  /* ============ Gestures ============ */

  late final AnimationController animationV;
  late final AnimationController animationH;

  late Simulation simulationV;
  late Simulation simulationH;

  late final ScrollController scrollControllerV = ScrollController();
  late final ScrollController scrollControllerH = ScrollController();

  // values at the start of a pan
  double _baseOffsetY = 0;
  double _basePointerY = 0;

  /* ============================================= */

  double _scaleFactor = 3;
  double _baseOffsetX = 0;
  double _basePointerX = 0;
  double _currentOffsetX = 0;

  double get maxOffsetX => canvasWidth * (_scaleFactor - 1);

  double get currentOffsetX => _currentOffsetX;
  set currentOffsetX(double value) =>
      _currentOffsetX = value.clamp(0, maxOffsetX);

  @override
  void initState() {
    super.initState();
    _initRenderController();

    animationV = AnimationController.unbounded(vsync: this);
    animationV.addListener(() {
      _setScrollY(animationV.value);
    });
  }

  void _initRenderController() {
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
    animationV.dispose();
    scrollControllerV.dispose();
    super.dispose();
  }

  void _setScrollY(double value) {
    scrollControllerV
        .jumpTo(value.clamp(0, scrollControllerV.position.maxScrollExtent));
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

      if (index >= chunk.startIndex && index <= chunk.endIndex) return null;

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

  Widget _buildPageView(RenderResult result) {
    final physicalWidth = canvasWidth * _scaleFactor;
    final physicalHeight = physicalWidth * result.invAspectRatio;
    _estimatedPageHeight = physicalHeight;

    final imageWidget = Image.memory(
      result.imageData,
      width: physicalWidth,
      height: physicalHeight,
      fit: BoxFit.fill,
    );

    double time = maxOffsetX > 0 ? _currentOffsetX / maxOffsetX : 0;
    double coord = 2 * time - 1;

    final scrolled = UnconstrainedBox(
      alignment: Alignment.topLeft,
      constrainedAxis: Axis.vertical,
      child: SizedOverflowBox(
        alignment: Alignment(coord, -1),
        size: Size(canvasWidth, physicalHeight),
        child: imageWidget,
      ),
    );

    return Container(
      color: Colors.white,
      child: scrolled,
    );
  }

  Widget _buildScroller(BuildContext context) {
    return Container(
      color: Color(0xFFE0E0E0),
      child: ListView.builder(
        controller: scrollControllerV,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, index) {
          if (index >= pageCount) return null;

          final chunk = _generateChunk(index);
          if (chunk != null) renderCtrl.enqueueChunk(chunk);

          final result = _results[index];
          Widget item = result == null
              ? Container(
                  color: Colors.white,
                  width: canvasWidth,
                  height: _estimatedPageHeight,
                )
              : _buildPageView(result);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item,
              const SizedBox(
                height: 6,
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        animationV.stop();

        _baseOffsetY = scrollControllerV.position.pixels;
        _basePointerY = details.globalPosition.dy;

        _baseOffsetX = _currentOffsetX;
        _basePointerX = details.globalPosition.dx;
      },
      onPanUpdate: (details) {
        final dstY = details.globalPosition.dy - _basePointerY;
        final deltaY = -dstY;
        _setScrollY(_baseOffsetY + deltaY);

        final dstX = details.globalPosition.dx - _basePointerX;
        final deltaX = -dstX;
        //_setScrollY(_baseOffsetY + deltaX);
        setState(() {
          currentOffsetX = _baseOffsetX + deltaX;
        });
      },
      onPanEnd: (details) {
        // Vertical
        {
          animationV.stop();
          const physics = ClampingScrollPhysics();
          final simulation = physics.createBallisticSimulation(
            scrollControllerV.position,
            -details.velocity.pixelsPerSecond.dy,
          );
          if (simulation != null) {
            simulationV = simulation;
            animationV.animateWith(simulationV);
          }
        }
      },
      child: _buildScroller(context),
    );
  }
}
