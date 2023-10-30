import 'package:pdfx/pdfx.dart';
import 'package:flutter/material.dart';

import 'misc.dart';
import 'controllers.dart';

class PdfDocLoadedView extends StatefulWidget {
  final PdfLoadController loadCtrl;

  const PdfDocLoadedView({
    super.key,
    required this.loadCtrl,
  });

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

  @override
  void initState() {
    super.initState();
    _calculateMaxLogicalPageWidth();
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
        itemBuilder: (context, index) {
          print('##########################################################');
          print("Build index ${index}");
          print('##########################################################');

          return Container(
            color: Colors.grey[100],
            alignment: Alignment.center,
            height: 100,
            child: const Text('Loading...'),
          );
        },
      );
    });
  }
}

/*

class PageItemData {
  final PdfPageImage rawImage;
  final double nativeWidth;

  PageItemData({
    required this.rawImage,
    required this.nativeWidth,
  });
}

class ListPageDelegate extends SliverChildBuilderDelegate {
  ListPageDelegate(super.builder)
      : super(
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
        );
}


Widget? _buildPageIndexed(BuildContext context, int index) {
  final pageItem = renderedImages[index % renderedImages.length];
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.memory(
        pageItem.rawImage.bytes,
        width: viewportWidth * pageItem.nativeWidth / maxLogicalPageWidth,
      ),
    ],
  );
}


Future<void> _renderPages() async {
  List<PageItemData> renderedImages = [];
  final loadCtrl = widget.loadCtrl;
  final pagesCount = loadCtrl.getDocument().pagesCount;

  for (int i = 0; i < pagesCount; ++i) {
    final pageLoader = loadCtrl.loadPage(i + 1);

    final page = await pageLoader.getOrInit();
    double aspectRatio = page.height / page.width;

    Size physicalSize = Size(viewportWidth, aspectRatio * viewportWidth);
    physicalSize *= viewportPixelRatio;

    final image = await page.render(
      width: physicalSize.width,
      height: physicalSize.height,
      format: PdfPageImageFormat.png,
    );
    await pageLoader.close();

    renderedImages
        .add(PageItemData(rawImage: image!, nativeWidth: page.width));
  }
}

*/
