import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

class QrCodeUtil {
  static Future<Uint8List?> svgToPngBytes(
    String svgString, {
    int size = 280,
  }) async {
    if (svgString.trim().isEmpty) return null;

    try {
      final pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );

      final image = await pictureInfo.picture.toImage(size, size);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      pictureInfo.picture.dispose();
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
