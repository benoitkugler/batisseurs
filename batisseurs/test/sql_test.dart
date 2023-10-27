import 'package:batisseurs/logic/grid.dart';
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

    expect(await db.selectGame(), null);

    final game = await db.createGame(10, true, ["1", "2", "3"]);

    expect((await db.selectTeams(game.id)).length, 3);

    final team = await db.createTeam(game.id, "My team");
    expect(team.name, "My team");
    expect((await db.selectTeams(game.id)).length, 4);

    await db.updateTeam(team.copyWith(mud: 3));

    final build = await db.addBuilding(Building(
        id: 0,
        idTeam: team.id,
        type: BuildingType.academie,
        squares: const [Coord(1, -1), Coord(2, 2)]));

    await db.deleteBuilding(build.id);

    await db.removeGame(game.id);

    expect(await db.selectGame(), null);

    await db.close();
  });
}
