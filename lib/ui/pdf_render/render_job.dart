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

class RenderRequestRange {
  final int startIndex;
  final int endIndex;

  RenderRequestRange({
    required this.startIndex,
    required this.endIndex,
  });

  RenderRequestRange.empty()
      : startIndex = -1,
        endIndex = -1;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RenderRequestRange &&
            startIndex == other.startIndex &&
            endIndex == other.endIndex);
  }

  @override
  int get hashCode => startIndex.hashCode ^ endIndex.hashCode;
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
  final int pageCount;
  
  RenderJob({
    required this.loadCtrl,
    required this.onJobResult,
  }) : pageCount = loadCtrl.getDocument().pagesCount;

  RenderRequestRange currentRange = RenderRequestRange.empty();
  List<RenderedPageData> resultImages = [];

  bool cancelled = false;
  bool processing = false;

  Notifier cancelNotifier = Notifier();

  void start(RenderRequestRange range, RenderViewportInfo viewportInfo) async {
    // TODO: assert(processing == false)
    processing = true;

    resultImages.clear();
    currentRange = range;

    for (int i = range.startIndex; i <= range.endIndex; ++i) {
      if (cancelled) {
        resultImages = [];
        break;
      }

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

      resultImages.add(RenderedPageData(
        index: i,
        image: image!,
        logicalWidth: page.width,
      ));

      await pageLoader.close();
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
