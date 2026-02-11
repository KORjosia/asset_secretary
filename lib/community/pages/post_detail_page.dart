//community/pages/post_detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../models/community_comment.dart';
import '../services/community_service.dart';
import '../widgets/community_ui.dart';



class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) {
      _snack('댓글을 입력해줘.');
      return;
    }
    if (text.length > 300) {
      _snack('댓글은 300자 이하여야 해.');
      return;
    }

    setState(() => _sending = true);
    try {
      await CommunityService.addComment(postId: widget.postId, text: text);
      _commentCtrl.clear();
      _snack('댓글이 등록됐어!');
    } catch (e) {
      _snack('댓글 등록 실패: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postStream = FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots();
    final commentsStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('게시글', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: CommunityUI.pageBg(),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: postStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data?.exists != true) {
                return const Center(child: Text('게시글을 찾을 수 없어.', style: TextStyle(color: Colors.white)));
              }
              if (snap.hasError) {
                return Center(child: Text('불러오기 실패: ${snap.error}', style: const TextStyle(color: Colors.white)));
              }

              final post = CommunityPost.fromDoc(snap.data!);

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      children: [
                        _PostHeader(post: post),

                        const SizedBox(height: 10),
                        _ActionBar(postId: widget.postId, post: post),

                        const SizedBox(height: 12),
                        _CommentsTitle(count: post.commentCount),

                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: commentsStream,
                          builder: (context, cs) {
                            if (cs.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (cs.hasError) {
                              return Text('댓글 불러오기 실패: ${cs.error}', style: const TextStyle(color: Colors.white));
                            }
                            final docs = cs.data?.docs ?? const [];
                            if (docs.isEmpty) {
                              return Container(
                                decoration: CommunityUI.cardDeco(),
                                padding: const EdgeInsets.all(14),
                                child: const Text(
                                  '첫 댓글을 남겨보세요 🙂',
                                  style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w800),
                                ),
                              );
                            }

                            return Column(
                              children: docs.map((d) {
                                final c = CommunityComment.fromDoc(d);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _CommentTile(c: c),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // 댓글 입력 바
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF071225),
                      border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentCtrl,
                              enabled: !_sending,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: '댓글을 입력하세요 (최대 300자)',
                                hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                                filled: true,
                                fillColor: const Color(0x121A2A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CommunityUI.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _sending ? null : _sendComment,
                              child: Text(_sending ? '전송중' : '등록', style: const TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CommunityUI.cardDeco(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
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
                      post.authorJob ?? '직업 미입력',
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
            style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12, height: 1.4),
          ),

          if (post.portfolioSnapshot != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pie_chart_outline, color: CommunityUI.accent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 게시글에는 작성자의 포트폴리오 스냅샷이 포함되어 있어요.',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.postId, required this.post});
  final String postId;
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CommunityUI.cardDeco(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          StreamBuilder<bool>(
            stream: CommunityService.likeState(postId),
            builder: (_, s) {
              final liked = s.data == true;
              return _ActionChip(
                icon: liked ? Icons.favorite : Icons.favorite_border,
                label: '좋아요 ${post.likeCount}',
                active: liked,
                onTap: () => CommunityService.toggleLike(postId),
              );
            },
          ),
          const SizedBox(width: 8),

          StreamBuilder<bool>(
            stream: CommunityService.bookmarkState(postId),
            builder: (_, s) {
              final saved = s.data == true;
              return _ActionChip(
                icon: saved ? Icons.bookmark : Icons.bookmark_border,
                label: '저장 ${post.bookmarkCount}',
                active: saved,
                onTap: () => CommunityService.toggleBookmark(postId),
              );
            },
          ),
          const SizedBox(width: 8),

          StreamBuilder<bool>(
            stream: CommunityService.mentorRecommendState(postId),
            builder: (_, s) {
              final rec = s.data == true;
              return _ActionChip(
                icon: rec ? Icons.verified : Icons.verified_outlined,
                label: '멘토추천 ${post.mentorRecommendCount}',
                active: rec,
                onTap: () => CommunityService.toggleMentorRecommend(postId),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0x1A0AA3E3) : const Color(0x121A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? const Color(0x330AA3E3) : const Color(0x22FFFFFF)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? CommunityUI.accent : const Color(0xCCFFFFFF), size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xCCFFFFFF),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsTitle extends StatelessWidget {
  const _CommentsTitle({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.mode_comment_outlined, color: Color(0xCCFFFFFF), size: 18),
        const SizedBox(width: 8),
        Text('댓글', style: CommunityUI.title()),
        const SizedBox(width: 6),
        Text('$count', style: const TextStyle(color: CommunityUI.accent, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.c});
  final CommunityComment c;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CommunityUI.cardDeco(),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2F45),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            alignment: Alignment.center,
            child: Text(
              (c.authorNickname.isNotEmpty ? c.authorNickname[0] : 'A').toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.authorNickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                const SizedBox(height: 4),
                Text(c.text, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
