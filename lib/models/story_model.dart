import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String authorId;
  final String content;
  final String? imageUrl;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;
  final Map<String, String> reactions; // userId -> reaction (e.g. '❤️')
  final bool isHighlight;

  StoryModel({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    required this.colorIndex,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
    this.reactions = const {},
    this.isHighlight = false,
  });

  factory StoryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return StoryModel(
      id: documentId,
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      colorIndex: data['colorIndex'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      viewers: List<String>.from(data['viewers'] ?? []),
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
      isHighlight: data['isHighlight'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'colorIndex': colorIndex,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewers': viewers,
      'reactions': reactions,
      'isHighlight': isHighlight,
    };
  }
}
