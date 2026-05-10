import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.senderUsername = '',
    this.text = '',
    this.imageUrl = '',
    this.senderAvatar = '',
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.deletedFor = const [],
    this.reactions = const {},
    this.readBy = const [],
    this.replyTo,
  });

  final String id;
  final String text;
  final String imageUrl;
  final String senderId;
  final String senderName;
  final String senderUsername;
  final String senderAvatar;
  final DateTime timestamp;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;
  final List<String> deletedFor;
  final Map<String, List<String>> reactions;
  final List<String> readBy;

  // Structure: {id, senderId, senderName, senderUsername, text, imageUrl}
  final Map<String, dynamic>? replyTo;

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    final rawReactions = Map<String, dynamic>.from(map['reactions'] ?? const {});
    return MessageModel(
      id: id,
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderUsername: map['senderUsername'] ?? '',
      senderAvatar: map['senderAvatar'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
      isEdited: map['isEdited'] ?? false,
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      deletedFor: List<String>.from(map['deletedFor'] ?? const []),
      reactions: rawReactions.map(
        (key, value) => MapEntry(key, List<String>.from(value ?? const [])),
      ),
      readBy: List<String>.from(map['readBy'] ?? const []),
      replyTo: map['replyTo'] == null ? null : Map<String, dynamic>.from(map['replyTo']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'imageUrl': imageUrl,
      'senderId': senderId,
      'senderName': senderName,
      'senderUsername': senderUsername,
      'senderAvatar': senderAvatar,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'editedAt': editedAt == null ? null : Timestamp.fromDate(editedAt!),
      'deletedFor': deletedFor,
      'reactions': reactions,
      'readBy': readBy,
      'replyTo': replyTo,
    };
  }
}
