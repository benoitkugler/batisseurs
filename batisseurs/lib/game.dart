import 'package:batisseurs/grid.dart';
import 'package:batisseurs/logic/grid.dart';
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
      appBar: AppBar(
        title: const Text("Partie en cours"),
        actions: [
          TextButton(onPressed: _showRankings, child: const Text("Classement")),
          IconButton(
              onPressed: _closeGame, icon: const Icon(Icons.delete_forever)),
        ],
      ),
      body: ListView(
          children: teams
              .map((e) => InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  onTap: () => _showTeam(e),
                  child: _TeamCard(e)))
              .toList()),
    );
  }

  _closeGame() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Terminer la partie"),
              content: const Text(
                  "Es-tu sur de terminer et effacer la partie ? Cette opération est irréversible."),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Terminer et effacer"),
                )
              ],
            ));

    if (confirm ?? false) {
      await widget.db.removeGame(widget.game.id);
      if (!mounted) return;

      Navigator.of(context).pop();
    }
  }

  _showRankings() async {
    final scs = scores(teams);
    showDialog(
        context: context, builder: (context) => _RankingsDialog(teams, scs));
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
    final stats = team.stats();
    final hasZeroStats =
        stats.bonusCup + stats.contremaitres + stats.attack + stats.defense ==
            0;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResourceIcon(Image.asset("assets/wood.png"), team.team.wood),
              ResourceIcon(Image.asset("assets/mud.png"), team.team.mud),
              ResourceIcon(Image.asset("assets/stone.png"), team.team.stone),
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
          ),
          if (!hasZeroStats)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: _ReapeatIcon(
                            Image.asset("assets/cup.png"), stats.bonusCup)),
                    Expanded(
                        child: _ReapeatIcon(
                            Image.asset("assets/contremaitre.png"),
                            stats.contremaitres)),
                    Expanded(
                        child: _ReapeatIcon(
                            Image.asset("assets/swords.png"), stats.attack)),
                    Expanded(
                        child: _ReapeatIcon(
                            Image.asset("assets/shield.png"), stats.defense)),
                  ],
                ),
              ),
            )
        ],
      ),
    ));
  }
}

class _ReapeatIcon extends StatelessWidget {
  final Image icon;
  final int nbRepeat;
  const _ReapeatIcon(this.icon, this.nbRepeat, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Wrap(
          alignment: WrapAlignment.center,
          children: List.filled(
              nbRepeat, SizedBox(width: 20, height: 20, child: icon))),
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

  @override
  void initState() {
    team = widget.team;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.team.name),
        actions: [
          TextButton(onPressed: _showTrade, child: const Text("Commercer"))
        ],
      ),
      body:
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Card(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ResourceButton(
                  Image.asset("assets/wood.png"), team.team.wood, _addWood),
              _ResourceButton(
                  Image.asset("assets/mud.png"), team.team.mud, _addMud),
              _ResourceButton(
                  Image.asset("assets/stone.png"), team.team.stone, _addStone),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: Grid(team, widget.game.gridSize, _addBuilding)),
      ]),
    );
  }

  _showTrade() async {
    final teams = await widget.db.selectTeams(widget.game.id);
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (context) => _TradeDialog(team.team, teams, _doTrade));
  }

  _doTrade(Team otherTeam, BuildingCost toGive, BuildingCost toReceive) async {
    Navigator.of(context).pop();
    final t = team.team;
    final newT = t.copyWith(
        wood: t.wood - toGive.wood + toReceive.wood,
        mud: t.mud - toGive.mud + toReceive.mud,
        stone: t.stone - toGive.stone + toReceive.stone);
    final newOtherT = otherTeam.copyWith(
        wood: otherTeam.wood + toGive.wood - toReceive.wood,
        mud: otherTeam.mud + toGive.mud - toReceive.mud,
        stone: otherTeam.stone + toGive.stone - toReceive.stone);
    await widget.db.updateTeam(newT);
    await widget.db.updateTeam(newOtherT);
    if (!mounted) return;
    setState(() {
      team = team.copyWith(team: newT);
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Echange effectué."),
      backgroundColor: Colors.lightGreen,
    ));
  }

  _addBuilding(BuildingType toPlace, Shape shape) async {
    final b = await widget.db.addBuilding(
        Building(id: 0, idTeam: team.team.id, type: toPlace, squares: shape));
    // pay the price
    final cost = buildingProperties[toPlace.index].cost;
    final t = team.team;
    final newT = t.copyWith(
        wood: t.wood - cost.wood,
        mud: t.mud - cost.mud,
        stone: t.stone - cost.stone);
    await widget.db.updateTeam(newT);

    setState(() {
      team.buildings.add(b);
      team = team.copyWith(team: newT);
    });
  }

  _addWood() async {
    final t = team.team.copyWith(wood: team.team.wood + 1);
    await widget.db.updateTeam(t);
    setState(() {
      team = team.copyWith(team: t);
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

class _TradeDialog extends StatefulWidget {
  final Team team;
  final List<TeamExt> allTeams;

  final void Function(
      Team otherTeam, BuildingCost toGive, BuildingCost toReceive) onTrade;

  const _TradeDialog(this.team, this.allTeams, this.onTrade, {super.key});

  @override
  State<_TradeDialog> createState() => __TradeDialogState();
}

class __TradeDialogState extends State<_TradeDialog> {
  int? otherTeamId;
  BuildingCost toGive = const BuildingCost(0, 0, 0);
  BuildingCost toReceive = const BuildingCost(0, 0, 0);

  Team? get otherTeam => widget.allTeams
      .firstWhere((element) => element.team.id == otherTeamId)
      .team;

  bool get isTradeValid {
    if (otherTeamId == null) return false;
    final thisTeam = widget.team;
    return toGive.isSatisfied(thisTeam.wood, thisTeam.mud, thisTeam.stone) &&
        toReceive.isSatisfied(
            otherTeam!.wood, otherTeam!.mud, otherTeam!.stone);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Echanger des ressources"),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          DropdownMenu<int>(
            onSelected: (value) => setState(() {
              otherTeamId = value;
            }),
            dropdownMenuEntries: widget.allTeams
                .where((t) => t.team.id != widget.team.id)
                .map((e) =>
                    DropdownMenuEntry(value: e.team.id, label: e.team.name))
                .toList(),
            label: const Text("Avec l'équipe"),
          ),
          Text(
            "Donner",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ResourceField(
                  Image.asset("assets/wood.png"),
                  _IntegerInput(
                      toGive.wood,
                      (v) => setState(() {
                            toGive = toGive.copyWith(wood: v);
                          }))),
              _ResourceField(
                  Image.asset("assets/mud.png"),
                  _IntegerInput(
                      toGive.mud,
                      (v) => setState(() {
                            toGive = toGive.copyWith(mud: v);
                          }))),
              _ResourceField(
                  Image.asset("assets/stone.png"),
                  _IntegerInput(
                      toGive.stone,
                      (v) => setState(() {
                            toGive = toGive.copyWith(stone: v);
                          }))),
            ],
          ),
          Text(
            "Recevoir",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ResourceField(
                  Image.asset("assets/wood.png"),
                  _IntegerInput(
                      toReceive.wood,
                      (v) => setState(() {
                            toReceive = toReceive.copyWith(wood: v);
                          }))),
              _ResourceField(
                  Image.asset("assets/mud.png"),
                  _IntegerInput(
                      toReceive.mud,
                      (v) => setState(() {
                            toReceive = toReceive.copyWith(mud: v);
                          }))),
              _ResourceField(
                  Image.asset("assets/stone.png"),
                  _IntegerInput(
                      toReceive.stone,
                      (v) => setState(() {
                            toReceive = toReceive.copyWith(stone: v);
                          }))),
            ],
          ),
          ElevatedButton(
              onPressed: isTradeValid
                  ? () => widget.onTrade(otherTeam!, toGive, toReceive)
                  : null,
              child: const Text("Procéder à l'échange"))
        ],
      ),
    );
  }
}

class _IntegerInput extends StatelessWidget {
  final int value;
  final void Function(int) onChange;
  const _IntegerInput(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("$value", style: Theme.of(context).textTheme.titleMedium),
        ),
        Row(
          children: [
            IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 18,
                onPressed: value > 0 ? () => onChange(value - 1) : null,
                icon: const Icon(Icons.remove)),
            IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 18,
                onPressed: () => onChange(value + 1),
                icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}

class _ResourceField extends StatelessWidget {
  final Image image;
  final Widget field;

  const _ResourceField(this.image, this.field, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          SizedBox(width: 40, height: 40, child: image),
          field
        ],
      ),
    );
  }
}

class _RankingsDialog extends StatelessWidget {
  final List<TeamExt> teams;
  final List<int> scores;

  const _RankingsDialog(this.teams, this.scores, {super.key});

  @override
  Widget build(BuildContext context) {
    final sorted = List.generate(
        teams.length, (index) => MapEntry(teams[index], scores[index]));
    sorted.sort((a, b) => -a.value + b.value);
    return AlertDialog(
        title: const Text("Classement"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: [
              ListTile(
                trailing: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset("assets/victory.png")),
              ),
              ...sorted.map((e) => ListTile(
                    title: Text(e.key.team.name),
                    trailing: Text(
                      "${e.value}",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ))
            ],
          ),
        ));
  }
}
