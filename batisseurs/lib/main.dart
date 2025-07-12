import 'dart:io';

import 'package:batisseurs/game.dart';
import 'package:batisseurs/logic/grid.dart';
import 'package:batisseurs/logic/models.dart';
import 'package:batisseurs/logic/sql.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const localizations = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const locales = [
  Locale('fr', ''), // French, no country code
  Locale('en', ''), // English, no country code
];

void main() {
  if (Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: locales,
      localizationsDelegates: localizations,
      title: 'Les bâtisseurs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.yellow.shade400, secondary: Colors.blue.shade100),
        scaffoldBackgroundColor: Colors.blue.shade100,
        cardColor: Colors.blue.shade100,
        useMaterial3: true,
      ),
      home: const _Loader(),
    );
  }
}

class _Loader extends StatefulWidget {
  const _Loader();

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  DBApi? db;
  Game? game;

  @override
  void initState() {
    _loadDB();

    super.initState();
  }

  _loadDB() async {
    final db = await DBApi.open();
    final game = await db.selectGame();
    setState(() {
      this.db = db;
      this.game = game;
    });
  }

  @override
  Widget build(BuildContext context) {
    return db == null
        ? const Scaffold(body: Center(child: Text("Chargement...")))
        : _Home(game, game == null ? _showGameSetup : _goToGame);
  }

  _goToGame() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => GameScreen(db!, game!)));
    if (!mounted) return;

    // make sure the state is updated
    final g = await db!.selectGame();
    setState(() {
      game = g;
    });
  }

  _showGameSetup() async {
    final conf = await showDialog<GameConfig>(
        context: context,
        builder: (context) =>
            GameConfigDialog((conf) => Navigator.of(context).pop(conf)));
    if (conf == null) return;

    final newGame = await db!.createGame(conf);
    if (!mounted) return;

    setState(() {
      game = newGame;
    });

    _goToGame();
  }
}

class _Home extends StatelessWidget {
  final Game? game;
  final void Function() onLaunch;

  const _Home(this.game, this.onLaunch);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "Les bâtisseurs",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FadeInImage(
                      placeholder: MemoryImage(kTransparentImage),
                      image: const AssetImage("assets/city.png")),
                ),
              ),
              ElevatedButton(
                onPressed: onLaunch,
                style: ElevatedButton.styleFrom(
                  elevation: 8,
                  backgroundColor: Colors.lightGreenAccent.shade200,
                ),
                child: game == null
                    ? const Text("Créer une partie")
                    : const Text("Continuer la partie"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatefulWidget {
  const _Grid();

  @override
  State<_Grid> createState() => __GridState();
}

class __GridState extends State<_Grid> {
  List<Coord> tiles = [];

  @override
  Widget build(BuildContext context) {
    const gridSize = 6;
    return GridView.count(
        crossAxisCount: gridSize,
        children: List.generate(gridSize * gridSize, (index) {
          final row = index ~/ 6;
          final col = index % 6;
          final rowFromBot = gridSize - 1 - row;
          final coord = Coord(col, rowFromBot);
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: tiles.contains(coord) ? Colors.amber : null,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (tiles.contains(coord)) {
                    tiles.remove(coord);
                  } else {
                    tiles.add(coord);
                  }
                  // print("squares: $tiles");
                });
              },
            ),
          );
        }));
  }
}
