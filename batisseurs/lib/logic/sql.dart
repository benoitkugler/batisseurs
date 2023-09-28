import 'package:batisseurs/logic/models.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const _createSQLStatements = [
  """ 
  CREATE TABLE teams(
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    wood INTEGER NOT NULL,
    mud INTEGER NOT NULL,
    stone INTEGER NOT NULL,
    buildings TEXT NOT NULL
  );
  """,
];

extension B on Buildings {
  String toSQL() {
    return buildings.map((e) => e.toString()).join(";");
  }

  static fromSQL(String sql) {
    return Buildings(sql.split(";").map((e) => int.parse(e)).toList());
  }
}

extension T on Team {
  static Team fromSQLMap(Map<String, dynamic> map) {
    return Team(
      id: map["id"],
      name: map["name"],
      wood: map["wood"],
      mud: map["mud"],
      stone: map["stone"],
      buildings: B.fromSQL(map["buildings"]),
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "name": name,
      "wood": wood,
      "mud": mud,
      "stone": stone,
      "buildings": buildings.toSQL(),
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

    // DEV MODE only : reset DB at start
    // final fi = File(dbPath);
    // if (await fi.exists()) {
    //   await fi.delete();
    //   print("DB deleted");
    // }

    // open/create the database
    final database = await openDatabase(dbPath, version: _apiVersion,
        onCreate: (db, version) async {
      // Run the CREATE TABLE statements on the database.
      final ba = db.batch();
      for (var table in _createSQLStatements) {
        ba.execute(table);
      }
      ba.commit();
    }, singleInstance: false);

    return DBApi._(database);
  }

  Future<void> close() async {
    await db.close();
  }

  Future<List<Team>> selectTeams() async {
    final res = await db.query("teams");
    return res.map((e) => T.fromSQLMap(e)).toList();
  }

  Future<Team> createTeam(String name) async {
    final team = Team.empty(name);
    final id = await db.insert("teams", team.toSQLMap(true));
    return team.copyWith(id: id);
  }

  Future<void> updateTeam(Team team) async {
    await db.update("teams", team.toSQLMap(false));
  }

  // remove all teams, terminating the game
  Future<void> clearTeams() async {
    await db.delete("teams");
  }
}

String _arrayPlaceholders(Iterable array) {
  final values = List.filled(array.length, "?").join(",");
  return "($values)";
}
