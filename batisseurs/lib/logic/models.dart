/// Team stores the advance of one group of players.
class Team {
  final int id;
  final String name;
  // ressources
  final int wood;
  final int mud;
  final int stone;
  // already built
  final Buildings buildings;

  const Team({
    required this.id,
    required this.name,
    required this.wood,
    required this.mud,
    required this.stone,
    required this.buildings,
  });

  factory Team.empty(String name) => Team(
      id: 0,
      name: name,
      wood: 0,
      mud: 0,
      stone: 0,
      buildings: Buildings.empty());

  Team copyWith({
    int? id,
    String? name,
    int? wood,
    int? mud,
    int? stone,
    Buildings? buildings,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      wood: wood ?? this.wood,
      mud: mud ?? this.mud,
      stone: stone ?? this.stone,
      buildings: buildings ?? this.buildings,
    );
  }
}

enum Building {
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
  bassinArgileux,
  poterie,
  atelier,
  ecoleArts,
  ecoleArchitecture,
  petiteTourGarde,
  grandeTourGarde,
  forteresse,
  armurerie,
  ecurie,
  campEntrainement
}

class BuildingCost {
  final int wood;
  final int mud;
  final int stone;
  const BuildingCost(this.wood, this.mud, this.stone);
}

/// to keep in sync with [Building] values
const costs = [
  BuildingCost(3, 0, 0), // marche,
  BuildingCost(3, 2, 2), // forum,
  BuildingCost(1, 3, 4), // chambreCommerce,
  BuildingCost(0, 1, 1), // obelisque,
  BuildingCost(1, 1, 1), // statue,
  BuildingCost(5, 1, 1), // jardins,
  BuildingCost(3, 0, 4), // theatre,
  BuildingCost(0, 0, 1), // pantheon,
  BuildingCost(3, 2, 2), // senat,
  BuildingCost(5, 4, 4), // hotelVille,
  BuildingCost(2, 1, 0), // officine,
  BuildingCost(4, 1, 1), // laboratoire,
  BuildingCost(4, 2, 1), // observatoire,
  BuildingCost(1, 2, 3), // academie,
  BuildingCost(7, 2, 2), // bassinArgileux,
  BuildingCost(4, 1, 1), // poterie,
  BuildingCost(8, 4, 3), // atelier,
  BuildingCost(2, 1, 3), // ecoleArts,
  BuildingCost(6, 3, 4), // ecoleArchitecture,
  BuildingCost(3, 1, 3), // petiteTourGarde,
  BuildingCost(5, 2, 0), // grandeTourGarde,
  BuildingCost(3, 2, 6), // forteresse,
  BuildingCost(3, 2, 2), // armurerie,
  BuildingCost(8, 0, 0), // ecurie,
  BuildingCost(5, 4, 4), // campEntrainement
];

class Buildings {
  final List<int> buildings; // builing index -> nb ressources
  const Buildings(this.buildings);
  factory Buildings.empty() =>
      Buildings(List.filled(Building.values.length, 0));
}
