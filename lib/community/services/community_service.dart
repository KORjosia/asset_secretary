//community/services/community_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static Future<Map<String, dynamic>> _loadMyProfileForPost() async {
    final uid = _uid;
    if (uid == null) return {};

    final userSnap = await _db.collection('users').doc(uid).get();
    final data = userSnap.data() ?? {};
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final goal = (data['goal'] as Map<String, dynamic>?) ?? {};

    // 포트폴리오 스냅샷(원하면 여기서 더 축소/가공 가능)
    return {
      'profile': profile,
      'goal': goal,
      'selectedMentor': data['selectedMentor'] ?? {},
      'capturedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<String> _myNickname() async {
    final uid = _uid;
    if (uid == null) return '익명';

    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data() ?? {};
    // signup에서 nickname을 users에 저장하고 있음
    return (data['nickname'] ?? '익명').toString();
  }

  static Future<String?> _myJob() async {
    final uid = _uid;
    if (uid == null) return null;

    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data() ?? {};
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final job = profile['job']?.toString();
    return job?.isEmpty == true ? null : job;
  }

  // ===== 게시글 작성 =====
  static Future<void> createPost({
    required String content,
    required bool attachPortfolio,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('NOT_AUTH');

    final nickname = await _myNickname();
    final job = await _myJob();

    final ref = _db.collection('posts').doc();
    final payload = <String, dynamic>{
      'authorId': uid,
      'authorNickname': nickname,
      'authorJob': job,
      'content': content,
      'likeCount': 0,
      'commentCount': 0,
      'bookmarkCount': 0,
      'mentorRecommendCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (attachPortfolio) {
      payload['portfolioSnapshot'] = await _loadMyProfileForPost();
    }

    await ref.set(payload);
  }

  // ===== 좋아요 토글 =====
  static Future<void> toggleLike(String postId) async {
    final uid = _uid;
    if (uid == null) throw Exception('NOT_AUTH');

    final postRef = _db.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);

    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  // ===== 저장(북마크) 토글 =====
  static Future<void> toggleBookmark(String postId) async {
    final uid = _uid;
    if (uid == null) throw Exception('NOT_AUTH');

    final postRef = _db.collection('posts').doc(postId);
    final bmRef = postRef.collection('bookmarks').doc(uid);

    await _db.runTransaction((tx) async {
      final bmSnap = await tx.get(bmRef);
      if (bmSnap.exists) {
        tx.delete(bmRef);
        tx.update(postRef, {'bookmarkCount': FieldValue.increment(-1)});
      } else {
        tx.set(bmRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'bookmarkCount': FieldValue.increment(1)});
      }
    });
  }

  // ===== 멘토 추천 토글 =====
  static Future<void> toggleMentorRecommend(String postId) async {
    final uid = _uid;
    if (uid == null) throw Exception('NOT_AUTH');

    final postRef = _db.collection('posts').doc(postId);
    final recRef = postRef.collection('mentor_recommends').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(recRef);
      if (snap.exists) {
        tx.delete(recRef);
        tx.update(postRef, {'mentorRecommendCount': FieldValue.increment(-1)});
      } else {
        tx.set(recRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'mentorRecommendCount': FieldValue.increment(1)});
      }
    });
  }

  // ===== 댓글 추가 =====
  static Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('NOT_AUTH');

    final nickname = await _myNickname();
    final postRef = _db.collection('posts').doc(postId);
    final cRef = postRef.collection('comments').doc();

    await _db.runTransaction((tx) async {
      tx.set(cRef, {
        'authorId': uid,
        'authorNickname': nickname,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(postRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  // ===== 내 상태 읽기(좋아요/저장/추천) =====
  static Stream<bool> likeState(String postId) {
    final uid = _uid;
   if (uid == null) return Stream<bool>.value(false);
    return _db.collection('posts').doc(postId).collection('likes').doc(uid).snapshots().map((d) => d.exists);
  }

  static Stream<bool> bookmarkState(String postId) {
    final uid = _uid;
    if (uid == null) return Stream<bool>.value(false);
    return _db.collection('posts').doc(postId).collection('bookmarks').doc(uid).snapshots().map((d) => d.exists);
  }

  static Stream<bool> mentorRecommendState(String postId) {
    final uid = _uid;
    if (uid == null) return Stream<bool>.value(false);
    return _db.collection('posts').doc(postId).collection('mentor_recommends').doc(uid).snapshots().map((d) => d.exists);
  }
}
