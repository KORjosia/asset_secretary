//community/pages/post_composer_page.dart
import 'package:flutter/material.dart';

import '../services/community_service.dart';
import '../widgets/community_ui.dart';

class PostComposerPage extends StatefulWidget {
  const PostComposerPage({super.key});

  @override
  State<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends State<PostComposerPage> {
  final _ctrl = TextEditingController();
  bool _attachPortfolio = false;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool get _canSubmit => _ctrl.text.trim().isNotEmpty && !_saving;

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      _snack('내용을 입력해줘.');
      return;
    }
    if (text.length > 1000) {
      _snack('글은 1000자 이하여야 해.');
      return;
    }

    setState(() => _saving = true);
    try {
      await CommunityService.createPost(content: text, attachPortfolio: _attachPortfolio);
      _snack('게시글이 등록됐어!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('등록 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('글쓰기', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: CommunityUI.pageBg(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            children: [
              Container(
                decoration: CommunityUI.cardDeco(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('게시글 내용', style: CommunityUI.title()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ctrl,
                      maxLines: 10,
                      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                      decoration: InputDecoration(
                        hintText: '자산 관리 팁, 투자 경험, 질문 등 자유롭게 공유해보세요.',
                        hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0x121A2A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x0AFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x22FFFFFF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pie_chart_outline, color: CommunityUI.accent, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '내 포트폴리오를 함께 공유할까요?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                          Switch(
                            value: _attachPortfolio,
                            activeColor: CommunityUI.accent,
                            onChanged: (v) => setState(() => _attachPortfolio = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '※ 포트폴리오 공유를 ON 하면, 현재 users 문서의 profile/goal을 스냅샷으로 게시글에 함께 저장합니다.',
                      style: CommunityUI.sub(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CommunityUI.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: const Color(0xFF103A4D),
                    disabledForegroundColor: const Color(0x66FFFFFF),
                  ),
                  onPressed: _canSubmit ? _submit : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(_saving ? '등록 중...' : '등록하기', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
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
