import 'package:equatable/equatable.dart';

enum HomeStatus {
  initial,
  loading,
  ready,
  invalid,
  submitted,
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.url = '',
    this.errorMessage,
    this.submissionCount = 0,
  });

  final HomeStatus status;
  final String url;
  final String? errorMessage;
  final int submissionCount;

  HomeState copyWith({
    HomeStatus? status,
    String? url,
    String? errorMessage,
    bool clearError = false,
    int? submissionCount,
  }) {
    return HomeState(
      status: status ?? this.status,
      url: url ?? this.url,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submissionCount: submissionCount ?? this.submissionCount,
    );
  }

  @override
  List<Object?> get props => [status, url, errorMessage, submissionCount];
}
