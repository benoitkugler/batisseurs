import 'package:batisseurs/grid.dart';
import 'package:batisseurs/logic/models.dart';
import 'package:batisseurs/logic/sql.dart';
import 'package:flutter/material.dart';

const _civilizations = [
  "Romains",
  "Byzantins",
  "Egyptiens",
  "Grecs",
  "Gaulois",
  "Germains",
  "Breutons",
  "Perses",
];

List<String> pickTeamNames(int nbTeams) {
  final l = _civilizations.map((e) => e).toList();
  l.shuffle();
  return l.sublist(0, nbTeams);
}

class GameConfig {
  final int nbTeams;
  final int gridSize;

  GameConfig(this.nbTeams, this.gridSize);
}

class GameConfigDialog extends StatefulWidget {
  final void Function(GameConfig) launch;
  const GameConfigDialog(this.launch, {super.key});

  @override
  State<GameConfigDialog> createState() => _GameConfigDialogState();
}

class _GameConfigDialogState extends State<GameConfigDialog> {
  int nbTeams = 3;
  int gridSize = 10;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return AlertDialog(
      title: const Text("Configurer la partie"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Nombre d'équipes", style: th.textTheme.titleMedium),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(
                7,
                (index) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ChoiceChip(
                          elevation: 2,
                          selected: nbTeams == index + 1,
                          selectedColor: th.colorScheme.secondary,
                          onSelected: (b) => setState(() {
                                if (b) {
                                  nbTeams = index + 1;
                                }
                              }),
                          label: Text("${index + 1}")),
                    )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Taille de la grille",
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [7, 10, 12]
                .map((size) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ChoiceChip(
                          elevation: 2,
                          selected: gridSize == size,
                          selectedColor: th.colorScheme.secondary,
                          onSelected: (b) => setState(() {
                                if (b) {
                                  gridSize = size;
                                }
                              }),
                          label: Text("$size x $size")),
                    ))
                .toList(),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: () => widget.launch(GameConfig(nbTeams, gridSize)),
            child: const Text("Démarrer"))
      ],
    );
  }
}

class GameScreen extends StatefulWidget {
  final DBApi db;
  final Game game;
  const GameScreen(this.db, this.game, {super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<TeamExt> teams = [];

  @override
  void initState() {
    _loadTeams();
    super.initState();
  }

  _loadTeams() async {
    final l = await widget.db.selectTeams(widget.game.id);
    setState(() {
      teams = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Partie en cours")),
      body: ListView(
          children: teams
              .map((e) =>
                  InkWell(onTap: () => _showTeam(e), child: _TeamCard(e)))
              .toList()),
    );
  }

  _showTeam(TeamExt team) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => _TeamDetails(widget.db, widget.game, team)));

    _loadTeams();
  }
}

class _TeamCard extends StatelessWidget {
  final TeamExt team;
  const _TeamCard(this.team, {super.key});

  @override
  Widget build(BuildContext context) {
    final nbB = team.buildings.length;
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            team.team.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ResourceIcon(Image.asset("assets/wood.png"), team.team.wood),
              _ResourceIcon(Image.asset("assets/mud.png"), team.team.mud),
              _ResourceIcon(Image.asset("assets/stone.png"), team.team.stone),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    nbB == 0
                        ? "Aucun bâtiment"
                        : nbB == 1
                            ? "Un bâtiment"
                            : "$nbB bâtiments",
                    style: Theme.of(context).textTheme.bodyLarge),
              )
            ],
          )
        ],
      ),
    ));
  }
}

class _ResourceIcon extends StatelessWidget {
  final Image image;
  final int amount;
  final double size;
  const _ResourceIcon(this.image, this.amount, {this.size = 40, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: size, height: size, child: image),
            Text(
              "$amount",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamDetails extends StatefulWidget {
  final DBApi db;
  final Game game;
  final TeamExt team;

  const _TeamDetails(this.db, this.game, this.team, {super.key});

  @override
  State<_TeamDetails> createState() => __TeamDetailsState();
}

class __TeamDetailsState extends State<_TeamDetails> {
  late TeamExt team;

  BuildingType? toPlace; // begin purchased

  @override
  void initState() {
    team = widget.team;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.team.team.name)),
      body: Column(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ResourceButton(
                    Image.asset("assets/wood.png"), team.team.wood, _addWood),
                _ResourceButton(
                    Image.asset("assets/mud.png"), team.team.mud, _addMud),
                _ResourceButton(Image.asset("assets/stone.png"),
                    team.team.stone, _addStone),
              ],
            ),
            ElevatedButton(
                onPressed: _showBuildings,
                child: const Text("Construire un bâtiment")),
            Grid(widget.game.gridSize, team.buildings, toPlace),
          ]),
    );
  }

  _showBuildings() async {
    final t = team.team;
    final toBuild = await showDialog<BuildingType>(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
              title: const Text("Que construire ?"),
              content: ListView(
                children: BuildingType.values.map((e) {
                  final prop = buildingProperties[e.index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      tileColor: e.color().withOpacity(0.3),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      onTap: () => Navigator.of(context).pop(e),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                      title: Text(prop.name),
                      enabled: prop.cost.isSatisfied(t.wood, t.mud, t.stone),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        _ResourceIcon(
                          Image.asset("assets/wood.png"),
                          prop.cost.wood,
                          size: 20,
                        ),
                        _ResourceIcon(
                            Image.asset("assets/mud.png"), prop.cost.mud,
                            size: 20),
                        _ResourceIcon(
                            Image.asset("assets/stone.png"), prop.cost.stone,
                            size: 20),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ));

    if (toBuild == null) return;

    setState(() {
      toPlace = toBuild;
    });
  }

  _addWood() async {
    final t = team.team.copyWith(wood: team.team.wood + 1);
    await widget.db.updateTeam(t);
    setState(() {
      team = team.copyWith(team: t);

      team.buildings.add(Building(
          id: 0,
          idTeam: 0,
          type: BuildingType.academie,
          squares: buildingProperties[0].shape));
      team.buildings.add(Building(
          id: 1,
          idTeam: 0,
          type: BuildingType.ecoleArchitecture,
          squares: buildingProperties[2].shape));
      team.buildings.add(Building(
          id: 2,
          idTeam: 0,
          type: BuildingType.ecurie,
          squares: buildingProperties[5].shape));
    });
  }

  _addMud() async {
    final t = team.team.copyWith(mud: team.team.mud + 1);
    await widget.db.updateTeam(t);
    setState(() {
      team = team.copyWith(team: t);
    });
  }

  _addStone() async {
    final t = team.team.copyWith(stone: team.team.stone + 1);
    await widget.db.updateTeam(t);
    setState(() {
      team = team.copyWith(team: t);
    });
  }
}

class _ResourceButton extends StatelessWidget {
  final Image image;
  final int amount;
  final void Function() onAdd;
  const _ResourceButton(this.image, this.amount, this.onAdd, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "$amount",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 4),
              SizedBox(width: 50, height: 50, child: image)
            ],
          ),
          ElevatedButton(onPressed: onAdd, child: const Text("Acheter"))
        ],
      ),
    );
  }
}
