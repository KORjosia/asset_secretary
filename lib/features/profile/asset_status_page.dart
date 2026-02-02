//lib/features/profile/asset_status_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/money_input_formatter.dart';

class AssetStatusPage extends ConsumerStatefulWidget {
  const AssetStatusPage({
    super.key,
    this.onDonePop = true,
  });

  final bool onDonePop;

  @override
  ConsumerState<AssetStatusPage> createState() => _AssetStatusPageState();
}

class _AssetStatusPageState extends ConsumerState<AssetStatusPage> {
  final jobCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final regionCtrl = TextEditingController();

  final monthlyCtrl = TextEditingController();
  final sideCtrl = TextEditingController();
  final goalCtrl = TextEditingController();

  // ✅ 월급날(1~28)
  final paydayCtrl = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(userProfileProvider);

    jobCtrl.text = p.job;
    companyCtrl.text = p.company;
    regionCtrl.text = p.region;

    monthlyCtrl.text = p.monthlyIncomeWon > 0 ? p.monthlyIncomeWon.toString() : '';
    sideCtrl.text = p.sideIncomeWon > 0 ? p.sideIncomeWon.toString() : '';
    goalCtrl.text = p.savingsGoalWon > 0 ? p.savingsGoalWon.toString() : '';

    paydayCtrl.text = p.paydayDay.toString(); // ✅ 기본 25
  }

  @override
  void dispose() {
    jobCtrl.dispose();
    companyCtrl.dispose();
    regionCtrl.dispose();
    monthlyCtrl.dispose();
    sideCtrl.dispose();
    goalCtrl.dispose();
    paydayCtrl.dispose();
    super.dispose();
  }

  int _parseWon(String s) => int.tryParse(s.replaceAll(',', '').trim()) ?? 0;
  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _save() async {
    setState(() {
      loading = true;
      error = null;
    });

    final job = jobCtrl.text.trim();
    final company = companyCtrl.text.trim();
    final region = regionCtrl.text.trim();

    final monthly = _parseWon(monthlyCtrl.text);
    final side = _parseWon(sideCtrl.text);
    final goal = _parseWon(goalCtrl.text);

    final paydayRaw = _parseInt(paydayCtrl.text);
    final payday = paydayRaw.clamp(1, 28);

    // ✅ 최소 필수 조건
    if (job.isEmpty) {
      setState(() {
        loading = false;
        error = '직업을 입력해줘.';
      });
      return;
    }
    if (region.isEmpty) {
      setState(() {
        loading = false;
        error = '지역을 입력해줘.';
      });
      return;
    }
    if (monthly <= 0) {
      setState(() {
        loading = false;
        error = '월수익(월급)은 0보다 커야 해.';
      });
      return;
    }
    if (paydayRaw <= 0) {
      setState(() {
        loading = false;
        error = '월급날을 입력해줘. (1~28)';
      });
      return;
    }

    final next = UserProfile(
      job: job,
      company: company,
      region: region,
      monthlyIncomeWon: monthly,
      sideIncomeWon: side,
      savingsGoalWon: goal,
      paydayDay: payday, // ✅ 필수
    );

    try {
      await ref.read(userProfileProvider.notifier).updateProfile(next);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자산 현황이 저장됐어요.')),
      );

      if (widget.onDonePop) Navigator.pop(context);
    } catch (e) {
      setState(() => error = '저장 실패: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 현황'),
        actions: [
          TextButton(
            onPressed: loading ? null : _save,
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '기본 정보를 입력해두면\n상담/커뮤니티/포트폴리오 구성에 자동으로 반영돼요.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          if (!p.isBasicComplete)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                '필수: 직업 · 지역 · 월수익 · 월급날',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

          const SizedBox(height: 14),

          TextField(
            controller: jobCtrl,
            decoration: const InputDecoration(
              labelText: '직업',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: companyCtrl,
            decoration: const InputDecoration(
              labelText: '회사(선택)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: regionCtrl,
            decoration: const InputDecoration(
              labelText: '지역',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: monthlyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration: const InputDecoration(
              labelText: '월수익(월급)',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: paydayCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '월급날(1~28)',
              helperText: '포트폴리오 계산 기준일입니다.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: sideCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration: const InputDecoration(
              labelText: '부수익(부업, 선택)',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: goalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration: const InputDecoration(
              labelText: '목표 저축 금액(선택)',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),
          if (error != null) ...[
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],

          FilledButton(
            onPressed: loading ? null : _save,
            child: const Text('저장하기'),
          ),
        ],
      ),
    );
  }
}
