import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webspark_pathfinder/presentation/cubit/process_cubit.dart';
import 'package:webspark_pathfinder/presentation/cubit/process_state.dart';
import 'package:webspark_pathfinder/presentation/screens/result_list_screen.dart';

/// Displays task fetching, shortest-path calculation progress, and submission controls.
class ProcessScreen extends StatelessWidget {
  /// Creates a [ProcessScreen] bound to [apiUrl].
  const ProcessScreen({super.key, required this.apiUrl});

  /// Validated API base URL used for fetching tasks and submitting results.
  final String apiUrl;

  String _statusMessage(ProcessState state) {
    return switch (state.status) {
      ProcessStatus.fetchingTasks => 'Fetching tasks from server...',
      ProcessStatus.calculating => 'Calculating shortest paths...',
      ProcessStatus.calculationFinished ||
      ProcessStatus.sendSuccess =>
        'All calculations has finished, you can send your results to server',
      ProcessStatus.sendingResults => 'Sending results to server...',
      ProcessStatus.failure => state.errorMessage ?? 'An error occurred',
    };
  }

  Widget _buildBottomAction(BuildContext context, ProcessState state) {
    if (state.status == ProcessStatus.failure && !state.isCalculationDone) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.read<ProcessCubit>().startProcess(apiUrl),
            child: const Text('Retry'),
          ),
        ),
      );
    }

    if (state.isCalculationDone) {
      final isSending = state.status == ProcessStatus.sendingResults;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isSending
                ? null
                : () => context.read<ProcessCubit>().sendResults(apiUrl),
            child: isSending
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Sending...'),
                    ],
                  )
                : const Text('Send results to server'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Process screen')),
      body: SafeArea(
        child: BlocConsumer<ProcessCubit, ProcessState>(
          listenWhen: (prev, curr) =>
              prev.navigationCount != curr.navigationCount,
          listener: (context, state) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ResultListScreen(solutions: state.solutions),
              ),
            );
          },
          builder: (context, state) {
            final isIndeterminate =
                state.status == ProcessStatus.fetchingTasks ||
                state.status == ProcessStatus.sendingResults;

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _statusMessage(state),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: state.status == ProcessStatus.failure
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${state.progressPercent}%',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              value: isIndeterminate ? null : state.progress,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomAction(context, state),
              ],
            );
          },
        ),
      ),
    );
  }
}
