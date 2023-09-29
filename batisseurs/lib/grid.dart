import 'package:batisseurs/logic/grid.dart';
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

  final void Function(Shape) onBuild;

  const Grid(this.gridSize, this.buildings, this.toPlace, this.onBuild,
      {super.key});

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  Building? selected;
  Shape? shapeToPlace;
  Color gridColor = Colors.grey;

  List<List<bool>> crible = [];

  @override
  void initState() {
    _initToPlace();
    _buildCrible();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Grid oldWidget) {
    _initToPlace();
    _buildCrible();
    super.didUpdateWidget(oldWidget);
  }

  _buildCrible() {
    final crible = matrix(widget.gridSize, false);
    for (var shape in widget.buildings) {
      for (var coord in shape.squares) {
        crible[coord.x][coord.y] = true;
      }
    }
    this.crible = crible;
  }

  _initToPlace() {
    if (widget.toPlace == null) {
      shapeToPlace = null;
    } else {
      shapeToPlace = buildingProperties[widget.toPlace!.index]
          .shape
          .centerOnGrid(widget.gridSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (shapeToPlace != null)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Choisis l'emplacement"),
                  Text(
                    "Tu peux cliquer pour faire tourner le bâtiment",
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
                  )
                ],
              ),
              ElevatedButton(
                  onPressed: shapeToPlace!.mayFit(crible, widget.gridSize)
                      ? () => widget.onBuild(shapeToPlace!)
                      : null,
                  child: const Text("Construire"))
            ]),
          LayoutBuilder(builder: (context, constraints) {
            final gridWidth = constraints.biggest.shortestSide;
            return Stack(children: [
              _GridBackground(gridWidth, widget.gridSize, gridColor),
              _Buildings(
                  gridWidth,
                  widget.gridSize,
                  _merge(widget.buildings, widget.gridSize),
                  widget.toPlace != null,
                  selected,
                  (b) => setState(() {
                        selected = b;
                      })),
              if (shapeToPlace != null)
                _ToPlaceBuilding(gridWidth, widget.gridSize, shapeToPlace!,
                    _onMoveToPlace, _onDropToPlace, _onRotateToPlace)
            ]);
          }),
          if (selected != null) _BuildingCard(selected!),
        ],
      ),
    );
  }

  _onMoveToPlace(Shape shape) {
    final ok = shape.mayFit(crible, widget.gridSize);
    setState(() {
      gridColor = ok ? Colors.green : Colors.red;
    });
  }

  _onDropToPlace(Shape shape) {
    final ok = shape.mayFit(crible, widget.gridSize);
    setState(() {
      gridColor = Colors.grey;
      if (!ok) return;
      shapeToPlace = shape;
    });
  }

  _onRotateToPlace() {
    setState(() {
      shapeToPlace = shapeToPlace!.rotate();
    });
  }
}

class _GridBackground extends StatelessWidget {
  final double gridWith;
  final int gridSize;
  final Color color;
  const _GridBackground(this.gridWith, this.gridSize, this.color, {super.key});

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
              decoration:
                  BoxDecoration(border: Border.all(width: 0.5, color: color))),
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
        (i) => Column(
            children: List.generate(gridSize, (j) {
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

class _FitBuilding extends StatelessWidget {
  final double cellSize;
  final Shape shape;

  const _FitBuilding(this.cellSize, this.shape, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SizedBox(width: cellSize * shape.size(), height: cellSize * shape.size()),
      ...shape.map(
        (e) => Positioned(
          left: e.x * cellSize,
          top: e.y * cellSize,
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                border: Border.all(
                    color: Colors.blue,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignCenter),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.blueAccent, blurRadius: 5, spreadRadius: 1),
                  BoxShadow(color: Colors.blue, blurRadius: 4, spreadRadius: 2),
                ]),
          ),
        ),
      ),
      ...shape.map(
        (e) => Positioned(
          left: e.x * cellSize,
          top: e.y * cellSize,
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ToPlaceBuilding extends StatelessWidget {
  final double gridWidth;
  final int gridSize;

  final Shape shape;

  final void Function(Shape) onMove; // the new shape
  final void Function(Shape) onDrop; // the new shape
  final void Function() onRotate; // the new shape

  const _ToPlaceBuilding(this.gridWidth, this.gridSize, this.shape, this.onMove,
      this.onDrop, this.onRotate,
      {super.key});

  @override
  Widget build(BuildContext context) {
    final cellSize = gridWidth / gridSize;
    final minC = shape.minC;
    final innerShape = shape.translate(-minC.x, -minC.y);

    return DragTarget(
      onAcceptWithDetails: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.offset);
        final tx = (offset.dx / cellSize).round();
        final ty = (offset.dy / cellSize).round();
        onDrop(innerShape.translate(tx, ty));
      },
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.offset);
        final tx = (offset.dx / cellSize).round();
        final ty = (offset.dy / cellSize).round();
        onMove(innerShape.translate(tx, ty));
      },
      builder: (context, candidateData, rejectedData) => Stack(
        children: [
          SizedBox(width: gridWidth, height: gridWidth),
          Positioned(
            left: cellSize * minC.x,
            top: cellSize * minC.y,
            child: GestureDetector(
              onTap: onRotate,
              child: Draggable(
                  data: 1,
                  feedback: _FitBuilding(cellSize, innerShape),
                  child: _FitBuilding(cellSize, innerShape)),
            ),
          )
        ],
      ),
    );
  }
}

typedef _MergedBuildings = List<List<Building?>>;

_MergedBuildings _merge(List<Building> l, int gridSize) {
  final out = matrix<Building?>(gridSize, null);
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
