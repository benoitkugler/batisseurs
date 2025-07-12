import 'dart:math';

import 'package:batisseurs/logic/grid.dart';

class Game {
  final int id;
  final int gridSize;
  final int duplicatedBuildings;
  final int themeIndex;

  const Game({
    required this.id,
    required this.gridSize,
    required this.duplicatedBuildings,
    required this.themeIndex,
  });
}

/// Team stores the advance of one group of players.
class Team {
  final int id;
  final int idGame;
  final String name;
  // ressources
  final int wood;
  final int mud;
  final int stone;
  // reserve
  final int stock;

  const Team({
    required this.id,
    required this.idGame,
    required this.name,
    required this.wood,
    required this.mud,
    required this.stone,
    required this.stock,
  });

  factory Team.empty(int idGame, String name) => Team(
        id: 0,
        idGame: idGame,
        name: name,
        wood: 0,
        mud: 0,
        stone: 0,
        stock: 0,
      );

  Team copyWith({
    int? id,
    int? idGame,
    String? name,
    int? wood,
    int? mud,
    int? stone,
    int? stock,
  }) {
    return Team(
      id: id ?? this.id,
      idGame: idGame ?? this.idGame,
      name: name ?? this.name,
      wood: wood ?? this.wood,
      mud: mud ?? this.mud,
      stone: stone ?? this.stone,
      stock: stock ?? this.stock,
    );
  }
}

/// [Building] represents a built and positionned building
class Building {
  final int id;
  final int idTeam;
  final BuildingType type;
  final Shape squares;

  const Building({
    required this.id,
    required this.idTeam,
    required this.type,
    required this.squares,
  });

  Building copyWith({
    int? id,
    int? idTeam,
    BuildingType? type,
    Shape? squares,
  }) {
    return Building(
      id: id ?? this.id,
      idTeam: idTeam ?? this.idTeam,
      type: type ?? this.type,
      squares: squares ?? this.squares,
    );
  }
}

class TeamExt {
  final Team team;
  final List<Building> buildings;
  const TeamExt(this.team, this.buildings);

  TeamExt copyWith({Team? team, List<Building>? buildings}) {
    return TeamExt(team ?? this.team, buildings ?? this.buildings);
  }

  /// [stats] sum the bonus of each building
  /// Note that each team has a defaut stock of 2
  Stats stats() {
    final out = Stats(stock: 2);
    for (var building in buildings) {
      final i = building.type.index;
      buildingProperties[i].effect.apply(out);
    }
    return out;
  }

  Map<BuildingType, int> buildingOccurrences() {
    final out = <BuildingType, int>{};
    for (var element in buildings) {
      out[element.type] = (out[element.type] ?? 0) + 1;
    }
    return out;
  }
}

class Stats {
  int victoryPoints;
  int attack;
  int defense;
  int bonusCup;
  int contremaitres;
  int stock;

  Stats(
      {this.victoryPoints = 0,
      this.attack = 0,
      this.defense = 0,
      this.bonusCup = 0,
      this.contremaitres = 0,
      this.stock = 0});

  @override
  String toString() {
    return "Stats($victoryPoints,$attack,$defense,$bonusCup,$contremaitres)";
  }
}

sealed class BuildingEffect {
  void apply(Stats stats);
}

class VictoryPointEffect implements BuildingEffect {
  final int points;
  const VictoryPointEffect(this.points);

  @override
  void apply(Stats stats) {
    stats.victoryPoints += points;
  }
}

class BonusCupEffect implements BuildingEffect {
  final int cups;
  const BonusCupEffect(this.cups);

  @override
  void apply(Stats stats) {
    stats.bonusCup += cups;
  }
}

class ContremaitreEffect implements BuildingEffect {
  final int contremaitres;
  const ContremaitreEffect(this.contremaitres);

  @override
  void apply(Stats stats) {
    stats.contremaitres += contremaitres;
  }
}

class AttackEffect implements BuildingEffect {
  final int attack;
  const AttackEffect(this.attack);

  @override
  void apply(Stats stats) {
    stats.attack += attack;
  }
}

class DefenseEffect implements BuildingEffect {
  final int defense;
  const DefenseEffect(this.defense);

  @override
  void apply(Stats stats) {
    stats.defense += defense;
  }
}

class ReserveEffect implements BuildingEffect {
  final int stock;
  const ReserveEffect(this.stock);

  @override
  void apply(Stats stats) {
    stats.stock += stock;
  }
}

/// each victory add this and remove to the other team
const militaryAttackPoint = 2;

/// [scores] compute the end game score for each team,
/// taking into accout military success and victory points.
List<int> scores(List<TeamExt> teams) {
  final stats = teams.map((e) => e.stats()).toList();
  // start with the victory points
  final out = stats.map((e) => e.victoryPoints).toList();
  // simulate military phase
  for (var i = 0; i < teams.length; i++) {
    for (var j = i + 1; j < teams.length; j++) {
      final teami = stats[i];
      final teamj = stats[j];
      // i attack
      final ai = max(teami.attack - teamj.defense, 0);
      // j attack
      final aj = max(teamj.attack - teami.defense, 0);
      out[i] += militaryAttackPoint * (ai - aj);
      out[j] += militaryAttackPoint * (aj - ai);
    }
  }
  return out;
}

enum BuildingType {
  // victory points
  marche,
  forum,
  chambreCommerce,
  obelisque,
  statue,
  jardins,
  theatre,
  pantheon,
  senat,
  hotelVille,
  officine,
  laboratoire,
  observatoire,
  academie,
  // bonus cup
  bassinArgileux,
  poterie,
  atelier,
  // contremaitres
  ecoleArts,
  ecoleArchitecture,
  // misc
  reserve,
  // military defense
  petiteTourGarde,
  grandeTourGarde,
  forteresse,
  // military attack
  armurerie,
  ecurie,
  campEntrainement,
}

typedef BuildingProperties = ({
  BuildingCost cost,
  Shape shape,
  BuildingEffect effect,
});

/// to keep in sync with [BuildingType] values
const buildingProperties = <BuildingProperties>[
  (
    cost: BuildingCost(3, 0, 0),
    shape: [Coord(0, 0), Coord(1, 0), Coord(2, 0)],
    effect: VictoryPointEffect(1)
  ),
  (
    cost: BuildingCost(0, 0, 1),
    shape: [Coord(0, 0), Coord(0, 1), Coord(1, 0)],
    effect: VictoryPointEffect(1)
  ),
  (
    cost: BuildingCost(3, 2, 0),
    shape: [Coord(0, 1), Coord(1, 1), Coord(1, 0)],
    effect: VictoryPointEffect(2)
  ),
  (
    cost: BuildingCost(3, 1, 1),
    shape: [Coord(0, 1), Coord(1, 1), Coord(0, 0)],
    effect: VictoryPointEffect(2)
  ),
  (
    cost: BuildingCost(0, 2, 1),
    shape: [Coord(0, 0), Coord(1, 1), Coord(0, 1)],
    effect: VictoryPointEffect(2)
  ),
  (
    cost: BuildingCost(2, 1, 1),
    shape: [Coord(0, 0), Coord(1, 1), Coord(1, 0), Coord(0, 2)],
    effect: VictoryPointEffect(2)
  ),
  (
    cost: BuildingCost(3, 2, 2),
    shape: [Coord(0, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1)],
    effect: VictoryPointEffect(3)
  ),
  (
    cost: BuildingCost(3, 2, 2),
    shape: [Coord(0, 1), Coord(1, 1), Coord(1, 0), Coord(2, 0)],
    effect: VictoryPointEffect(3)
  ),
  (
    cost: BuildingCost(5, 1, 1),
    shape: [
      Coord(0, 0),
      Coord(1, 1),
      Coord(1, 0),
      Coord(0, 1),
      Coord(2, 0),
      Coord(2, 1)
    ],
    effect: VictoryPointEffect(5)
  ),
  (
    cost: BuildingCost(4, 2, 1),
    shape: [
      Coord(0, 1),
      Coord(1, 1),
      Coord(2, 1),
      Coord(3, 1),
      Coord(4, 1),
      Coord(4, 0)
    ],
    effect: VictoryPointEffect(5)
  ),
  (
    cost: BuildingCost(1, 3, 4),
    shape: [Coord(2, 2), Coord(2, 1), Coord(1, 1), Coord(0, 1), Coord(0, 0)],
    effect: VictoryPointEffect(6)
  ),
  (
    cost: BuildingCost(4, 2, 3),
    shape: [
      Coord(0, 1),
      Coord(0, 2),
      Coord(2, 1),
      Coord(0, 0),
      Coord(1, 0),
      Coord(2, 0)
    ],
    effect: VictoryPointEffect(6)
  ),
  (
    cost: BuildingCost(3, 2, 4),
    shape: [Coord(0, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1), Coord(2, 0)],
    effect: VictoryPointEffect(6)
  ),
  (
    cost: BuildingCost(1, 4, 3),
    shape: [
      Coord(1, 1),
      Coord(3, 1),
      Coord(0, 0),
      Coord(1, 0),
      Coord(2, 0),
      Coord(3, 0)
    ],
    effect: VictoryPointEffect(6)
  ),
  (
    cost: BuildingCost(6, 2, 1),
    shape: [Coord(1, 0), Coord(0, 0)],
    effect: BonusCupEffect(1)
  ),
  (
    cost: BuildingCost(2, 2, 2),
    shape: [Coord(1, 1), Coord(0, 1), Coord(1, 0), Coord(2, 1)],
    effect: BonusCupEffect(1)
  ),
  (
    cost: BuildingCost(6, 2, 3),
    shape: [
      Coord(1, 1),
      Coord(0, 1),
      Coord(1, 0),
      Coord(2, 1),
      Coord(2, 0),
      Coord(3, 1)
    ],
    effect: BonusCupEffect(2)
  ),
  (
    cost: BuildingCost(2, 1, 3),
    shape: [Coord(1, 0), Coord(0, 0), Coord(2, 0)],
    effect: ContremaitreEffect(1)
  ),
  (
    cost: BuildingCost(6, 2, 3),
    shape: [Coord(1, 0), Coord(0, 0), Coord(2, 0), Coord(3, 0), Coord(4, 0)],
    effect: ContremaitreEffect(2)
  ),
  (
    cost: BuildingCost(3, 2, 0),
    shape: [Coord(1, 1), Coord(0, 1), Coord(0, 0), Coord(1, 0), Coord(2, 0)],
    effect: ReserveEffect(4)
  ),
  (
    cost: BuildingCost(3, 1, 3),
    shape: [Coord(1, 0), Coord(0, 0), Coord(2, 0)],
    effect: DefenseEffect(1)
  ),
  (
    cost: BuildingCost(5, 2, 1),
    shape: [Coord(1, 1), Coord(0, 1), Coord(2, 1), Coord(1, 0), Coord(2, 0)],
    effect: DefenseEffect(1)
  ),
  (
    cost: BuildingCost(3, 2, 6),
    shape: [
      Coord(1, 1),
      Coord(0, 1),
      Coord(2, 1),
      Coord(2, 0),
      Coord(0, 0),
      Coord(3, 0),
      Coord(3, 1)
    ],
    effect: DefenseEffect(2)
  ),
  (
    cost: BuildingCost(3, 2, 2),
    shape: [Coord(1, 1), Coord(0, 1), Coord(0, 0)],
    effect: AttackEffect(1)
  ),
  (
    cost: BuildingCost(8, 1, 1),
    shape: [Coord(1, 1), Coord(0, 1), Coord(0, 0), Coord(1, 0)],
    effect: AttackEffect(1)
  ),
  (
    cost: BuildingCost(5, 4, 4),
    shape: [Coord(1, 1), Coord(0, 1), Coord(0, 0), Coord(1, 0), Coord(2, 1)],
    effect: AttackEffect(2)
  ),
];

class BuildingCost {
  final int wood;
  final int mud;
  final int stone;
  const BuildingCost(this.wood, this.mud, this.stone);

  BuildingCost copyWith({
    int? wood,
    int? mud,
    int? stone,
  }) =>
      BuildingCost(
        wood ?? this.wood,
        mud ?? this.mud,
        stone ?? this.stone,
      );

  bool isSatisfied(int wood, int mud, int stone) {
    return this.wood <= wood && this.mud <= mud && this.stone <= stone;
  }

  int sandCost(int woodCost, int mudCost, int stoneCost) {
    return wood * woodCost + mud * mudCost + stone * stoneCost;
  }
}

class GameConfig {
  final int themeIndex;

  final int nbTeams;
  final int gridSize;

  /// [duplicatedBuildings] >= 1
  final int duplicatedBuildings;

  GameConfig(
      this.themeIndex, this.nbTeams, this.gridSize, this.duplicatedBuildings);
}
