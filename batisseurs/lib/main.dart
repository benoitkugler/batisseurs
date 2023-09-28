import 'package:batisseurs/game.dart';
import 'package:batisseurs/logic/models.dart';
import 'package:batisseurs/logic/sql.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  const _Loader({super.key});

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  DBApi? db;

  @override
  void initState() {
    _loadDB();

    super.initState();
  }

  _loadDB() async {
    final db = await DBApi.open();
    setState(() {
      this.db = db;
    });
  }

  @override
  Widget build(BuildContext context) {
    return db == null
        ? const Scaffold(body: Center(child: Text("Chargement...")))
        : _Home(db!);
  }
}

class _Home extends StatefulWidget {
  final DBApi db;
  const _Home(this.db, {super.key});

  @override
  State<_Home> createState() => __HomeState();
}

class __HomeState extends State<_Home> {
  List<Team> teams = [];

  bool get gameStarted => teams.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameStarted ? AppBar(title: const Text("Partie en cours")) : null,
      body: gameStarted
          ? Placeholder()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Les bâtisseurs",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FadeInImage(
                        placeholder: MemoryImage(kTransparentImage),
                        image: const AssetImage("assets/city.png")),
                  ),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      elevation: 8,
                      backgroundColor: Colors.lightGreenAccent.shade200,
                    ),
                    child: const Text("Créer une partie"),
                  ),
                ],
              ),
            ),
    );
  }

  _startGame() async {
    final players = await showDialog<int>(
        context: context,
        builder: (context) =>
            GameConfigDialog((n) => Navigator.of(context).pop(n)));
    if (players == null) return;
    print("launching $players");
    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => Scaffold(
    //           appBar: AppBar(title: Text("Equipes")),
    //           body: ListView(children: []),
    //         )));
  }
}
