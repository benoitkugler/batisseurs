import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round', () {
    expect((-1.5).ceil(), -1);
    expect((0.5).ceil(), 1);
  });
}
