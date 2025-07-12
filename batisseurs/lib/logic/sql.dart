import 'package:batisseurs/logic/grid.dart';
import 'package:batisseurs/logic/models.dart';
import 'package:batisseurs/logic/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const _createSQLStatements = [
  """
  CREATE TABLE games(
    id INTEGER PRIMARY KEY,
    gridSize INTEGER NOT NULL,
    duplicatedBuildings INTEGER NOT NULL,
    themeIndex INTEGER NOT NULL,
    woodCost INTEGER NOT NULL,
    mudCost INTEGER NOT NULL,
    stoneCost INTEGER NOT NULL
  );
  """,
  """
  CREATE TABLE teams(
    id INTEGER PRIMARY KEY,
    idGame INTEGER NOT NULL,
    name TEXT NOT NULL,
    wood INTEGER NOT NULL,
    mud INTEGER NOT NULL,
    stone INTEGER NOT NULL,
    stock INTEGER NOT NULL,
    sand INTEGER NOT NULL,
    FOREIGN KEY(idGame) REFERENCES games(id) ON DELETE CASCADE
  );
  """,
  """
  CREATE TABLE buildings(
    id INTEGER PRIMARY KEY,
    idTeam INTEGER NOT NULL,
    type INTEGER NOT NULL,
    squares TEXT NOT NULL,
    FOREIGN KEY(idTeam) REFERENCES teams(id) ON DELETE CASCADE
  );
  """,
];

extension Co on Coord {
  String toSQL() => "$x,$y";
  static Coord fromSQL(String sql) {
    final coords =
        sql.split(",").map((e) => int.parse(e)).toList(growable: false);
    return Coord(coords[0], coords[1]);
  }
}

extension Bs on Shape {
  String toSQL() {
    return map((e) => e.toSQL()).join(";");
  }

  static Shape fromSQL(String sql) {
    return sql.split(";").map((e) => Co.fromSQL(e)).toList();
  }
}

extension G on Game {
  static Game fromSQLMap(Map<String, dynamic> map) {
    return Game(
      id: map["id"],
      gridSize: map["gridSize"],
      duplicatedBuildings: map["duplicatedBuildings"],
      themeIndex: map["themeIndex"],
      sandCost: BuildingCost(
        map["woodCost"],
        map["mudCost"],
        map["stoneCost"],
      ),
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "gridSize": gridSize,
      "duplicatedBuildings": duplicatedBuildings,
      "themeIndex": themeIndex,
      "woodCost": sandCost.wood,
      "mudCost": sandCost.mud,
      "stoneCost": sandCost.stone,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }
}

extension T on Team {
  static Team fromSQLMap(Map<String, dynamic> map) {
    return Team(
      id: map["id"],
      idGame: map["idGame"],
      name: map["name"],
      wood: map["wood"],
      mud: map["mud"],
      stone: map["stone"],
      stock: map["stock"],
      sand: map["sand"],
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "idGame": idGame,
      "name": name,
      "wood": wood,
      "mud": mud,
      "stone": stone,
      "stock": stock,
      "sand": sand,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }
}

extension Bu on Building {
  static Building fromSQLMap(Map<String, dynamic> map) {
    return Building(
      id: map["id"],
      idTeam: map["idTeam"],
      type: BuildingType.values[map["type"]],
      squares: Bs.fromSQL(map["squares"]),
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "idTeam": idTeam,
      "type": type.index,
      "squares": squares.toSQL(),
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }
}

/// DBApi provides a convenient API
/// over a SQL database
class DBApi {
  @visibleForTesting
  final Database db;

  const DBApi._(this.db);

  static const _apiVersion = 1;

  static Future<String> _defaultPath() async {
    const dbName = "atable_database.db";
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    return join(await getDatabasesPath(), dbName);
  }

  /// [open] open a connection, creating the DB. If needed
  /// [dbPath] may be adjusted in tests
  static Future<DBApi> open({String? dbPath}) async {
    WidgetsFlutterBinding.ensureInitialized(); // required by sqflite

    dbPath ??= await _defaultPath();

    // // DEV MODE only : reset DB at start
    // final fi = File(dbPath);
    // if (await fi.exists()) {
    //   await fi.delete();
    //   print("DB deleted");
    // }

    // open/create the database
    final database = await openDatabase(
      dbPath,
      version: _apiVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Run the CREATE TABLE statements on the database.
        final ba = db.batch();
        for (var table in _createSQLStatements) {
          ba.execute(table);
        }
        ba.commit();
      },
      singleInstance: false,
    );

    return DBApi._(database);
  }

  Future<void> close() async {
    await db.close();
  }

  Future<Game?> selectGame() async {
    final l = await db.query("games");
    if (l.isEmpty) return null;
    return G.fromSQLMap(l.first);
  }

  Future<Game> createGame(GameConfig config) async {
    final theme = themes[config.themeIndex];
    final teamNames = theme.pickTeamNames(config.nbTeams);
    final newGame = Game(
      id: 0,
      gridSize: config.gridSize,
      duplicatedBuildings: config.duplicatedBuildings,
      themeIndex: config.themeIndex,
      sandCost: const BuildingCost(1, 2, 3),
    );

    final idGame = await db.insert("games", newGame.toSQLMap(true));

    final batch = db.batch();
    for (var name in teamNames) {
      batch.insert("teams", Team.empty(idGame, name).toSQLMap(true));
    }
    batch.commit();
    return newGame.copyWith(id: idGame);
  }

  Future<void> updateGame(Game game) async {
    await db.update("games", game.toSQLMap(false),
        where: "id = ?", whereArgs: [game.id]);
  }

  Future<List<TeamExt>> selectTeams(int idGame) async {
    final teams =
        (await db.query("teams", where: "idGame = ?", whereArgs: [idGame]))
            .map((e) => T.fromSQLMap(e))
            .toList();
    final buildings = (await db.query("buildings",
            where: "idTeam IN ${_arrayPlaceholders(teams)}",
            whereArgs: teams.map((e) => e.id).toList()))
        .map((e) => Bu.fromSQLMap(e));

    final byTeam = <int, List<Building>>{};
    for (var building in buildings) {
      final l = byTeam.putIfAbsent(building.idTeam, () => []);
      l.add(building);
    }

    return teams.map((e) => TeamExt(e, byTeam[e.id] ?? [])).toList();
  }

  Future<Team> createTeam(int idGame, String name) async {
    final team = Team.empty(idGame, name);
    final id = await db.insert("teams", team.toSQLMap(true));
    return team.copyWith(id: id);
  }

  Future<void> updateTeam(Team team) async {
    await db.update("teams", team.toSQLMap(false),
        where: "id = ?", whereArgs: [team.id]);
  }

  // remove all teams, terminating the game
  Future<void> removeGame(int id) async {
    await db.delete("teams", where: "idGame = ?", whereArgs: [id]);
    await db.delete("games", where: "id = ?", whereArgs: [id]);
  }

  Future<Building> addBuilding(Building building) async {
    final id = await db.insert("buildings", building.toSQLMap(true));
    return building.copyWith(id: id);
  }

  Future<void> deleteBuilding(int id) async {
    await db.delete("buildings", where: "id = ?", whereArgs: [id]);
  }
}

String _arrayPlaceholders(Iterable array) {
  final values = List.filled(array.length, "?").join(",");
  return "($values)";
}
