import 'package:flutter/widgets.dart';

class Coord {
  final int x;
  final int y;
  const Coord(this.x, this.y);

  @override
  int get hashCode => x + y;

  @override
  bool operator ==(Object other) {
    return (other is Coord) && other.x == x && other.y == y;
  }

  @override
  String toString() {
    return "Coord($x, $y)";
  }
}

typedef BuildingSquares = List<Coord>;

extension Bs on BuildingSquares {
  static BuildingSquares _fromCenters(Iterable<Offset> centers) {
    return centers
        .map((e) => Coord((e.dx - 0.5).round(), (e.dy - 0.5).toInt()))
        .toList();
  }

  List<Offset> _centers() =>
      map((c) => Offset(c.x + 0.5, c.y + 0.5)).toList(growable: false);

  /// [rotate] return the same shape, with
  /// -90° rotation applied
  /// The shape may not fit into the standard grid
  BuildingSquares rotate() {
    final cs = _centers();
    Offset barycentre = Offset.zero;
    for (var point in cs) {
      barycentre = barycentre + point;
    }
    barycentre = barycentre.scale(1 / cs.length, 1 / cs.length);
    // round to half integers
    barycentre = barycentre.scale(2, 2);
    barycentre =
        Offset(barycentre.dx.roundToDouble(), barycentre.dy.roundToDouble());
    barycentre = barycentre.scale(1 / 2, 1 / 2);
    // perform the rotation (x, y) -> (y, -x) centered at the barycentre
    final rotatedCenters = cs.map((point) {
      final tmp = point - barycentre;
      final rotated = Offset(tmp.dy, -tmp.dx);
      return rotated + barycentre;
    });
    return _fromCenters(rotatedCenters);
  }
}
