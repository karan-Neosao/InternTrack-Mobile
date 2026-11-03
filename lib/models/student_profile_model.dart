class StudentProfileModel {
  final int? id;
  final int? userId;
  final String? phone;
  final String? college;
  final String? course;
  final int? graduationYear;
  final String? skills;
  final String? resumePath;
  final String? linkedinUrl;

  StudentProfileModel({
    this.id,
    this.userId,
    this.phone,
    this.college,
    this.course,
    this.graduationYear,
    this.skills,
    this.resumePath,
    this.linkedinUrl,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      phone: json['phone']?.toString(),
      college: json['college']?.toString(),
      course: json['course']?.toString(),
      graduationYear: json['graduation_year'] is int
          ? json['graduation_year']
          : int.tryParse(json['graduation_year']?.toString() ?? ''),
      skills: json['skills']?.toString(),
      resumePath: json['resume_path']?.toString(),
      linkedinUrl: json['linkedin_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (phone != null) 'phone': phone,
      if (college != null) 'college': college,
      if (course != null) 'course': course,
      if (graduationYear != null) 'graduation_year': graduationYear,
      if (skills != null) 'skills': skills,
      if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
    };
  }

  List<String> get skillsList {
    if (skills == null || skills!.trim().isEmpty) return [];
    return skills!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
