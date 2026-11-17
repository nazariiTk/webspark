import 'package:equatable/equatable.dart';
import 'package:webspark_pathfinder/domain/entities/path_solution.dart';

enum ProcessStatus {
  fetchingTasks,
  calculating,
  calculationFinished,
  sendingResults,
  sendSuccess,
  failure,
}

class ProcessState extends Equatable {
  const ProcessState({
    this.status = ProcessStatus.fetchingTasks,
    this.progress = 0.0,
    this.solutions = const [],
    this.errorMessage,
    this.navigationCount = 0,
  });

  final ProcessStatus status;
  final double progress;
  final List<PathSolution> solutions;
  final String? errorMessage;
  final int navigationCount;

  int get progressPercent => (progress * 100).round().clamp(0, 100);

  bool get isCalculationDone =>
      status == ProcessStatus.calculationFinished ||
      status == ProcessStatus.sendingResults ||
      status == ProcessStatus.sendSuccess ||
      (status == ProcessStatus.failure && progress >= 1.0 && solutions.isNotEmpty);

  bool get canSendResults =>
      status == ProcessStatus.calculationFinished ||
      (status == ProcessStatus.failure && progress >= 1.0 && solutions.isNotEmpty);

  ProcessState copyWith({
    ProcessStatus? status,
    double? progress,
    List<PathSolution>? solutions,
    String? errorMessage,
    bool clearError = false,
    int? navigationCount,
  }) {
    return ProcessState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      solutions: solutions ?? this.solutions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      navigationCount: navigationCount ?? this.navigationCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        progress,
        solutions,
        errorMessage,
        navigationCount,
      ];
}
