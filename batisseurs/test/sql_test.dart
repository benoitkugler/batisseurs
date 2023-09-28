import 'package:batisseurs/logic/models.dart';
import 'package:batisseurs/logic/sql.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Setup sqflite_common_ffi for flutter test
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });
  test('SQL API', () async {
    final db = await DBApi.open(dbPath: inMemoryDatabasePath);

    expect((await db.selectTeams()).length, 0);

    final team = await db.createTeam("My team");
    expect(team.id, 1);
    expect(team.name, "My team");

    db.updateTeam(team.copyWith(
        mud: 3, buildings: const Buildings([1, 2, 3, 4, 0, 0, 0])));

    expect((await db.selectTeams()).length, 1);

    await db.close();
  });
}
