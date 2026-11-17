import 'dart:collection';

import 'package:webspark_pathfinder/domain/entities/grid_map.dart';
import 'package:webspark_pathfinder/domain/entities/grid_point.dart';

abstract interface class PathFinder {
  List<GridPoint> findShortestPath({
    required GridMap grid,
    required GridPoint start,
    required GridPoint end,
  });
}

/// Breadth-First Search implementation of [PathFinder] allowing 8-directional movement.
class BfsShortestPathFinder implements PathFinder {
  const BfsShortestPathFinder();

  @override
  List<GridPoint> findShortestPath({
    required GridMap grid,
    required GridPoint start,
    required GridPoint end,
  }) {
    _validateEndpoints(grid: grid, start: start, end: end);

    if (start == end) {
      return [start];
    }

    final queue = Queue<GridPoint>()..add(start);
    final parentMap = <GridPoint, GridPoint?>{start: null};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      for (final neighbor in grid.getAccessibleNeighbors(current)) {
        if (parentMap.containsKey(neighbor)) {
          continue;
        }
        parentMap[neighbor] = current;

        // First discovery in unweighted BFS guarantees a shortest path.
        if (neighbor == end) {
          return _reconstructPath(parentMap, end);
        }
        queue.add(neighbor);
      }
    }

    throw StateError('No accessible path found from $start to $end.');
  }

  void _validateEndpoints({
    required GridMap grid,
    required GridPoint start,
    required GridPoint end,
  }) {
    if (!grid.isInside(start)) {
      throw ArgumentError.value(
        start,
        'start',
        'Start point $start is outside the ${grid.size}x${grid.size} grid.',
      );
    }
    if (!grid.isInside(end)) {
      throw ArgumentError.value(
        end,
        'end',
        'End point $end is outside the ${grid.size}x${grid.size} grid.',
      );
    }
    if (grid.isBlocked(start)) {
      throw ArgumentError.value(
        start,
        'start',
        'Start point $start is blocked.',
      );
    }
    if (grid.isBlocked(end)) {
      throw ArgumentError.value(end, 'end', 'End point $end is blocked.');
    }
  }

  List<GridPoint> _reconstructPath(
    Map<GridPoint, GridPoint?> parentMap,
    GridPoint end,
  ) {
    final reversedPath = <GridPoint>[];
    GridPoint? cursor = end;
    while (cursor != null) {
      reversedPath.add(cursor);
      cursor = parentMap[cursor];
    }
    return reversedPath.reversed.toList();
  }
}
