import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  const RoomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.isPrivate = false,
    this.accessCode = '',
    this.avatarUrl = '',
    this.createdByName = '',
    this.createdByUsername = '',
    this.pinnedMessage = '',
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final String createdBy;
  final bool isPrivate;
  final String accessCode;
  final String avatarUrl;
  final String createdByName;
  final String createdByUsername;
  final String pinnedMessage;
  final int memberCount;
  final DateTime createdAt;

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      isPrivate: map['isPrivate'] ?? false,
      accessCode: map['accessCode'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdByUsername: map['createdByUsername'] ?? '',
      pinnedMessage: map['pinnedMessage'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'isPrivate': isPrivate,
      'accessCode': accessCode,
      'avatarUrl': avatarUrl,
      'createdByName': createdByName,
      'createdByUsername': createdByUsername,
      'pinnedMessage': pinnedMessage,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get ownerLabel =>
      createdByUsername.isNotEmpty ? '@$createdByUsername' : createdByName;

  RoomModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    bool? isPrivate,
    String? accessCode,
    String? avatarUrl,
    String? createdByName,
    String? createdByUsername,
    String? pinnedMessage,
    int? memberCount,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      accessCode: accessCode ?? this.accessCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdByName: createdByName ?? this.createdByName,
      createdByUsername: createdByUsername ?? this.createdByUsername,
      pinnedMessage: pinnedMessage ?? this.pinnedMessage,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
