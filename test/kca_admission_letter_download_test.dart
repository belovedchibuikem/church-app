import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

bool looksLikePdf(List<int> bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

void main() {
  test('looksLikePdf accepts PDF magic bytes', () {
    expect(
      looksLikePdf([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]),
      isTrue,
    );
    expect(looksLikePdf([0x7B, 0x22, 0x65, 0x72]), isFalse);
    expect(looksLikePdf(<int>[]), isFalse);
  });
}
