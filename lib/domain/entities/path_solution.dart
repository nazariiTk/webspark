import 'package:equatable/equatable.dart';
import 'package:webspark_pathfinder/domain/entities/grid_point.dart';
import 'package:webspark_pathfinder/domain/entities/path_task.dart';

/// Represents the computed shortest-path solution for a [PathTask]
class PathSolution extends Equatable {
  /// The original task associated with this solution
  final PathTask task;

  /// Ordered immutable sequence of coordinates from start to end inclusive
  final List<GridPoint> steps;

  /// Human-readable and API-formatted path string (e.g. (1,2)->(2,1)->(2,0))
  final String formattedPath;

  /// Creates a [PathSolution] for [task] with the given [steps]
  PathSolution({required this.task, required List<GridPoint> steps})
    : steps = List.unmodifiable(steps),
      formattedPath = steps.map((p) => p.toCoordinateString()).join('->');

  /// Serializes this solution into the JSON structure required by the submission endpoint
  Map<String, dynamic> toSubmissionJson() {
    return {
      'id': task.id,
      'result': {
        'steps': steps.map((s) => s.toStepJson()).toList(),
        'path': formattedPath,
      },
    };
  }

  @override
  List<Object?> get props => [task, steps, formattedPath];
}
