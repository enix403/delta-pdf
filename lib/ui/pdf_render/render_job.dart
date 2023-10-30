import 'dart:async';
import 'dart:ui';

import 'package:pdfx/pdfx.dart';
import 'controllers.dart';

class RenderedPageData {
  final int index;
  final PdfPageImage image;
  final double logicalWidth;

  RenderedPageData({
    required this.index,
    required this.image,
    required this.logicalWidth,
  });
}

class PageRange {
  final int startIndex;
  final int endIndex;

  PageRange(
    this.startIndex,
    this.endIndex,
  );

  PageRange.empty()
      : startIndex = -1,
        endIndex = -1;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PageRange &&
            startIndex == other.startIndex &&
            endIndex == other.endIndex);
  }

  @override
  int get hashCode => startIndex.hashCode ^ endIndex.hashCode;

  bool get isEmpty => startIndex == -1 && endIndex == -1;

  bool contains(int index) {
    return !isEmpty && (index >= startIndex && index <= endIndex);
  }
}

class RenderViewportInfo {
  final double width;
  final double pixelRatio;

  RenderViewportInfo({
    required this.width,
    required this.pixelRatio,
  });
}

class RenderJob {
  final PdfLoadController loadCtrl;
  final VoidCallback onJobResult;

  RenderJob({
    required this.loadCtrl,
    required this.onJobResult,
  });

  PageRange currentRange = PageRange.empty();
  List<RenderedPageData> resultImages = [];

  bool cancelled = false;
  bool processing = false;

  Notifier cancelNotifier = Notifier();

  void start(PageRange range, RenderViewportInfo viewportInfo) async {

    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    print("STARTING WITH ${range.startIndex} -> ${range.endIndex}");
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');

    // TODO: assert(processing == false)
    processing = true;

    resultImages.clear();
    currentRange = range;

    for (int i = range.startIndex; i <= range.endIndex; ++i) {
      if (cancelled) {
        resultImages = [];
        break;
      }

      print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
      print("$i ${viewportInfo.width} ${viewportInfo.pixelRatio}");

      final pageLoader = loadCtrl.loadPage(i + 1);
      final page = await pageLoader.getOrInit();
      double aspectRatio = page.height / page.width;

      final physicalSize =
          Size(viewportInfo.width, aspectRatio * viewportInfo.width) *
              viewportInfo.pixelRatio;

      final image = await page.render(
        width: physicalSize.width,
        height: physicalSize.height,
        format: PdfPageImageFormat.png,
      );

      await pageLoader.close();

      resultImages.add(RenderedPageData(
        index: i,
        image: image!,
        logicalWidth: page.width,
      ));
    }

    processing = false;

    if (cancelled) {
      cancelled = false;
      cancelNotifier.notify();
    } else {
      onJobResult();
    }
  }

  Future<void> cancel() {
    if (!processing) return Future.value();

    cancelled = true;

    final completer = new Completer<void>();

    cancelNotifier.onNotification(() {
      completer.complete();
    });

    return completer.future;
  }

  RenderedPageData? getIndexed(int index) {
    if (processing || cancelled) return null;

    if (!currentRange.contains(index)) return null;

    int dist = index - currentRange.startIndex;

    if (dist >= resultImages.length) return null;

    final item = resultImages[dist];

    return item.index == index ? item : null;
  }
}

/*==================*/

class Notifier {
  VoidCallback? callback;
  bool missed = false;

  void notify() {
    callback?.call();
    missed = callback == null;
    callback = null;
  }

  void onNotification(VoidCallback callback) {
    this.callback = callback;
    if (missed) {
      notify();
    }
  }
}
