import 'internship_model.dart';

class ApplicationModel {
  final int id;
  final int studentId;
  final int internshipId;
  final String? coverLetter;
  final String status;
  final String? createdAt;
  final String? appliedAt;
  final InternshipModel? internship;
  final String? studentName;
  final String? studentEmail;

  ApplicationModel({
    required this.id,
    required this.studentId,
    required this.internshipId,
    this.coverLetter,
    required this.status,
    this.createdAt,
    this.appliedAt,
    this.internship,
    this.studentName,
    this.studentEmail,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    InternshipModel? internshipObj;
    if (json['internship'] is Map<String, dynamic>) {
      internshipObj = InternshipModel.fromJson(json['internship']);
    }

    String? studentNameStr;
    String? studentEmailStr;
    if (json['student'] is Map<String, dynamic>) {
      studentNameStr = json['student']['name']?.toString();
      studentEmailStr = json['student']['email']?.toString();
    }

    return ApplicationModel(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      internshipId: json['internship_id'] ?? 0,
      coverLetter: json['cover_letter']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString(),
      appliedAt: json['applied_at']?.toString() ?? json['created_at']?.toString(),
      internship: internshipObj,
      studentName: studentNameStr,
      studentEmail: studentEmailStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'internship_id': internshipId,
      'cover_letter': coverLetter,
      'status': status,
      'created_at': createdAt,
      'applied_at': appliedAt,
    };
  }

  String get formattedStatus {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'reviewed':
        return 'Under Review';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}
