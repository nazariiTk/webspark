import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:webspark_pathfinder/domain/entities/grid_map.dart';
import 'package:webspark_pathfinder/domain/entities/grid_point.dart';
import 'package:webspark_pathfinder/domain/entities/path_solution.dart';
import 'package:webspark_pathfinder/domain/entities/path_task.dart';
import 'package:webspark_pathfinder/domain/services/shortest_path_finder.dart';

void main() {
  group('GridPoint', () {
    test('fromJson parses both int and string coordinates', () {
      final fromInts = GridPoint.fromJson({'x': 1, 'y': 2});
      final fromStrings = GridPoint.fromJson({'x': '1', 'y': '2'});
      final fromMixed = GridPoint.fromJson({'x': 0, 'y': '3'});

      expect(fromInts, const GridPoint(1, 2));
      expect(fromStrings, const GridPoint(1, 2));
      expect(fromMixed, const GridPoint(0, 3));
      expect(fromInts, fromStrings);
      expect(fromInts.hashCode, fromStrings.hashCode);
    });

    test('fromJson throws FormatException on invalid coordinate values', () {
      expect(
        () => GridPoint.fromJson({'x': 'abc', 'y': 1}),
        throwsFormatException,
      );
      expect(
        () => GridPoint.fromJson({'x': 1.5, 'y': 1}),
        throwsFormatException,
      );
      expect(
        () => GridPoint.fromJson({'x': null, 'y': 1}),
        throwsFormatException,
      );
    });

    test('formats step JSON and coordinate strings accurately', () {
      const point = GridPoint(4, 7);

      expect(point.toStepJson(), {'x': '4', 'y': '7'});
      expect(point.toCoordinateString(), '(4,7)');
      expect(point.toString(), '(4,7)');
    });
  });

  group('GridMap', () {
    test('accepts valid boundary dimensions 2x2 and 99x99', () {
      final minGrid = GridMap(['..', '..']);
      expect(minGrid.size, 2);

      final maxRows = List.generate(99, (_) => '.' * 99);
      final maxGrid = GridMap(maxRows);
      expect(maxGrid.size, 99);
    });

    test('throws ArgumentError for invalid grid dimensions', () {
      expect(() => GridMap([]), throwsArgumentError);
      expect(() => GridMap(['.']), throwsArgumentError);
      expect(
        () => GridMap(List.generate(100, (_) => '.' * 100)),
        throwsArgumentError,
      );
      expect(() => GridMap(['..', '...']), throwsArgumentError);
      expect(() => GridMap(['...', '...']), throwsArgumentError);
      expect(() => GridMap(['...', '..', '...']), throwsArgumentError);
    });

    test('checks bounds, blocked cells case-insensitively, and neighbors', () {
      final grid = GridMap([
        '.x.',
        '.X.',
        '...',
      ]);

      expect(grid.isInside(const GridPoint(0, 0)), isTrue);
      expect(grid.isInside(const GridPoint(2, 2)), isTrue);
      expect(grid.isInside(const GridPoint(-1, 0)), isFalse);
      expect(grid.isInside(const GridPoint(0, -1)), isFalse);
      expect(grid.isInside(const GridPoint(3, 0)), isFalse);
      expect(grid.isInside(const GridPoint(0, 3)), isFalse);

      expect(grid.isBlocked(const GridPoint(1, 0)), isTrue);
      expect(grid.isBlocked(const GridPoint(1, 1)), isTrue);
      expect(grid.isBlocked(const GridPoint(0, 0)), isFalse);
      expect(() => grid.isBlocked(const GridPoint(3, 0)), throwsRangeError);

      expect(
        grid.getAccessibleNeighbors(const GridPoint(0, 0)),
        [const GridPoint(0, 1)],
      );
      expect(
        grid.getAccessibleNeighbors(const GridPoint(1, 2)),
        [
          const GridPoint(0, 1),
          const GridPoint(2, 1),
          const GridPoint(0, 2),
          const GridPoint(2, 2),
        ],
      );
    });

    test('freezes rawRows and supports value equality', () {
      final source = ['.X.', '.X.', '...'];
      final gridA = GridMap(source);
      source[0] = 'XXX';

      final gridB = GridMap(['.X.', '.X.', '...']);

      expect(gridA.rawRows[0], '.X.');
      expect(() => gridA.rawRows.add('...'), throwsUnsupportedError);
      expect(gridA, gridB);
    });
  });

  group('PathTask & PathSolution', () {
    test('PathTask.fromJson parses valid payload', () {
      final task = PathTask.fromJson({
        'id': '7d785c38-cd54-4a98-ab57-44e50ae646c1',
        'field': ['.X.', '.X.', '...'],
        'start': {'x': 2, 'y': 1},
        'end': {'x': '0', 'y': '2'},
      });

      expect(task.id, '7d785c38-cd54-4a98-ab57-44e50ae646c1');
      expect(task.grid, GridMap(['.X.', '.X.', '...']));
      expect(task.start, const GridPoint(2, 1));
      expect(task.end, const GridPoint(0, 2));
    });

    test('PathTask.fromJson throws FormatException on malformed fields', () {
      expect(
        () => PathTask.fromJson({
          'id': 123,
          'field': ['..', '..'],
          'start': {'x': 0, 'y': 0},
          'end': {'x': 1, 'y': 1},
        }),
        throwsFormatException,
      );
      expect(
        () => PathTask.fromJson({
          'id': 'abc',
          'field': 'invalid',
          'start': {'x': 0, 'y': 0},
          'end': {'x': 1, 'y': 1},
        }),
        throwsFormatException,
      );
    });

    test(
      'PathSolution.toSubmissionJson formats steps with x and y as Strings',
      () {
        final task = PathTask(
          id: 'task-1',
          grid: GridMap(['.X.', '.X.', '...']),
          start: const GridPoint(1, 2),
          end: const GridPoint(2, 0),
        );
        final solution = PathSolution(
          task: task,
          steps: const [
            GridPoint(1, 2),
            GridPoint(2, 1),
            GridPoint(2, 0),
          ],
        );

        final json = solution.toSubmissionJson();
        expect(json, {
          'id': 'task-1',
          'result': {
            'steps': [
              {'x': '1', 'y': '2'},
              {'x': '2', 'y': '1'},
              {'x': '2', 'y': '0'},
            ],
            'path': '(1,2)->(2,1)->(2,0)',
          },
        });

        final result = json['result'] as Map<String, dynamic>;
        final steps = result['steps'] as List<Map<String, String>>;
        for (final step in steps) {
          expect(step['x'], isA<String>());
          expect(step['y'], isA<String>());
        }

        expect(
          () => solution.steps.add(const GridPoint(0, 0)),
          throwsUnsupportedError,
        );
      },
    );
  });

  group('BfsShortestPathFinder', () {
    const PathFinder finder = BfsShortestPathFinder();

    test('solves PDF example correctly', () {
      final task = PathTask(
        id: 'pdf-example',
        grid: GridMap([
          '.X.',
          '.X.',
          '...',
        ]),
        start: const GridPoint(1, 2),
        end: const GridPoint(2, 0),
      );

      final steps = finder.findShortestPath(
        grid: task.grid,
        start: task.start,
        end: task.end,
      );
      final solution = PathSolution(task: task, steps: steps);

      expect(steps, const [
        GridPoint(1, 2),
        GridPoint(2, 1),
        GridPoint(2, 0),
      ]);
      expect(solution.formattedPath, '(1,2)->(2,1)->(2,0)');
    });

    test('solves Live API example 1 correctly', () {
      final task = PathTask(
        id: 'live-api-1',
        grid: GridMap([
          '.X.',
          '.X.',
          '...',
        ]),
        start: const GridPoint(2, 1),
        end: const GridPoint(0, 2),
      );

      final steps = finder.findShortestPath(
        grid: task.grid,
        start: task.start,
        end: task.end,
      );
      final solution = PathSolution(task: task, steps: steps);

      expect(steps, const [
        GridPoint(2, 1),
        GridPoint(1, 2),
        GridPoint(0, 2),
      ]);
      expect(solution.formattedPath, '(2,1)->(1,2)->(0,2)');
    });

    test('solves Live API example 2 correctly', () {
      final task = PathTask(
        id: 'live-api-2',
        grid: GridMap([
          'XXX.',
          'X..X',
          'X..X',
          '.XXX',
        ]),
        start: const GridPoint(0, 3),
        end: const GridPoint(3, 0),
      );

      final steps = finder.findShortestPath(
        grid: task.grid,
        start: task.start,
        end: task.end,
      );
      final solution = PathSolution(task: task, steps: steps);

      expect(steps, const [
        GridPoint(0, 3),
        GridPoint(1, 2),
        GridPoint(2, 1),
        GridPoint(3, 0),
      ]);
      expect(solution.formattedPath, '(0,3)->(1,2)->(2,1)->(3,0)');
    });

    test('returns single-element path when start == end', () {
      final grid = GridMap([
        '.X.',
        '.X.',
        '...',
      ]);

      final steps = finder.findShortestPath(
        grid: grid,
        start: const GridPoint(0, 0),
        end: const GridPoint(0, 0),
      );

      expect(steps, const [GridPoint(0, 0)]);
    });

    test('throws StateError when target is unreachable', () {
      final grid = GridMap([
        '.X.',
        'XX.',
        '...',
      ]);

      expect(
        () => finder.findShortestPath(
          grid: grid,
          start: const GridPoint(0, 0),
          end: const GridPoint(2, 2),
        ),
        throwsStateError,
      );
    });

    test('throws ArgumentError when start or end is outside or blocked', () {
      final grid = GridMap([
        '.X.',
        '.X.',
        '...',
      ]);

      expect(
        () => finder.findShortestPath(
          grid: grid,
          start: const GridPoint(-1, 0),
          end: const GridPoint(2, 2),
        ),
        throwsArgumentError,
      );
      expect(
        () => finder.findShortestPath(
          grid: grid,
          start: const GridPoint(0, 0),
          end: const GridPoint(3, 2),
        ),
        throwsArgumentError,
      );
      expect(
        () => finder.findShortestPath(
          grid: grid,
          start: const GridPoint(1, 0),
          end: const GridPoint(2, 2),
        ),
        throwsArgumentError,
      );
      expect(
        () => finder.findShortestPath(
          grid: grid,
          start: const GridPoint(0, 0),
          end: const GridPoint(1, 1),
        ),
        throwsArgumentError,
      );
    });

    test('finds optimal path around multi-wall obstacles', () {
      final grid = GridMap([
        '.X...',
        '.X.X.',
        '.X.X.',
        '.X.X.',
        '...X.',
      ]);
      const start = GridPoint(0, 0);
      const end = GridPoint(4, 4);

      final steps = finder.findShortestPath(
        grid: grid,
        start: start,
        end: end,
      );

      expect(steps.first, start);
      expect(steps.last, end);
      // Optimal detour: (0,0)->(0,1)->(0,2)->(0,3)->(1,4)->(2,3)->(2,2)->(2,1)->(3,0)->(4,1)->(4,2)->(4,3)->(4,4) = 13 nodes
      expect(steps.length, 13);

      for (var i = 0; i < steps.length; i++) {
        expect(grid.isInside(steps[i]), isTrue);
        expect(grid.isBlocked(steps[i]), isFalse);
        if (i > 0) {
          final dx = (steps[i].x - steps[i - 1].x).abs();
          final dy = (steps[i].y - steps[i - 1].y).abs();
          expect(math.max(dx, dy), 1);
        }
      }
    });

    test('handles 99x99 grid efficiently', () {
      final grid = GridMap(List.generate(99, (_) => '.' * 99));
      const start = GridPoint(0, 0);
      const end = GridPoint(98, 98);

      final steps = finder.findShortestPath(
        grid: grid,
        start: start,
        end: end,
      );

      expect(steps.length, 99);
      expect(steps.first, start);
      expect(steps.last, end);
    });
  });
}
