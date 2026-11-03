class CompanyProfileModel {
  final int? id;
  final int? userId;
  final String? companyName;
  final String? website;
  final String? description;
  final String? industry;
  final String? location;
  final String? logoPath;
  final bool isVerified;

  CompanyProfileModel({
    this.id,
    this.userId,
    this.companyName,
    this.website,
    this.description,
    this.industry,
    this.location,
    this.logoPath,
    this.isVerified = false,
  });

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanyProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      companyName: json['company_name']?.toString(),
      website: json['website']?.toString(),
      description: json['description']?.toString(),
      industry: json['industry']?.toString(),
      location: json['location']?.toString(),
      logoPath: json['logo_path']?.toString(),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (companyName != null) 'company_name': companyName,
      if (website != null) 'website': website,
      if (description != null) 'description': description,
      if (industry != null) 'industry': industry,
      if (location != null) 'location': location,
    };
  }
}
