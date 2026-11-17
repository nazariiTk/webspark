import 'package:equatable/equatable.dart';
import 'package:webspark_pathfinder/domain/entities/grid_point.dart';

/// Represents a validated square 2D grid map of accesible and blocked cells
class GridMap extends Equatable {
  static const List<(int dx, int dy)> _directions = [
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
  ];

  /// Immutable list of grid rows ordered from top to bottom
  final List<String> rawRows;

  /// Creates a [GridMap] after validating that dimensions are square and strictly between 1 and 100
  GridMap(List<String> rows) : rawRows = _validateAndFreeze(rows);

  static List<String> _validateAndFreeze(List<String> rows) {
    final rowCount = rows.length;
    if (rowCount <= 1 || rowCount >= 100) {
      throw ArgumentError.value(
        rowCount,
        'rows',
        'Grid size must be greater than 1 and less than 100',
      );
    }

    for (var y = 0; y < rowCount; y++) {
      if (rows[y].length != rowCount) {
        throw ArgumentError(
          'Grid must be square (${rowCount}x$rowCount), '
          'but row $y has length ${rows[y].length}.',
        );
      }
    }

    return List.unmodifiable(rows);
  }

  /// Side length of the square grid
  int get size => rawRows.length;

  /// Returns true when [point] lies within [0, size) on both axes
  bool isInside(GridPoint point) =>
      point.x >= 0 && point.x < size && point.y >= 0 && point.y < size;

  /// Returns true when the cell at [point] is blocked
  bool isBlocked(GridPoint point) {
    if (!isInside(point)) {
      throw RangeError('Point $point is outside the ${size}x$size grid.');
    }
    return rawRows[point.y][point.x].toUpperCase() == 'X';
  }

  /// Returns all 8-directional neighbor points of [point] that are inside the grid and not blocked
  List<GridPoint> getAccessibleNeighbors(GridPoint point) {
    final neighbors = <GridPoint>[];
    for (final (dx, dy) in _directions) {
      final neighbor = GridPoint(point.x + dx, point.y + dy);
      if (isInside(neighbor) && !isBlocked(neighbor)) {
        neighbors.add(neighbor);
      }
    }
    return neighbors;
  }

  @override
  List<Object?> get props => [rawRows];
}
