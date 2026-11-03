import 'package:dio/dio.dart';
import '../models/internship_model.dart';
import 'api_service.dart';

class InternshipService {
  late final Dio _dio;

  InternshipService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiService.activeBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          if (err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.connectionError) {
            final currentBase = _dio.options.baseUrl;
            final alternateBase = currentBase == ApiService.primaryUrl
                ? ApiService.fallbackUrl
                : ApiService.primaryUrl;

            final hasRetried = err.requestOptions.extra['has_retried_fallback'] == true;
            if (!hasRetried) {
              try {
                final options = Options(
                  method: err.requestOptions.method,
                  headers: err.requestOptions.headers,
                  extra: {
                    ...err.requestOptions.extra,
                    'has_retried_fallback': true,
                  },
                );

                _dio.options.baseUrl = alternateBase;
                ApiService.activeBaseUrl = alternateBase;

                final response = await _dio.request(
                  err.requestOptions.path,
                  data: err.requestOptions.data,
                  queryParameters: err.requestOptions.queryParameters,
                  options: options,
                );

                return handler.resolve(response);
              } catch (_) {
                _dio.options.baseUrl = ApiService.primaryUrl;
                ApiService.activeBaseUrl = ApiService.primaryUrl;
              }
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  // Get all active internships
  Future<List<InternshipModel>> getInternships() async {
    try {
      final response = await _dio.get('/internships');

      if (response.data['success'] == true) {
        final paginationData = response.data['data'];
        final List<dynamic> internshipList =
            paginationData['data'] ?? [];

        return internshipList
            .map(
              (item) => InternshipModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
            .toList();
      }

      throw Exception('Unable to fetch internships.');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // Get internship details by ID
  Future<InternshipModel> getInternshipDetails(int id) async {
    try {
      final response = await _dio.get('/internships/$id');

      if (response.data['success'] == true) {
        return InternshipModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception('Unable to fetch internship details.');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // Apply for an internship
  Future<String> applyForInternship({
    required int internshipId,
    required String token,
    String? coverLetter,
  }) async {
    try {
      final response = await _dio.post(
        '/internships/$internshipId/apply',
        data: {
          'cover_letter': coverLetter,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data['message']?.toString() ??
          'Application submitted successfully.';
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // Common API error handler
  String _getErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please ensure your phone is connected to the same Wi-Fi (192.168.1.12) as your laptop.';
    }

    final data = error.response?.data;

    if (data is Map) {
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
          if (firstError is String) {
            return firstError;
          }
        }
      }

      if (data['message'] != null) {
        return data['message'].toString();
      }
    }

    return 'Failed to connect to server. Please try again.';
  }
}