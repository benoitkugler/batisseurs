import 'dart:math';

import 'package:batisseurs/logic/grid.dart';

class Game {
  final int id;
  final int gridSize;
  const Game({
    required this.id,
    required this.gridSize,
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
      if (i <= 0 && i < victoryPoints.length) {
        out.victoryPoints += victoryPoints[i];
      } else {
        switch (building.type) {
          case BuildingType.bassinArgileux:
          case BuildingType.poterie:
            out.bonusCup += 1;
          case BuildingType.atelier:
            out.bonusCup += 2;
          case BuildingType.petiteTourGarde:
          case BuildingType.grandeTourGarde:
            out.defense += 1;
          case BuildingType.forteresse:
            out.defense += 2;
          case BuildingType.armurerie:
          case BuildingType.ecurie:
            out.attack += 1;
          case BuildingType.campEntrainement:
            out.attack += 2;
          case BuildingType.ecoleArts:
            out.contremaitres += 1;
          case BuildingType.ecoleArchitecture:
            out.contremaitres += 2;
          default:
            break;
        }
      }
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

class BuildingProperty {
  final String name;
  final BuildingCost cost;
  final Shape shape;
  const BuildingProperty(this.name, this.cost, this.shape);
}

/// to keep in sync with [BuildingType] values
const buildingProperties = <BuildingProperty>[
  BuildingProperty(
      "Marché", BuildingCost(3, 0, 0), [Coord(0, 0), Coord(1, 0), Coord(2, 0)]),
  BuildingProperty("Forum", BuildingCost(3, 2, 2),
      [Coord(0, 1), Coord(1, 1), Coord(1, 0), Coord(2, 0)]),
  BuildingProperty("Chambre de commerce", BuildingCost(1, 3, 4),
      [Coord(2, 2), Coord(2, 1), Coord(1, 1), Coord(0, 1), Coord(0, 0)]),
  BuildingProperty("Obélisque", BuildingCost(0, 1, 1),
      [Coord(0, 0), Coord(1, 1), Coord(0, 1)]),
  BuildingProperty(
      "Statue", BuildingCost(1, 1, 1), [Coord(0, 0), Coord(1, 1), Coord(1, 0)]),
  BuildingProperty("Jardins", BuildingCost(5, 1, 1), [
    Coord(0, 0),
    Coord(1, 1),
    Coord(1, 0),
    Coord(0, 1),
    Coord(2, 0),
    Coord(2, 1)
  ]),
  BuildingProperty("Théâtre", BuildingCost(3, 0, 4), [
    Coord(0, 1),
    Coord(0, 2),
    Coord(2, 1),
    Coord(0, 0),
    Coord(1, 0),
    Coord(2, 0)
  ]),
  BuildingProperty("Panthéon", BuildingCost(0, 0, 1),
      [Coord(0, 0), Coord(0, 1), Coord(1, 0)]),
  BuildingProperty("Sénat", BuildingCost(3, 2, 2),
      [Coord(0, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1)]),
  BuildingProperty("Hôtel de ville", BuildingCost(5, 4, 4),
      [Coord(0, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1), Coord(2, 0)]),
  BuildingProperty("Officine", BuildingCost(2, 1, 0),
      [Coord(0, 1), Coord(1, 1), Coord(1, 0)]),
  BuildingProperty("Laboratoire", BuildingCost(4, 1, 1),
      [Coord(0, 1), Coord(1, 1), Coord(0, 0)]),
  BuildingProperty("Observatoire", BuildingCost(4, 2, 1), [
    Coord(0, 1),
    Coord(1, 1),
    Coord(2, 1),
    Coord(3, 1),
    Coord(4, 1),
    Coord(4, 0)
  ]),
  BuildingProperty("Académie", BuildingCost(1, 2, 3), [
    Coord(1, 1),
    Coord(3, 1),
    Coord(0, 0),
    Coord(1, 0),
    Coord(2, 0),
    Coord(3, 0)
  ]),
  BuildingProperty(
      "Bassin argileux", BuildingCost(7, 2, 2), [Coord(1, 0), Coord(0, 0)]),
  BuildingProperty("Poterie", BuildingCost(4, 1, 1),
      [Coord(1, 1), Coord(0, 1), Coord(1, 0), Coord(2, 1)]),
  BuildingProperty("Atelier", BuildingCost(8, 4, 3), [
    Coord(1, 1),
    Coord(0, 1),
    Coord(1, 0),
    Coord(2, 1),
    Coord(2, 0),
    Coord(3, 1)
  ]),
  BuildingProperty("Ecole des arts", BuildingCost(2, 1, 3),
      [Coord(1, 0), Coord(0, 0), Coord(2, 0)]),
  BuildingProperty("Ecole d'architecture", BuildingCost(6, 3, 4),
      [Coord(1, 0), Coord(0, 0), Coord(2, 0), Coord(3, 0), Coord(4, 0)]),
  BuildingProperty("Petite tour de garde", BuildingCost(3, 1, 3),
      [Coord(1, 0), Coord(0, 0), Coord(2, 0)]),
  BuildingProperty("Grande tour de garde", BuildingCost(5, 2, 0),
      [Coord(1, 1), Coord(0, 1), Coord(2, 1), Coord(1, 0), Coord(2, 0)]),
  BuildingProperty("Forteresse", BuildingCost(3, 2, 6), [
    Coord(1, 1),
    Coord(0, 1),
    Coord(2, 1),
    Coord(2, 0),
    Coord(0, 0),
    Coord(3, 0),
    Coord(3, 1)
  ]),
  BuildingProperty("Armurerie", BuildingCost(3, 2, 2),
      [Coord(1, 1), Coord(0, 1), Coord(0, 0)]),
  BuildingProperty("Ecurie", BuildingCost(8, 0, 0),
      [Coord(1, 1), Coord(0, 1), Coord(0, 0), Coord(1, 0)]),
  BuildingProperty("Camp d'entrainement", BuildingCost(5, 4, 4),
      [Coord(1, 1), Coord(0, 1), Coord(0, 0), Coord(1, 0), Coord(2, 1)]),
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

const victoryPoints = [
  1, // marche
  3, // forum
  6, // chambreCommerce
  2, // obelisque
  2, // statue
  5, // jardins
  6, // theatre
  1, // pantheon
  3, // senat
  6, // hotelVille
  2, // officine
  2, // laboratoire
  5, // observatoire
  6, // academie
];
