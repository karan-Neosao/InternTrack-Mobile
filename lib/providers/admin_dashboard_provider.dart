
import 'package:flutter/material.dart';

import '../models/admin_dashboard_model.dart';
import '../services/api_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AdminDashboardModel? dashboardData;

  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchDashboard(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getDashboard(token);

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        dashboardData = AdminDashboardModel.fromJson(
          response.data['data'],
        );
      } else {
        errorMessage = 'Failed to load dashboard';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
