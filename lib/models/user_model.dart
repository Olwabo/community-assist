import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { member, admin, worker }

extension UserRoleX on UserRole {
  String get key {
    switch (this) {
      case UserRole.member:
        return 'member';
      case UserRole.admin:
        return 'admin';
      case UserRole.worker:
        return 'worker';
    }
  }

  String get label {
    switch (this) {
      case UserRole.member:
        return 'Community Member';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.worker:
        return "Maintenance Worker";
    }
  }

  static UserRole fromKey(String? key) {
    return UserRole.values.firstWhere(
      (r) => r.key == key,
      orElse: () => UserRole.member,
    );
  }
}

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final String? photoUrl;
  final List<String> fcmTokens;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.fcmTokens = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isWorker => role == UserRole.worker;
  bool get isMember => role == UserRole.member;

  //Firestore

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRoleX.fromKey(map['role'] as String?),
      photoUrl: map['photoUrl'] as String?,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? const []),
      isActive: map['isActive'] ?? true,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role.key,
      'photoUrl': photoUrl,
      'fcmTokens': fcmTokens,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    String? photoUrl,
    List<String>? fcmTokens,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Helper: handle Timestamp or null safely
DateTime _toDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
