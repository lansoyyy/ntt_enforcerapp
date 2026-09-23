import 'package:enforcer_app/utils/qr_code_util.dart';
import 'package:flutter_test/flutter_test.dart';

const _pngMagic = [137, 80, 78, 71, 13, 10, 26, 10];

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
}
