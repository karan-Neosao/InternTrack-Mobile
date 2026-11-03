
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? token;
  Map<String, dynamic>? user;

  bool isLoading = false;
  String? errorMessage;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  String get userRole => user?['role']?.toString() ?? '';

  // LOGIN
  Future<bool> login({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(
        email.trim(),
        password,
      );

      final receivedUser =
      Map<String, dynamic>.from(result['user']);

      final receivedRole =
          receivedUser['role']?.toString() ?? '';

      if (receivedRole != expectedRole) {
        errorMessage =
        'This account is not registered as $expectedRole.';
        return false;
      }

      token = result['token'].toString();
      user = receivedUser;

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // STUDENT REGISTRATION
  Future<bool> registerStudent({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.registerStudent(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );

      token = result['token'].toString();
      user = Map<String, dynamic>.from(result['user']);

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // COMPANY REGISTRATION
  Future<bool> registerCompany({
    required String name,
    required String email,
    required String password,
    required String companyName,
    String? website,
    String? description,
    String? industry,
    String? location,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.registerCompany(
        name: name.trim(),
        email: email.trim(),
        password: password,
        companyName: companyName.trim(),
        website: website,
        description: description,
        industry: industry,
        location: location,
      );

      token = result['token'].toString();
      user = Map<String, dynamic>.from(result['user']);

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    final currentToken = token;

    try {
      if (currentToken != null) {
        await _apiService.logout(currentToken);
      }
    } finally {
      token = null;
      user = null;
      errorMessage = null;
      notifyListeners();
    }
  }
}
