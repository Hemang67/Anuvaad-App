import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/brand/extract_spec_assets.dart';

void main() {
  test('extracts unique data-URI images in order', () {
    final pngA = base64Encode([137, 80, 78, 71, 1]);
    final jpgB = base64Encode([255, 216, 255, 2]);
    final html = '<img src="data:image/png;base64,$pngA">'
        '<div style="background:url(data:image/jpeg;base64,$jpgB)"></div>'
        '<img src="data:image/png;base64,$pngA">';

    final images = extractEmbeddedImages(html);

    expect(images.map((i) => i.mimeType), ['image/png', 'image/jpeg']);
    expect(images.first.bytes, [137, 80, 78, 71, 1]);
    expect(images.last.bytes, [255, 216, 255, 2]);
  });

  test('ignores non-image data URIs', () {
    final font = base64Encode([0, 1, 0, 0]);
    expect(extractEmbeddedImages('<link href="data:font/woff2;base64,$font">'), isEmpty);
  });
}
