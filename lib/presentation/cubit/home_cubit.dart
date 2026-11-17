import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webspark_pathfinder/data/services/url_storage_service.dart';
import 'package:webspark_pathfinder/presentation/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this._urlStorageService}) : super(const HomeState());

  final UrlStorageService _urlStorageService;

  Future<void> loadSavedUrl() async {
    emit(state.copyWith(status: HomeStatus.loading));
    final savedUrl = await _urlStorageService.getSavedUrl();
    final initialUrl =
        (savedUrl != null && savedUrl.isNotEmpty)
            ? savedUrl
            : UrlStorageService.defaultApiUrl;
    emit(
      state.copyWith(
        status: HomeStatus.ready,
        url: initialUrl,
        clearError: true,
      ),
    );
  }

  void onUrlChanged(String value) {
    if (state.status == HomeStatus.invalid || state.errorMessage != null) {
      emit(
        state.copyWith(
          status: HomeStatus.ready,
          url: value,
          clearError: true,
        ),
      );
    } else {
      emit(state.copyWith(url: value));
    }
  }

  Future<void> submitUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (!UrlStorageService.isValidApiUrl(trimmed)) {
      emit(
        state.copyWith(
          status: HomeStatus.invalid,
          url: trimmed,
          errorMessage: 'Please enter a valid HTTP or HTTPS URL',
        ),
      );
      return;
    }

    await _urlStorageService.saveUrl(trimmed);
    emit(
      state.copyWith(
        status: HomeStatus.submitted,
        url: trimmed,
        clearError: true,
        submissionCount: state.submissionCount + 1,
      ),
    );
  }
}
