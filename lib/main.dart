import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webspark_pathfinder/data/services/url_storage_service.dart';
import 'package:webspark_pathfinder/data/services/webspark_api_service.dart';
import 'package:webspark_pathfinder/domain/services/shortest_path_finder.dart';
import 'package:webspark_pathfinder/presentation/cubit/home_cubit.dart';
import 'package:webspark_pathfinder/presentation/screens/home_screen.dart';

void main() {
  runApp(const WebsparkApp());
}

class WebsparkApp extends StatelessWidget {
  const WebsparkApp({
    super.key,
    this.urlStorageService,
    this.apiService,
    this.pathFinder,
  });

  final UrlStorageService? urlStorageService;
  final WebsparkApiService? apiService;
  final PathFinder? pathFinder;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UrlStorageService>(
          create: (_) => urlStorageService ?? UrlStorageService(),
        ),
        RepositoryProvider<WebsparkApiService>(
          create: (_) => apiService ?? WebsparkApiService(),
        ),
        RepositoryProvider<PathFinder>(
          create: (_) => pathFinder ?? const BfsShortestPathFinder(),
        ),
      ],
      child: MaterialApp(
        title: 'Webspark Pathfinder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            primary: const Color(0xFF2196F3),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
              foregroundColor: Colors.black87,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.black45,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF1E88E5), width: 1),
              ),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF2196F3),
          ),
        ),
        home: BlocProvider<HomeCubit>(
          create: (context) =>
              HomeCubit(urlStorageService: context.read<UrlStorageService>())
                ..loadSavedUrl(),
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
