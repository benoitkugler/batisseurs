import 'package:flutter/material.dart';

class GameConfigDialog extends StatelessWidget {
  final void Function(int players) launch;
  const GameConfigDialog(this.launch, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nombre d'équipes"),
      content: Wrap(
        alignment: WrapAlignment.center,
        children: List.generate(
            6,
            (index) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue.shade100),
                      onPressed: () => launch(index + 1),
                      child: Text("${index + 1}")),
                )),
      ),
    );
  }
}
