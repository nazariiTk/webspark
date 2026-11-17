import 'package:material_ui/material_ui.dart';
import 'package:webspark_pathfinder/domain/entities/path_solution.dart';
import 'package:webspark_pathfinder/presentation/screens/preview_screen.dart';

/// Displays the list of computed shortest-path strings for user inspection.
class ResultListScreen extends StatelessWidget {
  /// Creates a [ResultListScreen] for the computed [solutions].
  const ResultListScreen({super.key, required this.solutions});

  /// Calculated shortest-path solutions to display.
  final List<PathSolution> solutions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result list screen')),
      body: SafeArea(
        child: solutions.isEmpty
            ? const Center(child: Text('No results available'))
            : ListView.separated(
                itemCount: solutions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final solution = solutions[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PreviewScreen(solution: solution),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      child: Text(
                        solution.formattedPath,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
