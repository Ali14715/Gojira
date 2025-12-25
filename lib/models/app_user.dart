class AppUser {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final String? phone;
  final String? imageUrl;
  final DateTime? birthDate;
  final String? gender;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    this.phone,
    this.imageUrl,
    this.birthDate,
    this.gender,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      phone: map['phone'] as String?,
      imageUrl: map['imageUrl'] as String?,
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : null,
      gender: map['gender'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
      if (gender != null) 'gender': gender,
    };
  }
}
