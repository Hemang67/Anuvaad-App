// Extracts the approved Anuvaad brand images embedded in the spec HTML and
// writes the interim app assets (design Q2: replace with approved masters).
//
// Usage: dart run tool/brand/extract_spec_assets.dart <spec.html> <outDir>
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class EmbeddedImage {
  const EmbeddedImage(this.mimeType, this.bytes);
  final String mimeType;
  final Uint8List bytes;
}

final _dataUri = RegExp(r'data:(image/[a-z+]+);base64,([A-Za-z0-9+/=]+)');

/// Unique `data:image/...;base64,` images in order of first appearance.
List<EmbeddedImage> extractEmbeddedImages(String html) {
  final seen = <String>{};
  return [
    for (final match in _dataUri.allMatches(html))
      if (seen.add(match.group(2)!)) EmbeddedImage(match.group(1)!, base64Decode(match.group(2)!)),
  ];
}

// Globe-only region of the approved 900x1609 splash artwork (no wordmark,
// tagline, progress bar or caption). Recorded in assets/branding/README.md.
const globeCrop = (x: 0, y: 610, width: 900, height: 710);

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/brand/extract_spec_assets.dart <spec.html> <outDir>');
    exit(64);
  }
  final images = extractEmbeddedImages(File(args[0]).readAsStringSync());
  final outDir = Directory(args[1])..createSync(recursive: true);

  final logo = images.isNotEmpty && images[0].mimeType == 'image/png' ? img.decodePng(images[0].bytes) : null;
  final art = images.length > 1 && images[1].mimeType == 'image/jpeg' ? img.decodeJpg(images[1].bytes) : null;
  if (logo == null || art == null || logo.width != 372 || logo.height != 320 || art.width != 900 || art.height != 1609) {
    stderr.writeln('Spec images changed; update tool/brand/extract_spec_assets.dart');
    exit(2);
  }

  File('${outDir.path}/logo_interim.png').writeAsBytesSync(images[0].bytes);

  final globe = img.copyCrop(art, x: globeCrop.x, y: globeCrop.y, width: globeCrop.width, height: globeCrop.height);
  File('${outDir.path}/globe_light_interim.jpg').writeAsBytesSync(img.encodeJpg(globe, quality: 90));

  final background = _borderMedian(logo);

  File('${outDir.path}/icon_full_interim.png')
      .writeAsBytesSync(img.encodePng(_centered(logo, canvas: 1024, logoWidth: 720, fill: background)));
  File('${outDir.path}/icon_foreground_interim.png')
      .writeAsBytesSync(img.encodePng(_centered(logo, canvas: 1024, logoWidth: 960)));
  File('${outDir.path}/splash_icon_interim.png')
      .writeAsBytesSync(img.encodePng(_centered(logo, canvas: 1152, logoWidth: 560)));

  String hex(num v) => v.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
  stdout.writeln('background=#${hex(background.r)}${hex(background.g)}${hex(background.b)}');
}

/// Median colour of the image's outermost pixels: the logo's own background.
img.ColorRgba8 _borderMedian(img.Image image) {
  final r = <int>[], g = <int>[], b = <int>[];
  void add(int x, int y) {
    final p = image.getPixel(x, y);
    r.add(p.r.toInt());
    g.add(p.g.toInt());
    b.add(p.b.toInt());
  }

  for (var x = 0; x < image.width; x++) {
    add(x, 0);
    add(x, image.height - 1);
  }
  for (var y = 1; y < image.height - 1; y++) {
    add(0, y);
    add(image.width - 1, y);
  }
  int median(List<int> v) => (v..sort())[v.length ~/ 2];
  return img.ColorRgba8(median(r), median(g), median(b), 255);
}

/// [logo] resized to [logoWidth] and centred on a square [canvas]; transparent unless [fill] is given.
img.Image _centered(img.Image logo, {required int canvas, required int logoWidth, img.Color? fill}) {
  final out = img.Image(width: canvas, height: canvas, numChannels: 4);
  if (fill != null) img.fill(out, color: fill);
  final resized = img.copyResize(logo, width: logoWidth, interpolation: img.Interpolation.cubic);
  return img.compositeImage(out, resized,
      dstX: (canvas - resized.width) ~/ 2, dstY: (canvas - resized.height) ~/ 2);
}
