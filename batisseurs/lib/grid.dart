import 'package:batisseurs/logic/models.dart';
import 'package:flutter/material.dart';

extension Bt on BuildingType {
  Color color() {
    if (index <= BuildingType.academie.index) {
      return Colors.blue;
    } else if (index <= BuildingType.ecoleArchitecture.index) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }
}

class Grid extends StatefulWidget {
  final int gridSize;

  final List<Building> buildings;

  final BuildingType? toPlace;

  const Grid(this.gridSize, this.buildings, this.toPlace, {super.key});

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  Building? selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (widget.toPlace != null)
            const Text("Choisis l'emplacement du bâtiment"),
          LayoutBuilder(builder: (context, constraints) {
            final gridWidth = constraints.biggest.shortestSide;
            return Stack(children: [
              _GridBackground(gridWidth, widget.gridSize),
              _Buildings(
                  gridWidth,
                  widget.gridSize,
                  _merge(widget.buildings, widget.gridSize),
                  widget.toPlace != null,
                  selected,
                  (b) => setState(() {
                        selected = b;
                      }))
            ]);
          }),
          if (selected != null) _BuildingCard(selected!),
        ],
      ),
    );
    // MediaQuery.of(context).size.shortestSide
    // return GridView.count(
    //   crossAxisCount: size,
    //   children: List.generate(size * size, (index) {
    //     final row = index ~/ size;
    //     final col = index % size;
    //     return Container(
    //       decoration: BoxDecoration(color: Colors.white, border: Border.all()),
    //       child: SizedBox(width: 60, height: 60),
    //     );
    //   }),
    // );
  }
}

class _GridBackground extends StatelessWidget {
  final double gridWith;
  final int gridSize;
  const _GridBackground(this.gridWith, this.gridSize, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gridWith,
      height: gridWith,
      child: Row(
          children: List.generate(
        gridSize,
        (index) => Column(
            children: List.generate(
          gridSize,
          (index) => Container(
              width: gridWith / gridSize,
              height: gridWith / gridSize,
              decoration: BoxDecoration(border: Border.all(width: 0.5))),
        )),
      )),
    );
  }
}

class _Buildings extends StatelessWidget {
  final double gridWith;
  final int gridSize;

  final _MergedBuildings buildings;
  final bool disabled;

  final Building? selected;

  final void Function(Building) onSelect;

  const _Buildings(this.gridWith, this.gridSize, this.buildings, this.disabled,
      this.selected, this.onSelect,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gridWith,
      height: gridWith,
      child: Row(
          children: List.generate(
        gridSize,
        (j) => Column(
            children: List.generate(gridSize, (i) {
          final b = buildings[i][j];
          return GestureDetector(
            onTap: b == null ? null : () => onSelect(b),
            child: Container(
                width: gridWith / gridSize,
                height: gridWith / gridSize,
                decoration: BoxDecoration(
                    color: b == null
                        ? null
                        : disabled
                            ? Colors.grey
                            : b.type
                                .color()
                                .withOpacity(b.id == selected?.id ? 1 : 0.6))),
          );
        })),
      )),
    );
  }
}

typedef _MergedBuildings = List<List<Building?>>;

_MergedBuildings _merge(List<Building> l, int gridSize) {
  final out = List.generate(
      gridSize, (index) => List<Building?>.filled(gridSize, null));
  for (var item in l) {
    for (var square in item.squares) {
      out[square.x][square.y] = item;
    }
  }
  return out;
}

class _BuildingCard extends StatelessWidget {
  final Building building;

  const _BuildingCard(this.building, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: building.type.color().withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(buildingProperties[building.type.index].name,
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
