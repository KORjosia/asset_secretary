//community/models/community_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String authorNickname;
  final String? authorJob;
  final String content;

  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final int mentorRecommendCount;

  final Map<String, dynamic>? portfolioSnapshot; // users 문서에서 가져온 스냅샷(선택)

  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.bookmarkCount,
    required this.mentorRecommendCount,
    required this.createdAt,
    this.authorJob,
    this.portfolioSnapshot,
  });

  static CommunityPost fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = (d['createdAt'] as Timestamp?) ?? Timestamp.now();
    return CommunityPost(
      id: doc.id,
      authorId: (d['authorId'] ?? '').toString(),
      authorNickname: (d['authorNickname'] ?? '익명').toString(),
      authorJob: d['authorJob']?.toString(),
      content: (d['content'] ?? '').toString(),
      likeCount: (d['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (d['commentCount'] as num?)?.toInt() ?? 0,
      bookmarkCount: (d['bookmarkCount'] as num?)?.toInt() ?? 0,
      mentorRecommendCount: (d['mentorRecommendCount'] as num?)?.toInt() ?? 0,
      portfolioSnapshot: (d['portfolioSnapshot'] as Map<String, dynamic>?),
      createdAt: ts.toDate(),
    );
  }
}
