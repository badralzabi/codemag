import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/story_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Users
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final query = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data() as Map<String, dynamic>, query.docs.first.id);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }
  
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) return Stream.value([]);
    return _db.collection('users').snapshots().map((snapshot) {
      final all = snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      return all.where((u) => 
        u.displayName.toLowerCase().contains(query.toLowerCase()) || 
        u.username.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  Future<void> updatePresence(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleFollow(String currentUserId, UserModel targetUser, bool isFollowing, bool isRequested) async {
    WriteBatch batch = _db.batch();
    DocumentReference currentUserRef = _db.collection('users').doc(currentUserId);
    DocumentReference targetUserRef = _db.collection('users').doc(targetUser.uid);

    if (isFollowing) {
      batch.set(currentUserRef, {'following': FieldValue.arrayRemove([targetUser.uid])}, SetOptions(merge: true));
      batch.set(targetUserRef, {'followers': FieldValue.arrayRemove([currentUserId])}, SetOptions(merge: true));
    } else if (isRequested) {
      batch.set(targetUserRef, {'followRequests': FieldValue.arrayRemove([currentUserId])}, SetOptions(merge: true));
    } else {
      if (targetUser.isPrivate) {
        batch.set(targetUserRef, {'followRequests': FieldValue.arrayUnion([currentUserId])}, SetOptions(merge: true));
      } else {
        batch.set(currentUserRef, {'following': FieldValue.arrayUnion([targetUser.uid])}, SetOptions(merge: true));
        batch.set(targetUserRef, {'followers': FieldValue.arrayUnion([currentUserId])}, SetOptions(merge: true));
      }
    }

    await batch.commit();

    if (!isFollowing && !isRequested && currentUserId != targetUser.uid) {
      if (targetUser.isPrivate) {
        sendNotification(targetUser.uid, currentUserId, 'follow_request');
      } else {
        sendNotification(targetUser.uid, currentUserId, 'follow');
      }
    }
  }

  Future<void> acceptFollowRequest(String currentUserId, String requesterId, {String? notificationId}) async {
    WriteBatch batch = _db.batch();
    DocumentReference currentUserRef = _db.collection('users').doc(currentUserId);
    DocumentReference requesterRef = _db.collection('users').doc(requesterId);

    batch.set(currentUserRef, {'followRequests': FieldValue.arrayRemove([requesterId]), 'followers': FieldValue.arrayUnion([requesterId])}, SetOptions(merge: true));
    batch.set(requesterRef, {'following': FieldValue.arrayUnion([currentUserId])}, SetOptions(merge: true));
    
    if (notificationId != null) {
      batch.delete(_db.collection('notifications').doc(notificationId));
    }
    
    await batch.commit();
    sendNotification(requesterId, currentUserId, 'follow');
  }

  Future<void> declineFollowRequest(String currentUserId, String requesterId, {String? notificationId}) async {
    WriteBatch batch = _db.batch();
    batch.update(_db.collection('users').doc(currentUserId), {
      'followRequests': FieldValue.arrayRemove([requesterId])
    });
    if (notificationId != null) {
      batch.delete(_db.collection('notifications').doc(notificationId));
    }
    await batch.commit();
  }

  // Stickers
  Future<void> addRecentSticker(String userId, String stickerId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;
    
    final data = userDoc.data()!;
    List<String> recents = List<String>.from(data['recentStickers'] ?? []);
    
    // Remove if exists to put it at the top
    recents.remove(stickerId);
    recents.insert(0, stickerId);
    
    // Keep only last 20
    if (recents.length > 20) {
      recents = recents.sublist(0, 20);
    }
    
    await _db.collection('users').doc(userId).update({
      'recentStickers': recents,
    });
  }

  Future<void> toggleFavoriteSticker(String userId, String stickerId, bool isFavorite) async {
    await _db.collection('users').doc(userId).update({
      'favoriteStickers': isFavorite 
          ? FieldValue.arrayUnion([stickerId])
          : FieldValue.arrayRemove([stickerId]),
    });
  }

  // Posts
  // Posts - returns true if this is the user's first post (tracked via user doc flag)
  Future<bool> createPost(String authorId, String content, {String? imageUrl}) async {
    // Get fresh user doc to check first post flag
    final userDoc = await _db.collection('users').doc(authorId).get();
    final userData = userDoc.data() ?? {};
    
    // Check if the user document already indicates they have posted before
    final bool hasPostedBefore = userData['hasPostedBefore'] == true;
    final bool isFirstPost = !hasPostedBefore;
    final int pointsAwarded = isFirstPost ? 50 : 10; // 50 points for first, 10 for subsequent

    await _db.collection('posts').add({
      'authorId': authorId,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'commentCount': 0,
      'likes': [],
    });

    // Update buddy points and set the first post flag permanently
    await _db.collection('users').doc(authorId).update({
      'buddyPoints': FieldValue.increment(pointsAwarded),
      'hasPostedBefore': true,
    });

    return isFirstPost;
  }

  Future<PostModel?> getPost(String postId) async {
    DocumentSnapshot doc = await _db.collection('posts').doc(postId).get();
    if (doc.exists) {
      return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<PostModel?> getPostStream(String postId) {
    return _db.collection('posts').doc(postId).snapshots().map((doc) {
      if (doc.exists) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }



  Stream<List<PostModel>> getPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<PostModel>> getUserPosts(String userId) {
    return _db.collection('posts')
      .where('authorId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        var posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList();
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      });
  }

  Future<void> toggleLike(String postId, String userId, bool isLiked, String postAuthorId) async {
    DocumentReference postRef = _db.collection('posts').doc(postId);
    if (isLiked) {
      await postRef.set({
        'likes': FieldValue.arrayRemove([userId])
      }, SetOptions(merge: true));
    } else {
      await postRef.set({
        'likes': FieldValue.arrayUnion([userId])
      }, SetOptions(merge: true));
      sendNotification(postAuthorId, userId, 'like', postId: postId);
    }
  }

  Future<void> toggleBookmark(String userId, String postId, bool isBookmarked) async {
    DocumentReference userRef = _db.collection('users').doc(userId);
    if (isBookmarked) {
      await userRef.set({
        'savedPosts': FieldValue.arrayRemove([postId])
      }, SetOptions(merge: true));
    } else {
      await userRef.set({
        'savedPosts': FieldValue.arrayUnion([postId])
      }, SetOptions(merge: true));
    }
  }

  Future<bool> createStory(String authorId, String content, int colorIndex, {String? imageUrl}) async {
    // Get fresh user doc to check first story flag
    final userDoc = await _db.collection('users').doc(authorId).get();
    final userData = userDoc.data() ?? {};

    // Check if the user document already indicates they have posted a story before
    final bool hasPostedStoryBefore = userData['hasPostedStoryBefore'] == true;
    final bool isFirstStory = !hasPostedStoryBefore;
    final int pointsAwarded = isFirstStory ? 50 : 20; // 50 points for first story, 20 points for subsequent stories

    await _db.collection('stories').add({
      'authorId': authorId,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'colorIndex': colorIndex,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
    });

    // Update buddy points and set the first story flag permanently
    await _db.collection('users').doc(authorId).update({
      'buddyPoints': FieldValue.increment(pointsAwarded),
      'hasPostedStoryBefore': true,
    });

    return isFirstStory;
  }

  Stream<List<StoryModel>> getStories({List<String>? allowedUserIds}) {
    return _db.collection('stories').snapshots().map((snapshot) {
      final all = snapshot.docs.map((doc) => StoryModel.fromMap(doc.data(), doc.id)).toList();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // Return unexpired stories or highlighted stories
      return all.where((s) {
        final isNotExpired = s.expiresAt.isAfter(DateTime.now()) || s.isHighlight;
        final isAllowed = allowedUserIds == null || allowedUserIds.contains(s.authorId);
        return isNotExpired && isAllowed;
      }).toList();
    });
  }

  Stream<List<StoryModel>> getHighlights(String userId) {
    return _db.collection('stories')
        .where('authorId', isEqualTo: userId)
        .where('isHighlight', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final all = snapshot.docs.map((doc) => StoryModel.fromMap(doc.data(), doc.id)).toList();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    });
  }

  Future<void> toggleStoryHighlight(String storyId, bool isHighlight) async {
    await _db.collection('stories').doc(storyId).update({
      'isHighlight': isHighlight,
    });
  }

  Future<void> deleteStory(String storyId) async {
    await _db.collection('stories').doc(storyId).delete();
  }

  Future<void> viewStory(String storyId, String userId) async {
    await _db.collection('stories').doc(storyId).update({
      'viewers': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> reactToStory(String storyId, String userId, String reaction) async {
    await _db.collection('stories').doc(storyId).update({
      'reactions.$userId': reaction,
    });
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Future<void> updatePost(String postId, String newContent) async {
    await _db.collection('posts').doc(postId).update({
      'content': newContent,
    });
  }


  Future<void> addComment(String postId, String authorId, String content, String postAuthorId, {String? stickerUrl}) async {
    WriteBatch batch = _db.batch();
    
    DocumentReference commentRef = _db.collection('comments').doc();
    batch.set(commentRef, {
      'postId': postId,
      'authorId': authorId,
      'content': content,
      if (stickerUrl != null) 'stickerUrl': stickerUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    DocumentReference postRef = _db.collection('posts').doc(postId);
    batch.update(postRef, {
      'commentCount': FieldValue.increment(1)
    });

    await batch.commit();
    sendNotification(postAuthorId, authorId, 'comment', postId: postId);
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _db.collection('comments')
      .where('postId', isEqualTo: postId)
      .snapshots()
      .map((snapshot) {
        var comments = snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList();
        comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return comments;
      });
  }

  // Chats
  Future<String> createOrGetChatRoom(String user1Id, String user2Id) async {
    // Check if room exists
    QuerySnapshot qs = await _db.collection('chatRooms')
      .where('users', arrayContains: user1Id)
      .get();
      
    for (var doc in qs.docs) {
      List<dynamic> users = doc['users'];
      if (users.contains(user2Id)) {
        return doc.id; // Room exists
      }
    }

    // Create new room
    DocumentReference newRoom = await _db.collection('chatRooms').add({
      'users': [user1Id, user2Id],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    return newRoom.id;
  }

  Future<String> createGroupChat(List<String> userIds, String groupName, {String? groupIconUrl}) async {
    final creatorId = userIds.isNotEmpty ? userIds.first : '';
    DocumentReference docRef = _db.collection('chatRooms').doc();
    await docRef.set({
      'users': userIds,
      'lastMessage': 'تم إنشاء المجموعة',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'typingUsers': {},
      'isGroup': true,
      'groupName': groupName,
      'pinnedBy': [],
      if (groupIconUrl != null) 'groupIconUrl': groupIconUrl,
      'creatorId': creatorId,
      'admins': [creatorId],
    });
    return docRef.id;
  }

  Future<void> kickGroupMember(String roomId, String memberId) async {
    await _db.collection('chatRooms').doc(roomId).update({
      'users': FieldValue.arrayRemove([memberId]),
      'admins': FieldValue.arrayRemove([memberId]),
    });
  }

  Future<void> promoteToAdmin(String roomId, String memberId) async {
    await _db.collection('chatRooms').doc(roomId).update({
      'admins': FieldValue.arrayUnion([memberId]),
    });
  }

  Future<void> updateGroupDetails(String roomId, String newName, String? newIconUrl) async {
    await _db.collection('chatRooms').doc(roomId).update({
      'groupName': newName,
      if (newIconUrl != null) 'groupIconUrl': newIconUrl,
    });
  }

  Future<void> togglePinChatRoom(String roomId, String userId, bool isPinned) async {
    final docRef = _db.collection('chatRooms').doc(roomId);
    if (isPinned) {
      await docRef.update({
        'pinnedBy': FieldValue.arrayUnion([userId])
      });
    } else {
      await docRef.update({
        'pinnedBy': FieldValue.arrayRemove([userId])
      });
    }
  }

  Future<void> deleteChatRoom(String roomId, String userId) async {
    final docRef = _db.collection('chatRooms').doc(roomId);
    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final isGroup = data['isGroup'] ?? false;
      if (isGroup) {
        // Leave group
        await docRef.update({
          'users': FieldValue.arrayRemove([userId])
        });
      } else {
        // Delete completely for 1-1
        await docRef.delete();
        // Also delete messages inside
        final messages = await _db.collection('messages').where('roomId', isEqualTo: roomId).get();
        final batch = _db.batch();
        for (var msg in messages.docs) {
          batch.delete(msg.reference);
        }
        await batch.commit();
      }
    }
  }

  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    return _db.collection('chatRooms')
      .where('users', arrayContains: userId)
      .snapshots()
      .map((snapshot) {
        var rooms = snapshot.docs.map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id)).toList();
        rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return rooms;
      });
  }

  Future<void> sendMessage(String roomId, String senderId, String content, {
    String? imageUrl,
    String? audioUrl,
    String? storyImageUrl,
    int? duration,
    String? replyToMessageId,
    String? replyToMessageContent,
    bool isDisappearing = false,
    String? sharedPostId,
    String? sharedPostAuthorId,
    String? sharedPostAuthorName,
    String? sharedPostContent,
    String? sharedPostImageUrl,
  }) async {
    final message = {
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (storyImageUrl != null) 'storyImageUrl': storyImageUrl,
      if (duration != null) 'duration': duration,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToMessageContent != null) 'replyToMessageContent': replyToMessageContent,
      'isDisappearing': isDisappearing,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
      if (sharedPostId != null) 'sharedPostId': sharedPostId,
      if (sharedPostAuthorId != null) 'sharedPostAuthorId': sharedPostAuthorId,
      if (sharedPostAuthorName != null) 'sharedPostAuthorName': sharedPostAuthorName,
      if (sharedPostContent != null) 'sharedPostContent': sharedPostContent,
      if (sharedPostImageUrl != null) 'sharedPostImageUrl': sharedPostImageUrl,
    };
    
    try {
      await _db.collection('messages').add(message);
      // Award +5 buddy points for sending a message
      await _db.collection('users').doc(senderId).update({
        'buddyPoints': FieldValue.increment(5),
      });
    } catch (e) {
      throw Exception('Messages Collection Error: $e');
    }

    DocumentReference roomRef = _db.collection('chatRooms').doc(roomId);
    
    String lastMsgText = content;
    if (imageUrl != null) lastMsgText = '📷 صورة';
    if (audioUrl != null) lastMsgText = '🎤 مقطع صوتي';
    if (storyImageUrl != null) lastMsgText = 'رد على القصة: $content';
    if (sharedPostId != null) lastMsgText = '🔗 منشور مشترك';

    try {
      await roomRef.update({
        'lastMessage': lastMsgText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      throw Exception('ChatRooms Collection Error: $e');
    }
  }

  // Mark messages as read and delete disappearing messages if needed
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    final unreadMessages = await _db.collection('messages')
        .where('roomId', isEqualTo: roomId)
        .where('senderId', isNotEqualTo: userId)
        .where('status', isNotEqualTo: 'read')
        .get();

    final batch = _db.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'status': 'read'});
      
      // If it's a disappearing message, schedule deletion or delete after reading
      if (doc.data()['isDisappearing'] == true) {
        // We will just delete it immediately upon read for simplicity, or 
        // the client can handle deleting it after a delay.
        // Let's rely on the client to call deleteMessage after a delay.
      }
    }
    await batch.commit();
  }

  // Add reaction to message
  Future<void> addMessageReaction(String roomId, String messageId, String userId, String emoji) async {
    await _db.collection('messages').doc(messageId).set({
      'reactions': {
        userId: emoji,
      }
    }, SetOptions(merge: true));
  }

  Future<void> markMessagesAsDelivered(String roomId, String currentUserId) async {
    final undeliveredMessages = await _db.collection('messages')
        .where('roomId', isEqualTo: roomId)
        .where('senderId', isNotEqualTo: currentUserId)
        .where('status', isEqualTo: 'sent')
        .get();

    if (undeliveredMessages.docs.isEmpty) return;

    WriteBatch batch = _db.batch();
    for (var doc in undeliveredMessages.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }
    await batch.commit();
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    await _db.collection('messages').doc(messageId).delete();
  }

  Future<void> updateTypingStatus(String roomId, String userId, bool isTyping) async {
    await _db.collection('chatRooms').doc(roomId).set({
      'typingUsers': {
        userId: isTyping,
      }
    }, SetOptions(merge: true));
  }

  Stream<ChatRoomModel> getChatRoomStream(String roomId) {
    return _db.collection('chatRooms').doc(roomId).snapshots().map((doc) {
      try {
        return ChatRoomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } catch (e) {
        print('Error parsing ChatRoomModel in stream: $e');
        return ChatRoomModel(
          id: doc.id,
          users: const [],
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          lastMessageSenderId: '',
        );
      }
    });
  }

  Stream<List<MessageModel>> getMessages(String roomId) {
    return _db.collection('messages')
      .where('roomId', isEqualTo: roomId)
      .snapshots()
      .map((snapshot) {
        try {
          var messages = snapshot.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList();
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages;
        } catch (e, stack) {
          print('Error mapping messages for room $roomId: $e\n$stack');
          return <MessageModel>[];
        }
      });
  }

  // Update chat room theme
  Future<void> updateChatTheme(String roomId, String theme) async {
    await _db.collection('chatRooms').doc(roomId).update({
      'theme': theme,
    });
  }

  // Reels
  Stream<DocumentSnapshot> getReelStream(String reelId) {
    return _db.collection('reels').doc(reelId).snapshots();
  }

  Future<void> toggleReelLike(String reelId, String uid, bool isLiked) async {
    final docRef = _db.collection('reels').doc(reelId);
    if (isLiked) {
      await docRef.set({
        'likes': FieldValue.arrayUnion([uid])
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'likes': FieldValue.arrayRemove([uid])
      }, SetOptions(merge: true));
    }
  }

  Future<void> addReelComment(String reelId, String uid, String text, {String? stickerUrl}) async {
    final commentRef = _db.collection('reels').doc(reelId).collection('comments').doc();
    await commentRef.set({
      'authorId': uid,
      'content': text,
      if (stickerUrl != null) 'stickerUrl': stickerUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'postId': reelId,
    });

    await _db.collection('reels').doc(reelId).set({
      'commentCount': FieldValue.increment(1)
    }, SetOptions(merge: true));
  }

  Future<void> deleteReelComment(String reelId, String commentId) async {
    await _db.collection('reels').doc(reelId).collection('comments').doc(commentId).delete();
    await _db.collection('reels').doc(reelId).set({
      'commentCount': FieldValue.increment(-1)
    }, SetOptions(merge: true));
  }

  Future<void> editReelComment(String reelId, String commentId, String newText) async {
    await _db.collection('reels').doc(reelId).collection('comments').doc(commentId).update({
      'content': newText,
      // You can optionally add an 'updatedAt' field here
    });
  }

  Stream<List<CommentModel>> getReelCommentsStream(String reelId) {
    return _db.collection('reels').doc(reelId).collection('comments').snapshots().map((snapshot) {
      var comments = snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList();
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    });
  }

  // Notifications
  Future<void> sendNotification(String receiverId, String senderId, String type, {String? postId}) async {
    if (receiverId == senderId) return; // Don't notify self
    await _db.collection('notifications').add({
      'receiverId': receiverId,
      'senderId': senderId,
      'type': type,
      'postId': postId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db.collection('notifications')
      .where('receiverId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        var notifs = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
        notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifs;
      });
  }

  Future<void> markNotificationsAsRead(String userId) async {
    final batch = _db.batch();
    final qs = await _db.collection('notifications')
      .where('receiverId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .get();
    for (var doc in qs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> buyAccessory(String uid, String accessoryId, int price) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data != null) {
      final points = data['buddyPoints'] is int ? data['buddyPoints'] as int : 0;
      if (points >= price) {
        await _db.collection('users').doc(uid).update({
          'buddyPoints': FieldValue.increment(-price),
          'unlockedAccessories': FieldValue.arrayUnion([accessoryId]),
        });
      } else {
        throw Exception('النقاط غير كافية لشراء هذا الملحق!');
      }
    }
  }

  Future<void> equipAccessory(String uid, String? accessoryId) async {
    await _db.collection('users').doc(uid).update({
      'equippedAccessory': accessoryId,
    });
  }

  Future<void> transferPoints(String senderUid, String receiverUid, int amount) async {
    if (senderUid == receiverUid) {
      throw Exception('لا يمكنك إرسال نقاط لنفسك!');
    }
    if (amount <= 0) {
      throw Exception('يجب أن تكون كمية النقاط أكبر من صفر!');
    }
    
    final senderRef = _db.collection('users').doc(senderUid);
    final receiverRef = _db.collection('users').doc(receiverUid);

    await _db.runTransaction((transaction) async {
      final senderSnapshot = await transaction.get(senderRef);
      final receiverSnapshot = await transaction.get(receiverRef);

      if (!senderSnapshot.exists) {
        throw Exception('المستخدم المرسل غير موجود!');
      }
      if (!receiverSnapshot.exists) {
        throw Exception('المستخدم المستلم غير موجود!');
      }

      final senderData = senderSnapshot.data() as Map<String, dynamic>;
      final senderPoints = senderData['buddyPoints'] is int ? senderData['buddyPoints'] as int : 0;

      if (senderPoints < amount) {
        throw Exception('نقاطك غير كافية لإتمام عملية الإرسال!');
      }

      transaction.update(senderRef, {'buddyPoints': FieldValue.increment(-amount)});
      transaction.update(receiverRef, {'buddyPoints': FieldValue.increment(amount)});
    });
    
    // Send notification to recipient
    await sendNotification(receiverUid, senderUid, 'points_transfer', postId: amount.toString());
  }

  Future<void> startGameWithBet(String gameId, String playerXId, String playerOId, int betAmount, String gameType) async {
    final playerXRef = _db.collection('users').doc(playerXId);
    final playerORef = _db.collection('users').doc(playerOId);
    final gameRef = _db.collection('games').doc(gameId);

    await _db.runTransaction((transaction) async {
      final playerXSnapshot = await transaction.get(playerXRef);
      final playerOSnapshot = await transaction.get(playerORef);

      if (!playerXSnapshot.exists) {
        throw Exception('المستخدم الأول غير موجود!');
      }
      if (!playerOSnapshot.exists) {
        throw Exception('المستخدم الثاني غير موجود!');
      }

      final playerXData = playerXSnapshot.data() as Map<String, dynamic>;
      final playerOData = playerOSnapshot.data() as Map<String, dynamic>;

      final playerXPoints = playerXData['buddyPoints'] is int ? playerXData['buddyPoints'] as int : 0;
      final playerOPoints = playerOData['buddyPoints'] is int ? playerOData['buddyPoints'] as int : 0;

      if (playerXPoints < betAmount) {
        throw Exception('نقاط اللاعب الأول غير كافية!');
      }
      if (playerOPoints < betAmount) {
        throw Exception('نقاط اللاعب الثاني غير كافية!');
      }

      // Deduct bet points
      if (betAmount > 0) {
        transaction.update(playerXRef, {'buddyPoints': FieldValue.increment(-betAmount)});
        transaction.update(playerORef, {'buddyPoints': FieldValue.increment(-betAmount)});
      }

      final boardSize = gameType == 'c4' ? 42 : 9;

      transaction.set(gameRef, {
        'playerX': playerXId,
        'playerO': playerOId,
        'board': List.generate(boardSize, (_) => ''),
        'turn': playerXId,
        'status': 'active',
        'winner': '',
        'gameType': gameType,
        'betAmount': betAmount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> settleGame(String gameId, String winnerId, String loserId, int betAmount, String status, List<dynamic> board, String nextTurn) async {
    final gameRef = _db.collection('games').doc(gameId);
    final winnerRef = _db.collection('users').doc(winnerId);

    await _db.runTransaction((transaction) async {
      final gameSnapshot = await transaction.get(gameRef);
      if (!gameSnapshot.exists) return;

      final gameData = gameSnapshot.data() as Map<String, dynamic>;
      if (gameData['status'] != 'active') {
        throw Exception('هذه اللعبة منتهية بالفعل!');
      }

      // Payout winner
      if (betAmount > 0) {
        transaction.update(winnerRef, {'buddyPoints': FieldValue.increment(betAmount * 2)});
      }

      // Update game
      transaction.update(gameRef, {
        'board': board,
        'turn': nextTurn,
        'status': status,
        'winner': winnerId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> settleGameDraw(String gameId, String playerXId, String playerOId, int betAmount, List<dynamic> board, String nextTurn) async {
    final gameRef = _db.collection('games').doc(gameId);
    final playerXRef = _db.collection('users').doc(playerXId);
    final playerORef = _db.collection('users').doc(playerOId);

    await _db.runTransaction((transaction) async {
      final gameSnapshot = await transaction.get(gameRef);
      if (!gameSnapshot.exists) return;

      final gameData = gameSnapshot.data() as Map<String, dynamic>;
      if (gameData['status'] != 'active') {
        throw Exception('هذه اللعبة منتهية بالفعل!');
      }

      // Refund both players
      if (betAmount > 0) {
        transaction.update(playerXRef, {'buddyPoints': FieldValue.increment(betAmount)});
        transaction.update(playerORef, {'buddyPoints': FieldValue.increment(betAmount)});
      }

      // Update game to draw
      transaction.update(gameRef, {
        'board': board,
        'turn': nextTurn,
        'status': 'draw',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> awardWheelPoints(String userId, int points) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      transaction.update(userRef, {
        'buddyPoints': FieldValue.increment(points),
        'lastWheelSpin': FieldValue.serverTimestamp(),
      });
    });
  }

  // Gifts subcollection transactions
  Future<void> buyAndSendGift(String senderId, String recipientId, String roomId, String giftId, String giftName, String giftEmoji, int pointsCost) async {
    final senderRef = _db.collection('users').doc(senderId);
    final recipientGiftRef = _db.collection('users').doc(recipientId).collection('gifts').doc(giftId);
    
    await _db.runTransaction((transaction) async {
      // 1. Get all documents first (Reads)
      final senderSnapshot = await transaction.get(senderRef);
      if (!senderSnapshot.exists) {
        throw Exception('حساب المرسل غير موجود!');
      }
      final senderData = senderSnapshot.data();
      final currentPoints = (senderData != null && senderData['buddyPoints'] is int)
          ? senderData['buddyPoints'] as int
          : 0;
      if (currentPoints < pointsCost) {
        throw Exception('رصيدك غير كافٍ لشراء هذه الهدية! تحتاج إلى $pointsCost نقطة.');
      }
      
      final giftSnapshot = await transaction.get(recipientGiftRef);

      // 2. Perform all updates/sets (Writes)
      transaction.update(senderRef, {'buddyPoints': currentPoints - pointsCost});
      
      if (giftSnapshot.exists) {
        final giftData = giftSnapshot.data();
        final currentCount = (giftData != null && giftData['count'] is int)
            ? giftData['count'] as int
            : 0;
        transaction.update(recipientGiftRef, {'count': currentCount + 1, 'lastReceived': FieldValue.serverTimestamp()});
      } else {
        transaction.set(recipientGiftRef, {
          'id': giftId,
          'name': giftName,
          'emoji': giftEmoji,
          'points': pointsCost,
          'count': 1,
          'lastReceived': FieldValue.serverTimestamp(),
        });
      }
    });

    final messageRef = _db.collection('messages').doc();
    await messageRef.set({
      'roomId': roomId,
      'senderId': senderId,
      'content': '🎁 أرسل لك هدية: $giftEmoji $giftName',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
      'giftName': giftName,
      'giftEmoji': giftEmoji,
      'isDisappearing': false,
    });

    await _db.collection('chatRooms').doc(roomId).update({
      'lastMessage': '🎁 هدية: $giftEmoji $giftName',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });
  }

  Future<void> sendOwnedGift(String senderId, String recipientId, String roomId, String giftId, String giftName, String giftEmoji) async {
    final senderGiftRef = _db.collection('users').doc(senderId).collection('gifts').doc(giftId);
    final recipientGiftRef = _db.collection('users').doc(recipientId).collection('gifts').doc(giftId);
    
    await _db.runTransaction((transaction) async {
      // 1. Get all documents first (Reads)
      final senderGiftSnapshot = await transaction.get(senderGiftRef);
      if (!senderGiftSnapshot.exists) {
        throw Exception('لا تملك هذه الهدية في مخزونك!');
      }
      final senderGiftData = senderGiftSnapshot.data();
      final currentCount = (senderGiftData != null && senderGiftData['count'] is int)
          ? senderGiftData['count'] as int
          : 0;
      if (currentCount <= 0) {
        throw Exception('لا تملك هذه الهدية في مخزونك!');
      }
      
      final recipientGiftSnapshot = await transaction.get(recipientGiftRef);

      // 2. Perform all writes
      if (currentCount == 1) {
        transaction.delete(senderGiftRef);
      } else {
        transaction.update(senderGiftRef, {'count': currentCount - 1});
      }
      
      if (recipientGiftSnapshot.exists) {
        final recipientGiftData = recipientGiftSnapshot.data();
        final currentRecipientCount = (recipientGiftData != null && recipientGiftData['count'] is int)
            ? recipientGiftData['count'] as int
            : 0;
        transaction.update(recipientGiftRef, {'count': currentRecipientCount + 1, 'lastReceived': FieldValue.serverTimestamp()});
      } else {
        transaction.set(recipientGiftRef, {
          'id': giftId,
          'name': giftName,
          'emoji': giftEmoji,
          'points': (senderGiftData != null) ? (senderGiftData['points'] ?? 0) : 0,
          'count': 1,
          'lastReceived': FieldValue.serverTimestamp(),
        });
      }
    });

    final messageRef = _db.collection('messages').doc();
    await messageRef.set({
      'roomId': roomId,
      'senderId': senderId,
      'content': '🎁 أرسل لك هدية من مخزونه: $giftEmoji $giftName',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
      'giftName': giftName,
      'giftEmoji': giftEmoji,
      'isDisappearing': false,
    });

    await _db.collection('chatRooms').doc(roomId).update({
      'lastMessage': '🎁 هدية: $giftEmoji $giftName',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });
  }

  Stream<List<Map<String, dynamic>>> getUserGiftsStream(String userId) {
    return _db.collection('users').doc(userId).collection('gifts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> sellGift(String userId, String giftId, int pointsValue) async {
    final userRef = _db.collection('users').doc(userId);
    final giftRef = userRef.collection('gifts').doc(giftId);

    await _db.runTransaction((transaction) async {
      final giftSnapshot = await transaction.get(giftRef);
      if (!giftSnapshot.exists) {
        throw Exception('الهدية غير موجودة في مخزونك!');
      }

      final giftData = giftSnapshot.data();
      final count = (giftData != null && giftData['count'] is int)
          ? giftData['count'] as int
          : 0;

      if (count <= 0) {
        throw Exception('لا تملك أي نسخ من هذه الهدية لبيعها!');
      }

      if (count == 1) {
        transaction.delete(giftRef);
      } else {
        transaction.update(giftRef, {'count': count - 1});
      }

      transaction.update(userRef, {
        'buddyPoints': FieldValue.increment(pointsValue),
      });
    });
  }

  Future<void> blockUser(String currentUserId, String targetUserId) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final targetUserRef = _db.collection('users').doc(targetUserId);

    WriteBatch batch = _db.batch();

    // 1. Add to blockedUsers list
    batch.update(currentUserRef, {
      'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      // 2. Remove follow connections
      'followers': FieldValue.arrayRemove([targetUserId]),
      'following': FieldValue.arrayRemove([targetUserId]),
    });

    batch.update(targetUserRef, {
      'followers': FieldValue.arrayRemove([currentUserId]),
      'following': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
  }

  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    await currentUserRef.update({
      'blockedUsers': FieldValue.arrayRemove([targetUserId]),
    });
  }

  Future<void> removeFollower(String currentUserId, String targetUserId) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final targetUserRef = _db.collection('users').doc(targetUserId);

    WriteBatch batch = _db.batch();
    batch.update(currentUserRef, {
      'followers': FieldValue.arrayRemove([targetUserId]),
    });
    batch.update(targetUserRef, {
      'following': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
  }

  Future<List<UserModel>> getBlockedUsers(List<String> blockedUids) async {
    if (blockedUids.isEmpty) return [];
    List<UserModel> users = [];
    for (var uid in blockedUids) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        users.add(UserModel.fromMap(doc.data()!, doc.id));
      }
    }
    return users;
  }
}

