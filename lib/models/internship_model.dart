
class InternshipModel {
  final int id;
  final int companyId;
  final String title;
  final String description;
  final String? skills;
  final String? location;
  final String workType;
  final String? stipend;
  final String? duration;
  final String? deadline;
  final String status;
  final String companyName;

  InternshipModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    this.skills,
    this.location,
    required this.workType,
    this.stipend,
    this.duration,
    this.deadline,
    required this.status,
    required this.companyName,
  });

  factory InternshipModel.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>? ?? {};
    final directCompanyName = json['company_name']?.toString();

    return InternshipModel(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      skills: json['skills']?.toString(),
      location: json['location']?.toString(),
      workType: json['work_type']?.toString() ?? '',
      stipend: json['stipend']?.toString(),
      duration: json['duration']?.toString(),
      deadline: json['deadline']?.toString(),
      status: json['status']?.toString() ?? '',
      companyName: directCompanyName ?? company['name']?.toString() ?? 'Company',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'title': title,
      'description': description,
      'skills': skills,
      'location': location,
      'work_type': workType,
      'stipend': stipend,
      'duration': duration,
      'deadline': deadline,
      'status': status,
      'company_name': companyName,
      'company': {'name': companyName},
    };
  }

  List<String> get skillsList {
    if (skills == null || skills!.trim().isEmpty) return [];
    return skills!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String get formattedStipend {
    if (stipend == null || stipend!.trim().isEmpty) return 'Unpaid';
    final clean = stipend!.replaceAll('₹', '').trim();
    return '₹$clean/mo';
  }

  bool get isRemote => workType.toLowerCase() == 'remote';
  bool get isHybrid => workType.toLowerCase() == 'hybrid';
  bool get isOnsite => workType.toLowerCase() == 'onsite';
}
