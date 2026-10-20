import 'dart:typed_data';

import 'package:enforcer_app/utils/qr_code_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

const _pngMagic = [137, 80, 78, 71, 13, 10, 26, 10];

String? _decodeQr(Uint8List pngBytes) {
  final image = img.decodePng(pngBytes);
  if (image == null) return null;

  final rgba = image.getBytes(order: img.ChannelOrder.rgba);
  final pixels = Int32List(image.width * image.height);

  for (var i = 0; i < pixels.length; i++) {
    final offset = i * 4;
    pixels[i] = (0xFF << 24) |
        (rgba[offset] << 16) |
        (rgba[offset + 1] << 8) |
        rgba[offset + 2];
  }

  final source = RGBLuminanceSource(image.width, image.height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));

  return QRCodeReader().decode(bitmap).text;
}

void main() {
  group('QrCodeUtil', () {
    test('detects svg payloads', () {
      expect(QrCodeUtil.isSvg('  <?xml version="1.0"?><svg/>'), isTrue);
      expect(
        QrCodeUtil.isSvg('<svg xmlns="http://www.w3.org/2000/svg"/>'),
        isTrue,
      );
      expect(QrCodeUtil.isSvg('https://example.com/pay/abc'), isFalse);
    });

    test('generates a png from a raw value', () {
      final bytes = QrCodeUtil.valueToPngBytes('https://example.com/pay/abc');

      expect(bytes, isNotNull);
      expect(bytes!.sublist(0, 8), _pngMagic);
    });

    test('returns null for empty values', () {
      expect(QrCodeUtil.valueToPngBytes('   '), isNull);
    });

    testWidgets('routes and renders an svg payload', (tester) async {
      await tester.runAsync(() async {
        const svg = '<svg xmlns="http://www.w3.org/2000/svg" width="10" '
            'height="10"><rect width="10" height="10" fill="#000"/></svg>';

        final bytes = await QrCodeUtil.qrPayloadToPngBytes(svg);

        expect(bytes, isNotNull);
        expect(bytes!.sublist(0, 8), _pngMagic);
      });
    });
  });

  group('QrCodeUtil.normalizeQrValue', () {
    test('collapses duplicate slashes in the path', () {
      expect(
        QrCodeUtil.normalizeQrValue(
          'https://kind-water-0b5b52a00.5.azurestaticapps.net'
          '//online-payment/XPpm55pE',
        ),
        'https://kind-water-0b5b52a00.5.azurestaticapps.net'
        '/online-payment/XPpm55pE',
      );
    });

    test('keeps URLs without duplicate slashes unchanged', () {
      const value = 'https://www.ticketlink.ph/online-payment/2XpPo8MZ';

      expect(QrCodeUtil.normalizeQrValue(value), value);
    });

    test('keeps non-URL payloads unchanged', () {
      expect(QrCodeUtil.normalizeQrValue('just some text'), 'just some text');
    });
  });

  test('generates a normalized QR from a raw value', () async {
    final bytes = await QrCodeUtil.qrPayloadToPngBytes(
      'https://kind-water-0b5b52a00.5.azurestaticapps.net'
      '//online-payment/XPpm55pE',
    );

    expect(bytes, isNotNull);
    expect(
      _decodeQr(bytes!),
      'https://kind-water-0b5b52a00.5.azurestaticapps.net'
      '/online-payment/XPpm55pE',
    );
  });
}
