import 'package:batisseurs/logic/models.dart';
import 'package:batisseurs/logic/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme', () {
    expect(buildingProperties.length, BuildingType.values.length);
    expect(themeMedieval.buildingNames.length, BuildingType.values.length);
  });
}
