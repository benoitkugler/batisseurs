import 'dart:math';

import 'package:batisseurs/logic/grid.dart';

class Game {
  final int id;
  final int gridSize;
  final int duplicatedBuildings;

  const Game({
    required this.id,
    required this.gridSize,
    required this.duplicatedBuildings,
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

  const Team({
    required this.id,
    required this.idGame,
    required this.name,
    required this.wood,
    required this.mud,
    required this.stone,
  });

  factory Team.empty(int idGame, String name) => Team(
        id: 0,
        idGame: idGame,
        name: name,
        wood: 0,
        mud: 0,
        stone: 0,
      );

  Team copyWith({
    int? id,
    int? idGame,
    String? name,
    int? wood,
    int? mud,
    int? stone,
  }) {
    return Team(
      id: id ?? this.id,
      idGame: idGame ?? this.idGame,
      name: name ?? this.name,
      wood: wood ?? this.wood,
      mud: mud ?? this.mud,
      stone: stone ?? this.stone,
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
  Stats stats() {
    final out = Stats();
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

  Stats(
      {this.victoryPoints = 0,
      this.attack = 0,
      this.defense = 0,
      this.bonusCup = 0,
      this.contremaitres = 0});

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

/// each victory add this and remove to the other team
const militaryAttackPoint = 3;

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
  // military defense
  petiteTourGarde,
  grandeTourGarde,
  forteresse,
  // military attack
  armurerie,
  ecurie,
  campEntrainement
}

class BuildingProperties {
  final String name;
  final BuildingCost cost;
  final Shape shape;
  final BuildingEffect effect;
  const BuildingProperties(this.name, this.cost, this.shape, this.effect);
}

/// to keep in sync with [BuildingType] values
const buildingProperties = <BuildingProperties>[
  BuildingProperties("Marché", BuildingCost(3, 0, 0),
      [Coord(0, 0), Coord(1, 0), Coord(2, 0)], VictoryPointEffect(1)),
  BuildingProperties(
      "Forum",
      BuildingCost(3, 2, 2),
      [Coord(0, 1), Coord(1, 1), Coord(1, 0), Coord(2, 0)],
      VictoryPointEffect(3)),
  BuildingProperties(
      "Chambre de commerce",
      BuildingCost(1, 3, 4),
      [Coord(2, 2), Coord(2, 1), Coord(1, 1), Coord(0, 1), Coord(0, 0)],
      VictoryPointEffect(6)),
  BuildingProperties("Obélisque", BuildingCost(0, 1, 1),
      [Coord(0, 0), Coord(1, 1), Coord(0, 1)], VictoryPointEffect(2)),
  BuildingProperties("Statue", BuildingCost(1, 1, 1),
      [Coord(0, 0), Coord(1, 1), Coord(1, 0)], VictoryPointEffect(2)),
  BuildingProperties(
      "Jardins",
      BuildingCost(5, 1, 1),
      [
        Coord(0, 0),
        Coord(1, 1),
        Coord(1, 0),
        Coord(0, 1),
        Coord(2, 0),
        Coord(2, 1)
      ],
      VictoryPointEffect(5)),
  BuildingProperties(
      "Théâtre",
      BuildingCost(3, 0, 4),
      [
        Coord(0, 1),
        Coord(0, 2),
        Coord(2, 1),
        Coord(0, 0),
        Coord(1, 0),
        Coord(2, 0)
      ],
      VictoryPointEffect(6)),
  BuildingProperties("Panthéon", BuildingCost(0, 0, 1),
      [Coord(0, 0), Coord(0, 1), Coord(1, 0)], VictoryPointEffect(1)),
  BuildingProperties(
      "Sénat",
      BuildingCost(3, 2, 2),
      [Coord(0, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1)],
      VictoryPointEffect(3)),
  BuildingProperties(
      "Hôtel de ville",
      BuildingCost(5, 4, 4),
      [Coord(0, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1), Coord(2, 0)],
      VictoryPointEffect(6)),
  BuildingProperties("Officine", BuildingCost(2, 1, 0),
      [Coord(0, 1), Coord(1, 1), Coord(1, 0)], VictoryPointEffect(2)),
  BuildingProperties("Laboratoire", BuildingCost(4, 1, 1),
      [Coord(0, 1), Coord(1, 1), Coord(0, 0)], VictoryPointEffect(2)),
  BuildingProperties(
      "Observatoire",
      BuildingCost(4, 2, 1),
      [
        Coord(0, 1),
        Coord(1, 1),
        Coord(2, 1),
        Coord(3, 1),
        Coord(4, 1),
        Coord(4, 0)
      ],
      VictoryPointEffect(5)),
  BuildingProperties(
      "Académie",
      BuildingCost(1, 2, 3),
      [
        Coord(1, 1),
        Coord(3, 1),
        Coord(0, 0),
        Coord(1, 0),
        Coord(2, 0),
        Coord(3, 0)
      ],
      VictoryPointEffect(6)),
  BuildingProperties("Bassin argileux", BuildingCost(7, 2, 2),
      [Coord(1, 0), Coord(0, 0)], BonusCupEffect(1)),
  BuildingProperties("Poterie", BuildingCost(4, 1, 1),
      [Coord(1, 1), Coord(0, 1), Coord(1, 0), Coord(2, 1)], BonusCupEffect(1)),
  BuildingProperties(
      "Atelier",
      BuildingCost(8, 4, 3),
      [
        Coord(1, 1),
        Coord(0, 1),
        Coord(1, 0),
        Coord(2, 1),
        Coord(2, 0),
        Coord(3, 1)
      ],
      BonusCupEffect(2)),
  BuildingProperties("Ecole des arts", BuildingCost(2, 1, 3),
      [Coord(1, 0), Coord(0, 0), Coord(2, 0)], ContremaitreEffect(1)),
  BuildingProperties(
      "Ecole d'architecture",
      BuildingCost(6, 3, 4),
      [Coord(1, 0), Coord(0, 0), Coord(2, 0), Coord(3, 0), Coord(4, 0)],
      ContremaitreEffect(2)),
  BuildingProperties("Petite tour de garde", BuildingCost(3, 1, 3),
      [Coord(1, 0), Coord(0, 0), Coord(2, 0)], DefenseEffect(1)),
  BuildingProperties(
      "Grande tour de garde",
      BuildingCost(5, 2, 0),
      [Coord(1, 1), Coord(0, 1), Coord(2, 1), Coord(1, 0), Coord(2, 0)],
      DefenseEffect(1)),
  BuildingProperties(
      "Forteresse",
      BuildingCost(3, 2, 6),
      [
        Coord(1, 1),
        Coord(0, 1),
        Coord(2, 1),
        Coord(2, 0),
        Coord(0, 0),
        Coord(3, 0),
        Coord(3, 1)
      ],
      DefenseEffect(2)),
  BuildingProperties("Armurerie", BuildingCost(3, 2, 2),
      [Coord(1, 1), Coord(0, 1), Coord(0, 0)], AttackEffect(1)),
  BuildingProperties("Ecurie", BuildingCost(8, 0, 0),
      [Coord(1, 1), Coord(0, 1), Coord(0, 0), Coord(1, 0)], AttackEffect(1)),
  BuildingProperties(
      "Camp d'entrainement",
      BuildingCost(5, 4, 4),
      [Coord(1, 1), Coord(0, 1), Coord(0, 0), Coord(1, 0), Coord(2, 1)],
      AttackEffect(2)),
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
}
