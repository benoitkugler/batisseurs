import 'dart:io';

import 'package:batisseurs/logic/grid.dart';
import 'package:batisseurs/logic/models.dart';
import 'package:batisseurs/logic/theme.dart';

const _template = """
<html>
  <style>
    table {
      border: 1px solid black;
      border-collapse: collapse;
      font-size: 22;
    }

    th {
      padding: 12px 6px;
    }

    td,
    th {
      border: 1px solid black;
      text-align: center;
      padding: 4px 4px;
    }

    th > img {
      width: 50px;
      height: 50px;
    }
    td > img {
      width: 20px;
      height: 20px;
    }

    /* Shapes */
    table.shape {
      border: transparent;
      display: inline-block;
    }

    table.shape td {
      padding: 0px;
      margin: 0px;
      width: 20px;
      height: 20px;
    }

    td.cell-on {
      border: 1px solid black;
    }

    td.cell-off {
      border: transparent;
    }
  </style>
  <body>
    __tables__
  </body>
</html>
""";

const _tableTemplate1 = """
  <h2>Liste des bâtiments</h2>

  <table style='margin: auto'>
    <tr style="background-color: lightblue">
      <th colspan="6">Bâtiments à points de victoire</th>
    </tr>
    <tr style="background-color: lightblue">
      <th rowspan="2">Nom</th>
      <th>Gain</th>
      <th colspan="3">Coût</th>
      <th rowspan="2">Forme</th>
    </tr>
    <tr style="background-color: lightblue">
      <th><img src="assets/victory.png"/></th>
      <th><img src="__r1__"/></th>
      <th><img src="__r2__"/></th>
      <th><img src="__r3__"/></th>
    </tr>
    __rows__
  </table>

  <div style="break-after: page"></div>
""";

const _tableTemplate2 = """
  <h2>Liste des bâtiments</h2>

  <table style='margin: auto'>
    <tr style="background-color: lightgreen">
      <th colspan="6">Bâtiments à ressources</th>
    </tr>
    <tr style="background-color: lightgreen">
      <th rowspan="2">Nom</th>
      <th rowspan="2">Gain</th>
      <th colspan="3">Coût</th>
      <th rowspan="2">Forme</th>
    </tr>
    <tr style="background-color: lightgreen">
      <th><img src="__r1__"/></th>
      <th><img src="__r2__"/></th>
      <th><img src="__r3__"/></th>
    </tr>
    __rows__
  </table>

  <div style="break-after: page"></div>
""";

String _buildingCostsHTML(GameTheme theme) {
  final t1 = _table(
      _tableTemplate1, List.generate(14, (i) => BuildingType.values[i]), theme);
  final t2 = _table(_tableTemplate2,
      List.generate(12, (i) => BuildingType.values[14 + i]), theme);
  return _template.replaceFirst("__tables__", "$t1 $t2");
}

String _table(String template, List<BuildingType> buildings, GameTheme theme) {
  final rows = buildings.map((v) => v.rowHTML(theme)).join("\n");
  return template
      .replaceFirst("__r1__", theme.r1.path)
      .replaceFirst("__r2__", theme.r2.path)
      .replaceFirst("__r3__", theme.r3.path)
      .replaceFirst("__rows__", rows);
}

void exportBuildingCosts(GameTheme theme) {
  final file = File("${Directory.current.path}/buildings_${theme.name}.html");
  file.writeAsString(_buildingCostsHTML(theme));
}

extension on BuildingType {
  String rowHTML(GameTheme theme) {
    final props = buildingProperties[index];
    return """
    <tr>
        <td style="text-align: left">${theme.buildingNames[index]}</td>
        <td>${props.effect.toHTML()}</td>
        <td>${props.cost.wood}</td>
        <td>${props.cost.mud}</td>
        <td>${props.cost.stone}</td>
        <td>${props.shape.toHTML()}</td>
      </tr>
    """;
  }
}

extension on BuildingEffect {
  String toHTML() {
    final concrete = this;
    switch (concrete) {
      case VictoryPointEffect():
        return "${concrete.points}";
      case BonusCupEffect():
        return List.generate(
            concrete.cups, (_) => "<img src='assets/cup.png' />").join("");
      case ContremaitreEffect():
        return List.generate(concrete.contremaitres,
            (_) => "<img src='assets/contremaitre.png' />").join("");
      case AttackEffect():
        return List.generate(
            concrete.attack, (_) => "<img src='assets/swords.png' />").join("");
      case DefenseEffect():
        return List.generate(
                concrete.defense, (_) => "<img src='assets/shield.png' />")
            .join("");
      case ReserveEffect():
        return List.generate(
            concrete.stock, (_) => "<img src='assets/reserve.png' />").join("");
    }
  }
}

extension on Shape {
  String toHTML() {
    final byCell = crible();
    final nbColumns = byCell.length;
    final nbRows = byCell[0].length;
    final cells = List.generate(nbRows, (row) {
      final content = List.generate(
              nbColumns,
              (column) =>
                  "<td class='${byCell[column][row] ? 'cell-on' : 'cell-off'}'></td>")
          .join("");
      return "<tr>$content</tr>";
    }).join("\n");
    return """
    <table class='shape'>
      $cells
    </table>
    """;
  }
}
