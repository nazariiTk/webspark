import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webspark_pathfinder/data/services/webspark_api_service.dart';
import 'package:webspark_pathfinder/domain/services/shortest_path_finder.dart';
import 'package:webspark_pathfinder/presentation/cubit/home_cubit.dart';
import 'package:webspark_pathfinder/presentation/cubit/home_state.dart';
import 'package:webspark_pathfinder/presentation/cubit/process_cubit.dart';
import 'package:webspark_pathfinder/presentation/screens/process_screen.dart';

/// Initial screen allowing the user to configure and submit the API base URL.
class HomeScreen extends StatefulWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isControllerInitialized = false;
  late int _lastSubmissionCount;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<HomeCubit>().state;
    _lastSubmissionCount = initialState.submissionCount;
    if (initialState.status == HomeStatus.ready) {
      _controller.text = initialState.url;
      _isControllerInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToProcessScreen(BuildContext context, String apiUrl) {
    final apiService = context.read<WebsparkApiService>();
    final pathFinder = context.read<PathFinder>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ProcessCubit>(
          create: (_) => ProcessCubit(
            apiService: apiService,
            pathFinder: pathFinder,
          )..startProcess(apiUrl),
          child: ProcessScreen(apiUrl: apiUrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home screen')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<HomeCubit, HomeState>(
            listenWhen: (prev, curr) =>
                prev.submissionCount != curr.submissionCount ||
                (!_isControllerInitialized && curr.status == HomeStatus.ready),
            listener: (context, state) {
              if (!_isControllerInitialized &&
                  state.status == HomeStatus.ready) {
                _controller.text = state.url;
                _isControllerInitialized = true;
              }
              if (state.submissionCount != _lastSubmissionCount) {
                _lastSubmissionCount = state.submissionCount;
                _navigateToProcessScreen(context, state.url);
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set valid API base URL in order to continue'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.compare_arrows, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.url,
                          onChanged: (value) =>
                              context.read<HomeCubit>().onUrlChanged(value),
                          decoration: InputDecoration(
                            hintText: 'https://flutter.webspark.dev/flutter/api',
                            errorText: state.errorMessage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.status == HomeStatus.loading
                          ? null
                          : () => context
                              .read<HomeCubit>()
                              .submitUrl(_controller.text),
                      child: const Text('Start counting process'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
