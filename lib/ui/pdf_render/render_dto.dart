import 'dart:typed_data';

class DocumentMetaData {
  // Number of pages in the document
  final int pageCount;

  // Logical page widths
  final List<double> widths;

  // Logical page heights
  final List<double> heights;

  // Logical width of the widest page
  final double maxWidth;

  DocumentMetaData({
    required this.pageCount,
    required this.widths,
    required this.heights,
    required this.maxWidth,
  });
}

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

  final int version;

  RenderResult({
    required this.index,
    required this.imageData,
    required this.version,
  });
}

class PageChunk {
  final int startIndex;
  final int endIndex;

  PageChunk(this.startIndex, this.endIndex);
}

class VersionedPageChunk {
  final PageChunk chunk;
  final int version;

  VersionedPageChunk(this.chunk, this.version);
}
