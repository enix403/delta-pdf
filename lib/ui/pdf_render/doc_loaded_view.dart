import 'dart:math' as math;
import 'package:pdfx/pdfx.dart';
import 'package:flutter/material.dart';

import 'misc.dart';
import 'controllers.dart';
import 'render_job.dart';

class PdfDocLoadedView extends StatefulWidget {
  final PdfLoadController loadCtrl;
  final int pageCount;

  PdfDocLoadedView({
    super.key,
    required this.loadCtrl,
  }) : pageCount = loadCtrl.getDocument().pagesCount;

  @override
  State<PdfDocLoadedView> createState() => _PdfDocLoadedViewState();
}

class _PdfDocLoadedViewState extends State<PdfDocLoadedView> {
  static const int LOADING_MAX_WIDTH = 1;
  static const int LOADING_VIEWPORT_WIDTH = 2;

  int loadState = 0;

  final measureKey = new GlobalKey();
  double maxLogicalPageWidth = 0;
  double viewportWidth = 0;
  double viewportPixelRatio = 0;

  double lastContrainedWidth = 0;

  /* ============ */

  late final RenderJob renderJob;
  PageRange awaitingSet = PageRange.empty();

  @override
  void initState() {
    super.initState();
    _calculateMaxLogicalPageWidth();

    renderJob = new RenderJob(
      loadCtrl: widget.loadCtrl,
      onJobResult: () {
        setState(() {
          print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
          print("onJobResult");
          print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
          awaitingSet = PageRange.empty();
        });
      },
    );
  }

  @override
  void dispose() {
    renderJob.cancel();
    super.dispose();
  }

  Future<void> _calculateMaxLogicalPageWidth() async {
    setState(() {
      loadState = loadState | LOADING_MAX_WIDTH;
    });

    final doc = widget.loadCtrl.getDocument();

    double maxW = double.negativeInfinity;

    for (int i = 0; i < doc.pagesCount; ++i) {
      final page = await doc.getPage(i + 1);
      if (page.width > maxW) maxW = page.width;
      await page.close();
    }

    setState(() {
      maxLogicalPageWidth = maxW;
      loadState = loadState & ~LOADING_MAX_WIDTH;
    });
  }

  Future<void> _onGeometryChanged() async {
    setState(() {
      loadState = loadState | LOADING_VIEWPORT_WIDTH;
    });

    await Future.delayed(Duration.zero);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject =
          measureKey.currentContext?.findRenderObject() as RenderBox?;

      final viewportWidth = renderObject?.size.width ?? 0;

      setState(() {
        this.viewportWidth = viewportWidth;
        loadState = loadState & ~LOADING_VIEWPORT_WIDTH;
      });

      //_renderPages();
    });
  }

  Widget? _onPageDraw(BuildContext context, int index) {
    if (index >= widget.pageCount)
      return null;

    //print('##########################################################');
    //print("Build index ${index}");
    //print('##########################################################');

    final pageData = renderJob.getIndexed(index);

    if (pageData != null) {
      // render the page
      final color = [Colors.blue, Colors.yellow, Colors.green][index % 3];
      return Container(height: 200, color: color);
    } else if (!awaitingSet.contains(index)) {
      if (viewportWidth > 0 && viewportPixelRatio > 0) {
        const int EXTENT = 20;
        PageRange newRange = PageRange(
          math.max(0, index - EXTENT),
          math.min(index + EXTENT, widget.pageCount - 1),
        );
        // Note: no setState(...);
        awaitingSet = newRange;
        renderJob.cancel().then((_) {
          renderJob.start(
            newRange,
            RenderViewportInfo(
              width: viewportWidth,
              pixelRatio: viewportPixelRatio,
            ),
          );
        });
      }
    }

    return Container(
      color: Colors.grey[100],
      alignment: Alignment.center,
      height: 100,
      child: const Text('Loading...'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadState != 0) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        key: measureKey,
        alignment: Alignment.center,
        child: const LabelledSpinner("Loading View"),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (lastContrainedWidth != constraints.maxWidth) {
        print('##########################################################');
        print("Size miss");
        print('##########################################################');
        lastContrainedWidth = constraints.maxWidth;
        viewportPixelRatio = MediaQuery.of(context).devicePixelRatio;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onGeometryChanged();
        });
      }

      return ListView.builder(
        itemBuilder: _onPageDraw,
      );
    });
  }
}
