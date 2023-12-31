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

class ShapePreview extends StatelessWidget {
  final Shape shape;
  const ShapePreview(this.shape, {super.key});

  @override
  Widget build(BuildContext context) {
    final minC = shape.upperLeftCell;
    final innerShape = shape.translate(-minC.x, -minC.y);
    return _FitBuilding(20, innerShape, true, false, Colors.yellow);
  }
}

class TeamGrid extends StatefulWidget {
  final TeamExt team;

  final int gridSize;
  final bool allowDuplicateBuildings;

  final void Function(BuildingType, Shape) onBuild;
  final void Function(Building) onDelete;

  const TeamGrid(this.team, this.gridSize, this.allowDuplicateBuildings,
      this.onBuild, this.onDelete,
      {super.key});

  @override
  State<TeamGrid> createState() => _TeamGridState();
}

class _TeamGridState extends State<TeamGrid> {
  BuildingType? toPlace;
  Shape? shapeToPlace;

  Building? selected;
  Color gridColor = Colors.grey;

  List<List<bool>> crible = [];

  @override
  void initState() {
    _buildCrible();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TeamGrid oldWidget) {
    _buildCrible();
    super.didUpdateWidget(oldWidget);
  }

  _buildCrible() {
    final crible = matrix(widget.gridSize, false);
    for (var shape in widget.team.buildings) {
      for (var coord in shape.squares) {
        crible[coord.x][coord.y] = true;
      }
    }
    this.crible = crible;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (toPlace != null) ...[
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Choisis l'emplacement"),
                    Text(
                      "Tu peux cliquer pour faire tourner le bâtiment",
                      style:
                          TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
                    )
                  ],
                ),
                const Spacer(),
                IconButton(
                    onPressed: () => setState(() {
                          toPlace = null;
                          shapeToPlace = null;
                        }),
                    icon: const Icon(Icons.clear))
              ],
              ElevatedButton(
                  onPressed: toPlace == null
                      ? _showBuildings
                      : _isBuildingValid()
                          ? _onBuild
                          : null,
                  child:
                      Text(toPlace == null ? "Construire un bâtiment" : "OK"))
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final gridWidth = constraints.biggest.shortestSide;
              return Stack(children: [
                _GridBackground(gridWidth, widget.gridSize, gridColor),
                _Buildings(
                    gridWidth,
                    widget.gridSize,
                    _merge(widget.team.buildings, widget.gridSize),
                    toPlace != null,
                    selected,
                    (b) => setState(() {
                          selected = b;
                        })),
                if (shapeToPlace != null)
                  _ToPlaceBuilding(gridWidth, widget.gridSize, shapeToPlace!,
                      _onMoveToPlace, _onDropToPlace, _onRotateToPlace)
              ]);
            }),
          ),
          if (selected != null) _BuildingSummary(selected!, _confirmDelete),
        ],
      ),
    );
  }

  _confirmDelete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Supprimer le bâtiment"),
                content:
                    const Text("Confirmez-vous la suppression du batîment ?"),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style:
                        ElevatedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Supprimer"),
                  )
                ]));
    if ((ok ?? false) && selected != null) {
      widget.onDelete(selected!);

      setState(() {
        selected = null;
      });
    }
  }

  _showBuildings() async {
    final t = widget.team.team;
    final currentBuildings = widget.team.buildings.map((e) => e.type).toSet();
    final toBuild = await showDialog<BuildingType>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
        title: const Text("Que construire ?"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
              itemCount: BuildingType.values.length,
              itemBuilder: (context, index) {
                final e = BuildingType.values[index];
                final prop = buildingProperties[e.index];
                final hasResources =
                    prop.cost.isSatisfied(t.wood, t.mud, t.stone);
                final isDupOK = widget.allowDuplicateBuildings ||
                    !currentBuildings.contains(e);
                return _BuildingCard(e, prop, hasResources && isDupOK,
                    () => Navigator.of(context).pop(e));
              }),
        ),
      ),
    );

    if (toBuild == null) return;

    setState(() {
      toPlace = toBuild;
      // start with the shape in the center
      shapeToPlace =
          buildingProperties[toBuild.index].shape.centerOnGrid(widget.gridSize);
    });
  }

  bool _isBuildingValid() => shapeToPlace!.mayFit(crible, widget.gridSize);

  _onBuild() {
    widget.onBuild(toPlace!, shapeToPlace!);
    toPlace = null;
    shapeToPlace = null;
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
  final bool border;
  final bool shadow;
  final Color color;

  const _FitBuilding(
      this.cellSize, this.shape, this.border, this.shadow, this.color,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SizedBox(width: cellSize * shape.size(), height: cellSize * shape.size()),
      if (shadow)
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
                      color: color,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignCenter),
                  boxShadow: [
                    BoxShadow(color: color, blurRadius: 4, spreadRadius: 2),
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
            decoration: BoxDecoration(
              border: border ? Border.all() : null,
              color: color,
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
    final minC = shape.upperLeftCell;
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
                  feedback: _FitBuilding(
                      cellSize, innerShape, false, false, Colors.blue),
                  child: _FitBuilding(
                      cellSize, innerShape, false, true, Colors.blue)),
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

class _BuildingSummary extends StatelessWidget {
  final Building building;
  final void Function() onDelete;

  const _BuildingSummary(this.building, this.onDelete, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onDelete,
      child: Card(
        color: building.type.color().withOpacity(0.8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(buildingProperties[building.type.index].name,
              style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final BuildingType type;
  final BuildingProperty prop;
  final bool enabled;
  final void Function() onTap;

  const _BuildingCard(this.type, this.prop, this.enabled, this.onTap,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      splashColor: type.color(),
      hoverColor: type.color().withOpacity(0.5),
      onTap: enabled ? onTap : null,
      child: Card(
        color: type.color().withOpacity(enabled ? 0.5 : 0.2),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prop.name,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: enabled ? Colors.black : Colors.black38),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ResourceIcon(
                      Image.asset("assets/wood.png"),
                      prop.cost.wood,
                      size: 25,
                    ),
                    ResourceIcon(Image.asset("assets/mud.png"), prop.cost.mud,
                        size: 25),
                    ResourceIcon(
                        Image.asset("assets/stone.png"), prop.cost.stone,
                        size: 25),
                  ])
                ],
              ),
              ShapePreview(prop.shape),
            ],
          ),
        ),
      ),
    );
  }
}

class ResourceIcon extends StatelessWidget {
  final Image image;
  final int amount;
  final double size;
  const ResourceIcon(this.image, this.amount, {this.size = 40, super.key});

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
