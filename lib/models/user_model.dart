import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.username = '',
    this.avatarUrl = '',
    this.fcmToken = '',
    this.bio = '',
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.lastSeen,
    this.isDeleted = false,
    this.deletedAt,
    this.blockedUsers = const [],
    this.mutedRooms = const [],
  });

  final String uid;
  final String name;
  final String username;
  final String email;
  final String avatarUrl;
  final String fcmToken;
  final String bio;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String theme;
  final bool notificationsEnabled;
  final List<String> blockedUsers;
  final List<String> mutedRooms;

  String get displayName {
    if (isDeleted) return 'Deleted user';
    if (name.trim().isNotEmpty) return name.trim();
    return 'FlashChat User';
  }

  String get handleLabel {
    if (isDeleted) return 'Deleted user';
    if (username.trim().isNotEmpty) return '@${username.trim()}';
    return 'FlashChat member';
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      bio: map['bio'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      theme: map['theme'] ?? 'system',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      blockedUsers: List<String>.from(map['blockedUsers'] ?? const []),
      mutedRooms: List<String>.from(map['mutedRooms'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen == null ? null : Timestamp.fromDate(lastSeen!),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'blockedUsers': blockedUsers,
      'mutedRooms': mutedRooms,
    };
  }

  UserModel copyWith({
    String? name,
    String? username,
    String? avatarUrl,
    String? fcmToken,
    String? bio,
    DateTime? lastSeen,
    bool? isDeleted,
    DateTime? deletedAt,
    String? theme,
    bool? notificationsEnabled,
    List<String>? blockedUsers,
    List<String>? mutedRooms,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      mutedRooms: mutedRooms ?? this.mutedRooms,
    );
  }
}
