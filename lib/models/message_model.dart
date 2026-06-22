import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final String? audioUrl;
  final String? storyImageUrl; // For story replies
  final int? duration; // Duration in seconds for audio
  final DateTime createdAt;
  final String status; // 'sent', 'delivered', 'read'
  final String? replyToMessageId;
  final String? replyToMessageContent;
  final Map<String, String>? reactions; // Map of userId -> emoji
  final bool isDisappearing;
  final String? sharedPostId;
  final String? sharedPostAuthorId;
  final String? sharedPostAuthorName;
  final String? sharedPostContent;
  final String? sharedPostImageUrl;
  final String? giftName;
  final String? giftEmoji;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    this.audioUrl,
    this.storyImageUrl,
    this.duration,
    required this.createdAt,
    this.status = 'sent',
    this.replyToMessageId,
    this.replyToMessageContent,
    this.reactions,
    this.isDisappearing = false,
    this.sharedPostId,
    this.sharedPostAuthorId,
    this.sharedPostAuthorName,
    this.sharedPostContent,
    this.sharedPostImageUrl,
    this.giftName,
    this.giftEmoji,
  });

  static Map<String, String>? _safeReactionsMap(dynamic val) {
    if (val == null) return null;
    if (val is Map) {
      return val.map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    return null;
  }

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    try {
      final createdAtData = data['createdAt'];
      DateTime parsedCreatedAt;
      if (createdAtData is Timestamp) {
        parsedCreatedAt = createdAtData.toDate();
      } else if (createdAtData is int) {
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(createdAtData);
      } else if (createdAtData is String) {
        parsedCreatedAt = DateTime.tryParse(createdAtData) ?? DateTime.now();
      } else {
        parsedCreatedAt = DateTime.now();
      }

      int? parsedDuration;
      if (data['duration'] is int) {
        parsedDuration = data['duration'];
      } else if (data['duration'] is String) {
        parsedDuration = int.tryParse(data['duration']);
      }

      return MessageModel(
        id: documentId,
        roomId: data['roomId']?.toString() ?? '',
        senderId: data['senderId']?.toString() ?? '',
        content: data['content']?.toString() ?? '',
        imageUrl: data['imageUrl']?.toString(),
        audioUrl: data['audioUrl']?.toString(),
        storyImageUrl: data['storyImageUrl']?.toString(),
        duration: parsedDuration,
        createdAt: parsedCreatedAt,
        status: data['status']?.toString() ?? (data['isRead'] == true ? 'read' : 'sent'),
        replyToMessageId: data['replyToMessageId']?.toString(),
        replyToMessageContent: data['replyToMessageContent']?.toString(),
        reactions: _safeReactionsMap(data['reactions']),
        isDisappearing: data['isDisappearing'] == true,
        sharedPostId: data['sharedPostId']?.toString(),
        sharedPostAuthorId: data['sharedPostAuthorId']?.toString(),
        sharedPostAuthorName: data['sharedPostAuthorName']?.toString(),
        sharedPostContent: data['sharedPostContent']?.toString(),
        sharedPostImageUrl: data['sharedPostImageUrl']?.toString(),
        giftName: data['giftName']?.toString(),
        giftEmoji: data['giftEmoji']?.toString(),
      );
    } catch (e, stack) {
      print('Error parsing MessageModel for $documentId: $e\n$stack');
      return MessageModel(
        id: documentId,
        roomId: data['roomId']?.toString() ?? '',
        senderId: data['senderId']?.toString() ?? '',
        content: data['content']?.toString() ?? '',
        createdAt: DateTime.now(),
        status: 'sent',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (storyImageUrl != null) 'storyImageUrl': storyImageUrl,
      if (duration != null) 'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToMessageContent != null) 'replyToMessageContent': replyToMessageContent,
      if (reactions != null) 'reactions': reactions,
      'isDisappearing': isDisappearing,
      if (sharedPostId != null) 'sharedPostId': sharedPostId,
      if (sharedPostAuthorId != null) 'sharedPostAuthorId': sharedPostAuthorId,
      if (sharedPostAuthorName != null) 'sharedPostAuthorName': sharedPostAuthorName,
      if (sharedPostContent != null) 'sharedPostContent': sharedPostContent,
      if (sharedPostImageUrl != null) 'sharedPostImageUrl': sharedPostImageUrl,
      if (giftName != null) 'giftName': giftName,
      if (giftEmoji != null) 'giftEmoji': giftEmoji,
    };
  }
}
