import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webspark_pathfinder/data/services/webspark_api_service.dart';
import 'package:webspark_pathfinder/domain/entities/path_solution.dart';
import 'package:webspark_pathfinder/domain/services/shortest_path_finder.dart';
import 'package:webspark_pathfinder/presentation/cubit/process_state.dart';

class ProcessCubit extends Cubit<ProcessState> {
  ProcessCubit({
    required this._apiService,
    required this._pathFinder,
  }) : super(const ProcessState());

  final WebsparkApiService _apiService;
  final PathFinder _pathFinder;

  Future<void> startProcess(String apiUrl) async {
    if (isClosed) return;
    emit(
      const ProcessState(
        status: ProcessStatus.fetchingTasks,
        progress: 0.0,
      ),
    );

    try {
      final tasks = await _apiService.fetchTasks(apiUrl);
      if (isClosed) return;

      if (tasks.isEmpty) {
        emit(
          state.copyWith(
            status: ProcessStatus.calculationFinished,
            progress: 1.0,
            solutions: const [],
            clearError: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ProcessStatus.calculating,
          progress: 0.0,
          clearError: true,
        ),
      );

      final calculatedSolutions = <PathSolution>[];
      final totalTasks = tasks.length;

      for (var i = 0; i < totalTasks; i++) {
        if (isClosed) return;
        final task = tasks[i];
        final steps = _pathFinder.findShortestPath(
          grid: task.grid,
          start: task.start,
          end: task.end,
        );
        calculatedSolutions.add(PathSolution(task: task, steps: steps));

        // Short delay so the user visually sees percentage updates from 0% to 100%
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (isClosed) return;

        final progress = (i + 1) / totalTasks;
        emit(
          state.copyWith(
            status: ProcessStatus.calculating,
            progress: progress,
            solutions: List.unmodifiable(calculatedSolutions),
          ),
        );
      }

      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProcessStatus.calculationFinished,
          progress: 1.0,
          solutions: List.unmodifiable(calculatedSolutions),
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProcessStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProcessStatus.failure,
          errorMessage: 'Unexpected error: $e',
        ),
      );
    }
  }

  Future<void> sendResults(String apiUrl) async {
    if (isClosed || !state.canSendResults) return;

    emit(
      state.copyWith(
        status: ProcessStatus.sendingResults,
        clearError: true,
      ),
    );

    try {
      await _apiService.sendSolutions(apiUrl, state.solutions);
      if (isClosed) return;

      emit(
        state.copyWith(
          status: ProcessStatus.sendSuccess,
          clearError: true,
          navigationCount: state.navigationCount + 1,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProcessStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProcessStatus.failure,
          errorMessage: 'Failed to send results: $e',
        ),
      );
    }
  }
}
