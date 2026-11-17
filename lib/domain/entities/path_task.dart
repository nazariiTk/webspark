import 'package:equatable/equatable.dart';
import 'package:webspark_pathfinder/domain/entities/grid_map.dart';
import 'package:webspark_pathfinder/domain/entities/grid_point.dart';

/// Represents a single pathfinding task received from the API
class PathTask extends Equatable {
  /// Unique identifier of the task
  final String id;

  /// Validated square grid map for this task
  final GridMap grid;

  /// Starting coordinate on [grid]
  final GridPoint start;

  /// Destination coordinate on [grid]
  final GridPoint end;

  /// Creates an immutable [PathTask]
  const PathTask({
    required this.id,
    required this.grid,
    required this.start,
    required this.end,
  });

  /// Parses a [PathTask] from an API JSON object
  factory PathTask.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) {
      throw FormatException('Invalid or missing "id": $id');
    }

    final rawField = json['field'];
    if (rawField is! List) {
      throw const FormatException('Expected "field" to be a List');
    }
    final rows = rawField.map((row) {
      if (row is! String) {
        throw FormatException('Expected String row in "field", got $row');
      }
      return row;
    }).toList();

    final startJson = json['start'];
    final endJson = json['end'];
    if (startJson is! Map || endJson is! Map) {
      throw const FormatException(
        'Expected "start" and "end" to be JSON objects',
      );
    }

    return PathTask(
      id: id,
      grid: GridMap(rows),
      start: GridPoint.fromJson(Map<String, dynamic>.from(startJson)),
      end: GridPoint.fromJson(Map<String, dynamic>.from(endJson)),
    );
  }

  @override
  List<Object?> get props => [id, grid, start, end];
}
