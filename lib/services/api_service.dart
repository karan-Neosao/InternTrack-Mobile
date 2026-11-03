
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio dio;

  static const String primaryUrl = 'http://192.168.1.12:8000/api';
  static const String fallbackUrl = 'http://127.0.0.1:8000/api';
  static String activeBaseUrl = primaryUrl;

  static const String baseUrl = primaryUrl;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: activeBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Auto-fallback interceptor: If connecting to 192.168.1.12 fails (e.g. Wi-Fi off, USB connected),
    // automatically retry with 127.0.0.1:8000 (adb reverse), and vice-versa!
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          if (err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.connectionError) {
            final currentBase = dio.options.baseUrl;
            final alternateBase = currentBase == primaryUrl ? fallbackUrl : primaryUrl;

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

                dio.options.baseUrl = alternateBase;
                activeBaseUrl = alternateBase;

                final response = await dio.request(
                  err.requestOptions.path,
                  data: err.requestOptions.data,
                  queryParameters: err.requestOptions.queryParameters,
                  options: options,
                );

                return handler.resolve(response);
              } catch (_) {
                dio.options.baseUrl = primaryUrl;
                activeBaseUrl = primaryUrl;
              }
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  // Extract API error message
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

    if (error.response?.statusCode == 404) {
      return 'Requested resource not found.';
    }

    if (error.response?.statusCode == 401) {
      return 'Invalid credentials. Please check your email and password.';
    }

    if (error.response?.statusCode == 500) {
      return 'Internal server error. Please try again later.';
    }

    return 'Connection failed. Please check your network and try again.';
  }

  // Extract token and user from Laravel response
  Map<String, dynamic> _extractAuthData(dynamic responseData) {
    if (responseData is! Map) {
      throw Exception('Invalid response from server');
    }

    final root = Map<String, dynamic>.from(responseData);

    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'])
        : root;

    if (data['token'] == null || data['user'] is! Map) {
      throw Exception(
        root['message']?.toString() ??
            'Invalid authentication response from server',
      );
    }

    return data;
  }

  // LOGIN
  Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    try {
      final response = await dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return _extractAuthData(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // STUDENT REGISTRATION
  Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      return _extractAuthData(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY REGISTRATION
  Future<Map<String, dynamic>> registerCompany({
    required String name,
    required String email,
    required String password,
    required String companyName,
    String? website,
    String? description,
    String? industry,
    String? location,
  }) async {
    try {
      final response = await dio.post(
        '/register-company',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'company_name': companyName,
          'website': website,
          'description': description,
          'industry': industry,
          'location': location,
        },
      );

      return _extractAuthData(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // GET LOGGED-IN USER
  Future<Map<String, dynamic>> getUser(String token) async {
    try {
      final response = await dio.get(
        '/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;

      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }

      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // LOGOUT
  Future<void> logout(String token) async {
    try {
      await dio.post(
        '/logout',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ADMIN DASHBOARD
  Future<Response> getDashboard(String token) async {
    try {
      return await dio.get(
        '/admin/dashboard',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // GET ACTIVE INTERNSHIPS
  Future<List<Map<String, dynamic>>> getInternships() async {
    try {
      final response = await dio.get('/internships');
      if (response.data['success'] == true) {
        final paginationData = response.data['data'];
        final List<dynamic> list = paginationData['data'] ?? [];
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // GET SINGLE INTERNSHIP
  Future<Map<String, dynamic>> getInternshipDetails(int id) async {
    try {
      final response = await dio.get('/internships/$id');
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception('Internship not found');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // STUDENT: UPLOAD RESUME
  Future<Map<String, dynamic>> uploadStudentResume({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'resume': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/student/upload-resume',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception(response.data['message']?.toString() ?? 'Resume upload failed');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // STUDENT: APPLY FOR INTERNSHIP
  Future<String> applyForInternship({
    required int internshipId,
    required String token,
    String? coverLetter,
    String? resumeFilePath,
    String? resumeFileName,
  }) async {
    try {
      // If a resume file is selected, upload it first to sync with student profile and application
      if (resumeFilePath != null && resumeFileName != null) {
        try {
          await uploadStudentResume(
            token: token,
            filePath: resumeFilePath,
            fileName: resumeFileName,
          );
        } catch (uploadErr) {
          debugPrint('Notice: Resume upload step: $uploadErr');
        }
      }

      final response = await dio.post(
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

  // STUDENT: GET MY APPLICATIONS
  Future<List<Map<String, dynamic>>> getMyApplications(String token) async {
    try {
      final response = await dio.get(
        '/my-applications',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        final paginationData = response.data['data'];
        final List<dynamic> list = paginationData['data'] ?? [];
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // STUDENT: GET PROFILE
  Future<Map<String, dynamic>> getStudentProfile(String token) async {
    try {
      final response = await dio.get(
        '/student/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception('Unable to fetch profile');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // STUDENT: UPDATE PROFILE
  Future<Map<String, dynamic>> updateStudentProfile({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await dio.put(
        '/student/profile',
        data: profileData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(response.data['message']?.toString() ?? 'Profile update failed');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY: GET PROFILE
  Future<Map<String, dynamic>> getCompanyProfile(String token) async {
    try {
      final response = await dio.get(
        '/company/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception('Unable to fetch company profile');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY: UPDATE PROFILE
  Future<Map<String, dynamic>> updateCompanyProfile({
    required String token,
    required Map<String, dynamic> companyData,
  }) async {
    try {
      final response = await dio.put(
        '/company/profile',
        data: companyData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(response.data['message']?.toString() ?? 'Company profile update failed');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY: GET APPLICANTS
  Future<List<Map<String, dynamic>>> getCompanyApplicants(String token) async {
    try {
      final response = await dio.get(
        '/company/applicants',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        final paginationData = response.data['data'];
        final List<dynamic> list = paginationData['data'] ?? [];
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY: UPDATE APPLICANT STATUS
  Future<Map<String, dynamic>> updateApplicationStatus({
    required int applicationId,
    required String status,
    required String token,
  }) async {
    try {
      final response = await dio.patch(
        '/company/applications/$applicationId/status',
        data: {'status': status},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(response.data['message']?.toString() ?? 'Status update failed');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY: CREATE INTERNSHIP
  Future<Map<String, dynamic>> createInternship({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        '/internships',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(response.data['message']?.toString() ?? 'Failed to create internship');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY: UPDATE INTERNSHIP
  Future<Map<String, dynamic>> updateInternship({
    required int id,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      final response = await dio.put(
        '/internships/$id',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(response.data['message']?.toString() ?? 'Failed to update internship');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // COMPANY: DELETE INTERNSHIP
  Future<void> deleteInternship({
    required int id,
    required String token,
  }) async {
    try {
      await dio.delete(
        '/internships/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }
}
