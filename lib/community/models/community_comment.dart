//lib/community/models/community_comment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorNickname;
  final String content;
  final DateTime createdAt;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorNickname,
    required this.content,
    required this.createdAt,
  });
  
  String get text => content;

  factory CommunityComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    DateTime createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return CommunityComment(
      id: doc.id,
      postId: (data['postId'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      authorNickname: (data['authorNickname'] ?? '').toString(),
      content: (data['content'] ?? '').toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorNickname': authorNickname,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
