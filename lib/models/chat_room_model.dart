import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> users;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, bool> typingUsers; // Map of userId -> isTyping
  final bool isGroup;
  final String? groupName;
  final String? groupIconUrl;
  final List<String> pinnedBy;
  final String theme; // default, love, snow, summer
  final String? creatorId;
  final List<String> admins;
  final String activePanel; // none, game, watch

  ChatRoomModel({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.typingUsers = const {},
    this.isGroup = false,
    this.groupName,
    this.groupIconUrl,
    this.pinnedBy = const [],
    this.theme = 'default',
    this.creatorId,
    this.admins = const [],
    this.activePanel = 'none',
  });

  static List<String> _safeList(dynamic val) {
    if (val == null) return const [];
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static Map<String, bool> _safeTypingMap(dynamic val) {
    if (val == null) return const {};
    if (val is Map) {
      return val.map((key, value) => MapEntry(key.toString(), value == true));
    }
    return const {};
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> data, String documentId) {
    try {
      final lastMsgTimeData = data['lastMessageTime'];
      DateTime parsedTime;
      if (lastMsgTimeData is Timestamp) {
        parsedTime = lastMsgTimeData.toDate();
      } else if (lastMsgTimeData is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(lastMsgTimeData);
      } else if (lastMsgTimeData is String) {
        parsedTime = DateTime.tryParse(lastMsgTimeData) ?? DateTime.now();
      } else {
        parsedTime = DateTime.now();
      }

      return ChatRoomModel(
        id: documentId,
        users: _safeList(data['users']),
        lastMessage: data['lastMessage']?.toString() ?? '',
        lastMessageTime: parsedTime,
        lastMessageSenderId: data['lastMessageSenderId']?.toString() ?? '',
        typingUsers: _safeTypingMap(data['typingUsers']),
        isGroup: data['isGroup'] == true,
        groupName: data['groupName']?.toString(),
        groupIconUrl: data['groupIconUrl']?.toString(),
        pinnedBy: _safeList(data['pinnedBy']),
        theme: data['theme']?.toString() ?? 'default',
        creatorId: data['creatorId']?.toString(),
        admins: _safeList(data['admins']),
        activePanel: data['activePanel']?.toString() ?? 'none',
      );
    } catch (e, stack) {
      print('Error parsing ChatRoomModel for $documentId: $e\n$stack');
      return ChatRoomModel(
        id: documentId,
        users: const [],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: '',
        typingUsers: const {},
        isGroup: false,
        pinnedBy: const [],
        theme: 'default',
        creatorId: null,
        admins: const [],
        activePanel: 'none',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'typingUsers': typingUsers,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupIconUrl': groupIconUrl,
      'pinnedBy': pinnedBy,
      'theme': theme,
      if (creatorId != null) 'creatorId': creatorId,
      'admins': admins,
      'activePanel': activePanel,
    };
  }
}
