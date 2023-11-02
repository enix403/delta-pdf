import 'dart:typed_data';

class ViewportInfo {
  // Physical width of the screen
  final double width;

  final double pixelRatio;

  ViewportInfo({
    required this.width,
    required this.pixelRatio,
  });
}

// Represents a rendered page
class RenderResult {
  // Index of this page
  final int index;

  // Rendered image
  final Uint8List imageData;

  // Invert of the aspect ratio of the image equal to height / width;
  final double invAspectRatio;

  final int version;

  RenderResult({
    required this.index,
    required this.imageData,
    required this.invAspectRatio,
    required this.version,
  });
}

class PageChunk {
  final int startIndex;
  final int focusIndex;
  final int endIndex;

  PageChunk(this.startIndex, this.focusIndex, this.endIndex);
}
