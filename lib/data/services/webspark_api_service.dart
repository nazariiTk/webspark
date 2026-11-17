import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:webspark_pathfinder/domain/entities/path_solution.dart';
import 'package:webspark_pathfinder/domain/entities/path_task.dart';

/// Exception raised when a Webspark API call or response validation fails
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Network service for retrieving pathfinding tasks and submitting solutions
/// to the Webspark API
class WebsparkApiService {
  WebsparkApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

  final Dio _dio;

  /// Fetches pathfinding tasks from [url], preserving any query parameters
  Future<List<PathTask>> fetchTasks(String url) async {
    final uri = _parseUri(url);
    try {
      final response = await _dio.getUri<dynamic>(uri);
      final rawTasks = _extractDataList(
        response,
        fallbackErrorMessage: 'Unknown server error',
      );

      return rawTasks.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ApiException(
            'Unexpected task format in server response.',
            statusCode: response.statusCode,
          );
        }
        return PathTask.fromJson(item);
      }).toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw ApiException('Invalid task data from server: ${e.message}');
    } on ArgumentError catch (e) {
      throw ApiException('Invalid task data from server: ${e.message ?? e}');
    }
  }

  /// Submits solved [solutions] to [url] and verifies all server results pass
  Future<void> sendSolutions(String url, List<PathSolution> solutions) async {
    final uri = _parseUri(url);
    final payload = solutions.map((s) => s.toSubmissionJson()).toList();
    try {
      final response = await _dio.postUri<dynamic>(uri, data: payload);
      final results = _extractDataList(
        response,
        fallbackErrorMessage: 'Server error',
      );

      for (final item in results) {
        if (item is! Map || item['correct'] != true) {
          throw ApiException(
            'Some solutions were marked incorrect by the server.',
            statusCode: response.statusCode,
          );
        }
      }
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Uri _parseUri(String url) {
    try {
      return Uri.parse(url.trim());
    } on FormatException {
      throw const ApiException('Invalid API URL.');
    }
  }

  List<dynamic> _extractDataList(
    Response<dynamic> response, {
    required String fallbackErrorMessage,
  }) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        'Unexpected response format from server.',
        statusCode: response.statusCode,
      );
    }

    if (body['error'] == true) {
      final serverMessage = body['message']?.toString().trim();
      throw ApiException(
        (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : fallbackErrorMessage,
        statusCode: response.statusCode,
      );
    }

    final payload = body['data'];
    if (payload is! List<dynamic>) {
      throw ApiException(
        'Unexpected response format: missing list in "data".',
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  ApiException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final serverMessage = _extractServerMessage(e.response?.data);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          'Connection timed out. Please check your network and try again.',
          statusCode: statusCode,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          'Request timed out while sending data. Please try again.',
          statusCode: statusCode,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Server took too long to respond. Please try again.',
          statusCode: statusCode,
        );
      case DioExceptionType.transformTimeout:
        return ApiException(
          'Response processing timed out. Please try again.',
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'Connection failed. Please check your internet connection and API URL.',
          statusCode: statusCode,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          'SSL certificate verification failed.',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.', statusCode: statusCode);
      case DioExceptionType.badResponse:
        return ApiException(
          serverMessage ?? _defaultMessageForStatusCode(statusCode),
          statusCode: statusCode,
        );
      case DioExceptionType.unknown:
        return ApiException(
          serverMessage ?? 'Unexpected network error. Please check your connection and try again.',
          statusCode: statusCode,
        );
    }
  }

  String? _extractServerMessage(dynamic data) {
    Map<dynamic, dynamic>? map;
    if (data is Map) {
      map = data;
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          map = decoded;
        }
      } on FormatException {
        return null;
      }
    }

    final message = map?['message']?.toString().trim();
    return (message != null && message.isNotEmpty) ? message : null;
  }

  String _defaultMessageForStatusCode(int? statusCode) {
    return switch (statusCode) {
      400 => 'Bad request (400). Please check the submitted data.',
      401 || 403 => 'Access denied ($statusCode).',
      404 => 'API endpoint not found (404). Please check the URL.',
      429 => 'Too many requests (429). Please wait and try again later.',
      final code when code != null && code >= 500 =>
        'Server error ($code). Please try again later.',
      final code? => 'Request failed with status code $code.',
      null => 'Server returned an error response.',
    };
  }
}
