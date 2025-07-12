class GameTheme {
  // act as an identifier
  final String name;

  final Resource r1;
  final Resource r2;
  final Resource r3;

  final List<String> buildingNames;
  final List<String> civilizations;

  const GameTheme(this.name, this.r1, this.r2, this.r3, this.buildingNames,
      this.civilizations);

  List<String> pickTeamNames(int nbTeams) {
    final l = civilizations.map((e) => e).toList();
    l.shuffle();
    return l.sublist(0, nbTeams);
  }
}

// path is used with Image.assets(path)
typedef Resource = ({String name, String path});

const themeMedieval = GameTheme(
  "Médiéval",
  (name: "bois", path: "assets/wood.png"),
  (name: "argile", path: "assets/mud.png"),
  (name: "pierre", path: "assets/stone.png"),
  [
    "Marché",
    "Forum",
    "Chambre de commerce",
    "Obélisque",
    "Statue",
    "Jardins",
    "Théâtre",
    "Panthéon",
    "Sénat",
    "Hôtel de ville",
    "Officine",
    "Laboratoire",
    "Observatoire",
    "Académie",
    "Bassin argileux",
    "Poterie",
    "Atelier",
    "Ecole des arts",
    "Ecole d'architecture",
    "Réserve",
    "Petite tour de garde",
    "Grande tour de garde",
    "Forteresse",
    "Armurerie",
    "Ecurie",
    "Camp d'entrainement",
  ],
  [
    "Romains",
    "Byzantins",
    "Egyptiens",
    "Grecs",
    "Gaulois",
    "Germains",
    "Breutons",
    "Perses",
  ],
);

const themeMaritime = GameTheme(
  "Maritime",
  (name: "planche", path: "assets/planche.png"),
  (name: "coquillage", path: "assets/coquillage.png"),
  (name: "corail", path: "assets/corail.png"),
  [
    "Marché",
    "Forum",
    "Chambre de commerce",
    "Obélisque",
    "Statue",
    "Jardins",
    "Théâtre",
    "Panthéon",
    "Sénat",
    "Hôtel de ville",
    "Officine",
    "Laboratoire",
    "Observatoire",
    "Académie",
    "Bassin à coquillages",
    "Culture de corail",
    "Atelier",
    "Ecole des arts",
    "Ecole d'architecture",
    "Réserve",
    "Petite tour de garde",
    "Grande tour de garde",
    "Forteresse",
    "Armurerie",
    "Construction navale",
    "Bassin d'entrainement",
  ],
  [
    "Dauphins",
    "Hippocampe",
    "Requins",
    "Pirates",
    "Sauriens",
  ],
);

/// [themes] expose the availables themes.
const themes = [themeMedieval, themeMaritime];
