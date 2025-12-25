import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Support both String (old data) and Timestamp (new data) for createdAt.
    final createdAtRaw = map['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: createdAt,
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
      // Simpan sebagai Firestore Timestamp supaya konsisten dengan struktur
      // yang diinginkan di database.
      'createdAt': Timestamp.fromDate(createdAt),
      if (phone != null) 'phone': phone,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
      if (gender != null) 'gender': gender,
    };
  }
}
