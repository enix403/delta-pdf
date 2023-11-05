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

  double get scaledCanvasWidth => canvasWidth * _scaleFactor;

  RenderController get renderCtrl => widget.renderCtrl;
  int get pageCount => renderCtrl.document.pagesCount;

  /* ============ Rendering ============ */

  List<RenderResult?> _results = [];

  Timer? _pageReceivedDebouce;
  double _estimatedPageHeight = 400;

  /* ============ Gestures ============ */

  double _scaleFactor = 1;
  double _baseScaleFactor = 1;
  bool _currentlyZooming = false;

  final _ScrollPack _scrollPackH = _ScrollPack();
  final _ScrollPack _scrollPackV = _ScrollPack();

  final _pointerBase = Point(0, 0);
  final _offsetBase = Point(0, 0);

  double get maxOffsetX => canvasWidth * (_scaleFactor - 1);
  double _currentOffsetX = 0;

  @override
  void initState() {
    super.initState();
    _initRenderController();

    _scrollPackH.init(vsync: this);
    _scrollPackV.init(vsync: this);

    _scrollPackH.scrollController.addListener(() {
      setState(() {
        _currentOffsetX = _scrollPackH.scrollController.offset;
      });
    });
  }

  void _initRenderController() {
    _results = List.filled(pageCount, null);

    renderCtrl.updateViewport(ViewportInfo(
      width: scaledCanvasWidth,
      pixelRatio: widget.pixelRatio,
    ));

    renderCtrl.enqueueChunk(_generateChunk(0)!);

    renderCtrl.outputStream.listen((result) {
      //print("@@@@@@");
      //print("Rendered index ${result.index}");
      _results[result.index] = result;

      if (_pageReceivedDebouce?.isActive ?? false)
        _pageReceivedDebouce!.cancel();
      _pageReceivedDebouce = Timer(const Duration(milliseconds: 200), () {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _pageReceivedDebouce?.cancel();
    _scrollPackH.dispose();
    _scrollPackV.dispose();
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
    final physicalWidth = scaledCanvasWidth;
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
        controller: _scrollPackV.scrollController,
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
      onScaleStart: (details) {
        _scrollPackH.animController.stop();
        _scrollPackV.animController.stop();

        _offsetBase.x = _scrollPackH.offset;
        _offsetBase.y = _scrollPackV.offset;

        _pointerBase.x = details.focalPoint.dx;
        _pointerBase.y = details.focalPoint.dy;

        if (details.pointerCount > 1) {
          _currentlyZooming = true;
          _baseScaleFactor = _scaleFactor;
        }
      },
      onScaleUpdate: (details) {
        final newPoint = Point(details.focalPoint.dx, details.focalPoint.dy);
        final displacement = newPoint - _pointerBase;

        // We use -displacement since the page should move opposite to the pointer;
        final newOffset = _offsetBase - displacement;

        _scrollPackH.setScroll(newOffset.x);
        _scrollPackV.setScroll(newOffset.y);

        if (_currentlyZooming) {
          setState(() {
            double newScale = _baseScaleFactor * details.scale;
            _scaleFactor = math.max(1.0, newScale);
          });
        }
      },
      onScaleEnd: (details) {
        if (_currentlyZooming) {
          _currentlyZooming = false;
          // Re render only when zoom has actually changed
          if (_baseScaleFactor != _scaleFactor)
            renderCtrl.updateViewport(ViewportInfo(
              width: scaledCanvasWidth,
              pixelRatio: widget.pixelRatio,
            ));
        }

        _scrollPackH
            .applyPostScrollSimulation(-details.velocity.pixelsPerSecond.dx);
        _scrollPackV
            .applyPostScrollSimulation(-details.velocity.pixelsPerSecond.dy);
      },
      child: Stack(
        children: [
          _buildScroller(context),
          Positioned.fill(
            child: ListView(
              controller: _scrollPackH.scrollController,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(
                  //color: Colors.red,
                  height: canvasHeight,
                  width: scaledCanvasWidth,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class Point {
  double x;
  double y;

  Point(this.x, this.y);

  Point operator -(Point other) {
    return Point(x - other.x, y - other.y);
  }

  Point operator +(Point other) {
    return Point(x + other.x, y + other.y);
  }
}

class _ScrollPack {
  late final AnimationController animController;
  final ScrollController scrollController = ScrollController();

  void init({required TickerProvider vsync}) {
    animController = AnimationController.unbounded(vsync: vsync);
    animController.addListener(() {
      setScroll(animController.value);
    });
  }

  double get offset => scrollController.position.pixels;

  double setScroll(double value) {
    value = value.clamp(0, scrollController.position.maxScrollExtent);
    scrollController.jumpTo(value);
    return value;
  }

  void dispose() {
    animController.dispose();
    scrollController.dispose();
  }

  void applyPostScrollSimulation(double velocity) {
    animController.stop();
    const physics = ClampingScrollPhysics();
    final simulation = physics.createBallisticSimulation(
      scrollController.position,
      velocity,
    );
    if (simulation != null) {
      animController.animateWith(simulation);
    }
  }
}
