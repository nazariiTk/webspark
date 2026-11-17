import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:webspark_pathfinder/domain/entities/grid_point.dart';
import 'package:webspark_pathfinder/domain/entities/path_solution.dart';
import 'package:webspark_pathfinder/domain/entities/path_task.dart';

/// Renders the square grid with start, end, blocked, and shortest-path cells highlighted.
class PreviewScreen extends StatelessWidget {
  /// Creates a [PreviewScreen] visualizing [solution].
  const PreviewScreen({super.key, required this.solution});

  /// Shortest-path solution to render on the grid.
  final PathSolution solution;

  static const Color _startColor = Color(0xFF64FFDA);
  static const Color _endColor = Color(0xFF009688);
  static const Color _blockedColor = Color(0xFF000000);
  static const Color _pathColor = Color(0xFF4CAF50);
  static const Color _emptyColor = Color(0xFFFFFFFF);

  Widget _buildGridCell({
    required GridPoint point,
    required PathTask task,
    required Set<GridPoint> stepSet,
  }) {
    final isStart = point == task.start;
    final isEnd = point == task.end;
    final isBlocked = task.grid.isBlocked(point);
    final isPath = stepSet.contains(point);

    final Color cellColor;
    if (isStart) {
      cellColor = _startColor;
    } else if (isEnd) {
      cellColor = _endColor;
    } else if (isBlocked) {
      cellColor = _blockedColor;
    } else if (isPath) {
      cellColor = _pathColor;
    } else {
      cellColor = _emptyColor;
    }

    final useWhiteText = !isStart && !isEnd && isBlocked;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cellColor,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '(${point.x},${point.y})',
              style: TextStyle(
                color: useWhiteText ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid({
    required int size,
    required PathTask task,
    required Set<GridPoint> stepSet,
  }) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
      ),
      itemCount: size * size,
      itemBuilder: (context, index) {
        final x = index % size;
        final y = index ~/ size;
        return _buildGridCell(
          point: GridPoint(x, y),
          task: task,
          stepSet: stepSet,
        );
      },
    );
  }

  Widget _buildFormattedPath() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        solution.formattedPath,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = solution.task;
    final size = task.grid.size;
    final stepSet = solution.steps.toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Preview screen')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (size <= 12) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: _buildGrid(
                        size: size,
                        task: task,
                        stepSet: stepSet,
                      ),
                    ),
                    _buildFormattedPath(),
                  ],
                ),
              );
            }

            final cellSize = math.max(36.0, constraints.maxWidth / size);
            final gridExtent = cellSize * size;
            final pathMaxHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight * 0.3
                : 160.0;

            return Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(16),
                    minScale: 0.2,
                    maxScale: 4.0,
                    child: SizedBox(
                      width: gridExtent,
                      height: gridExtent,
                      child: _buildGrid(
                        size: size,
                        task: task,
                        stepSet: stepSet,
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: pathMaxHeight),
                  child: SingleChildScrollView(
                    child: _buildFormattedPath(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
