//community/pages/community_feed_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../widgets/community_ui.dart';
import 'post_composer_page.dart';
import 'post_detail_page.dart';

class CommunityFeedPage extends StatelessWidget {
  const CommunityFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('커뮤니티', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PostComposerPage()));
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: CommunityUI.pageBg(),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: posts,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    '커뮤니티 불러오기 실패: ${snap.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    decoration: CommunityUI.cardDeco(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.forum_outlined, color: Color(0x66FFFFFF), size: 44),
                        const SizedBox(height: 10),
                        const Text('아직 게시글이 없습니다', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text('첫 글을 작성해서 커뮤니티를 시작해보세요', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 46,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CommunityUI.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PostComposerPage()));
                            },
                            child: const Text('글쓰기', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final post = CommunityPost.fromDoc(docs[i]);
                  return _PostCard(
                    post: post,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)));
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});
  final CommunityPost post;
  final VoidCallback onTap;

  String _timeText(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: CommunityUI.cardDeco(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2F45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (post.authorNickname.isNotEmpty ? post.authorNickname[0] : 'A').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorNickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        '${post.authorJob ?? '직업 미입력'} · ${_timeText(post.createdAt)}',
                        style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (post.portfolioSnapshot != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: const Text('포트폴리오', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Metric(icon: Icons.favorite_border, text: '${post.likeCount}'),
                const SizedBox(width: 10),
                _Metric(icon: Icons.mode_comment_outlined, text: '${post.commentCount}'),
                const SizedBox(width: 10),
                _Metric(icon: Icons.bookmark_border, text: '${post.bookmarkCount}'),
                const Spacer(),
                _Metric(icon: Icons.verified_outlined, text: '${post.mentorRecommendCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0x99FFFFFF), size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
