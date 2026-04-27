class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  factory ProfileModel.empty({
    required String id,
    String? email,
  }) {
    return ProfileModel(
      id: id,
      email: email,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}