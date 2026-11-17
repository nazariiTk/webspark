import 'package:equatable/equatable.dart';

/// Represents a 2D coordinate on a grid where (0,0) is the top-left cell
class GridPoint extends Equatable {
  final int x;
  final int y;

  const GridPoint(this.x, this.y);

  /// Parses a [GridPoint] from a JSON map supporting both int and numeric String values
  factory GridPoint.fromJson(Map<String, dynamic> json) {
    return GridPoint(
      _parseCoordinate(json['x'], 'x'),
      _parseCoordinate(json['y'], 'y'),
    );
  }

  static int _parseCoordinate(dynamic value, String field) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.parse(value);
    }
    throw FormatException(
      'Invalid coordinate for "$field": expected int or numeric String, got $value.',
    );
  }

  /// Serializes this point to the step format expected by the API
  Map<String, String> toStepJson() => {'x': x.toString(), 'y': y.toString()};

  /// Formats this point as (x,y)
  String toCoordinateString() => '($x,$y)';

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => toCoordinateString();
}
