import 'dart:math';

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

typedef Shape = List<Coord>;

extension Bs on Shape {
  /// [mayFit] returns true if all squares are available
  bool mayFit(List<List<bool>> crible, int gridSize) {
    return every((coord) =>
        coord.x >= 0 &&
        coord.x < gridSize &&
        coord.y >= 0 &&
        coord.y < gridSize &&
        !crible[coord.x][coord.y]);
  }

  Coord get minC {
    int minX = 1000;
    int minY = 1000;
    for (var element in this) {
      if (element.x < minX) {
        minX = element.x;
      }
      if (element.y < minY) {
        minY = element.y;
      }
    }
    return Coord(minX, minY);
  }

  Coord get maxC {
    int maxX = -1000;
    int maxY = -1000;
    for (var element in this) {
      if (element.x > maxX) {
        maxX = element.x;
      }
      if (element.y > maxY) {
        maxY = element.y;
      }
    }
    return Coord(maxX, maxY);
  }

  /// intrinsic size of the shape
  int size() {
    return max(maxC.x - minC.x + 1, maxC.y - minC.y + 1);
  }

  Shape translate(int tx, int ty) {
    return map((e) => Coord(e.x + tx, e.y + ty)).toList();
  }

  /// [centerOnGrid] returns a new shape,
  /// centered in the middle of the given grid [0, gridSize-1]
  Shape centerOnGrid(int gridSize) {
    final c = _barycentre(_centers());
    final tr = Offset(gridSize / 2, gridSize / 2) - c;
    // round
    final tx = tr.dx.round();
    final ty = tr.dy.round();

    return translate(tx, ty);
  }

  static Shape _fromCenters(Iterable<Offset> centers) {
    return centers
        .map((e) => Coord((e.dx - 0.5).round(), (e.dy - 0.5).toInt()))
        .toList();
  }

  List<Offset> _centers() =>
      map((c) => Offset(c.x + 0.5, c.y + 0.5)).toList(growable: false);

  Offset _barycentre(List<Offset> centers) {
    Offset barycentre = Offset.zero;
    for (var point in centers) {
      barycentre = barycentre + point;
    }
    return barycentre.scale(1 / centers.length, 1 / centers.length);
  }

  /// [rotate] return the same shape, with
  /// -90° rotation applied
  /// The shape may not fit into the standard grid
  Shape rotate() {
    final cs = _centers();
    Offset barycentre = _barycentre(cs);
    // round to half integers
    barycentre = barycentre.scale(2, 2);
    barycentre =
        Offset(barycentre.dx.roundToDouble(), barycentre.dy.roundToDouble());
    barycentre = barycentre.scale(1 / 2, 1 / 2);
    // perform the rotation (x, y) -> (-y, x) centered at the barycentre
    final rotatedCenters = cs.map((point) {
      final tmp = point - barycentre;
      final rotated = Offset(-tmp.dy, tmp.dx);
      return rotated + barycentre;
    });
    return _fromCenters(rotatedCenters);
  }
}

List<List<T>> matrix<T>(int gridSize, T zero) {
  return List.generate(gridSize, (index) => List<T>.filled(gridSize, zero),
      growable: false);
}
