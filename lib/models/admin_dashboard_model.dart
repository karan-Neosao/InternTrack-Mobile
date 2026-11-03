class AdminDashboardModel {
  final int totalStudents;
  final int totalCompanies;
  final int totalInternships;
  final int activeInternships;
  final int totalApplications;
  final int pendingApplications;
  final int acceptedApplications;
  final int rejectedApplications;

  AdminDashboardModel({
    required this.totalStudents,
    required this.totalCompanies,
    required this.totalInternships,
    required this.activeInternships,
    required this.totalApplications,
    required this.pendingApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalStudents: json['total_students'] ?? 0,
      totalCompanies: json['total_companies'] ?? 0,
      totalInternships: json['total_internships'] ?? 0,
      activeInternships: json['active_internships'] ?? 0,
      totalApplications: json['total_applications'] ?? 0,
      pendingApplications: json['pending_applications'] ?? 0,
      acceptedApplications: json['accepted_applications'] ?? 0,
      rejectedApplications: json['rejected_applications'] ?? 0,
    );
  }
}