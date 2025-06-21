import 'package:intl/intl.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime dateOfBirth;
  final String gender;
  final double weight;
  final double height;
  final List<String> healthConditions;
  final bool isAdmin;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.weight,
    required this.height,
    required this.healthConditions,
    this.isAdmin = false,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : DateTime(2000),
      gender: json['gender'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      isAdmin: json['isAdmin'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'height': height,
      'healthConditions': healthConditions,
      'isAdmin': isAdmin,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not empty
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? dateOfBirth,
    String? gender,
    double? weight,
    double? height,
    List<String>? healthConditions,
    bool? isAdmin,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      healthConditions: healthConditions ?? this.healthConditions,
      isAdmin: isAdmin ?? this.isAdmin,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 