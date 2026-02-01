//C:\Users\user\asset_secretary\lib\features\experts\experts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/experts_provider.dart';
import '../../utils/money_input_formatter.dart';
import '../../models/expert_request.dart';

class ExpertsScreen extends ConsumerWidget {
  const ExpertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experts = ref.watch(expertsProvider);
    final requests = ref.watch(expertRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('전문가')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            '전문가 목록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...experts.map(
            (e) => Card(
              child: ListTile(
                title: Text('${e.name} • ${e.field}'),
                subtitle: const Text('상담 요청을 보내면 “대기” 상태로 저장됩니다.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final req = await _openExpertRequestForm(context, e.id);
                  if (req == null) return;

                  await ref.read(expertRequestsProvider.notifier).add(req);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('상담 요청이 접수됐어요.')),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '내 상담 요청',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty) const Text('아직 요청이 없어요.'),
          ...requests.map(
            (r) => Card(
              child: ListTile(
                title: const Text('상태: 대기'),
                subtitle: Text(r.message.isEmpty ? '(내용 없음)' : r.message),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<ExpertRequest?> _openExpertRequestForm(
    BuildContext context,
    String expertId,
  ) async {
    final incomeCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    const purposes = ['비상금', '주택/전세', '결혼', '여행', '학자금/자격증', '투자 종잣돈', '기타'];
    const savingStatuses = ['저축 거의 못함', '가끔 저축', '꾸준히 저축 중', '저축 충분(운용 고민)'];
    const spendingStatuses = ['매우 절제', '보통', '충동 소비 있음', '소비 통제 어려움'];

    String purpose = purposes[0];
    String savingStatus = savingStatuses[1];
    String spendingStatus = spendingStatuses[1];

    return showDialog<ExpertRequest>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          scrollable: true,
          title: const Text('상담 요청'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: incomeCtrl,
                  decoration: const InputDecoration(labelText: '월수익(원)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: targetCtrl,
                  decoration: const InputDecoration(labelText: '목표금액(원)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: purpose,
                  decoration: const InputDecoration(labelText: '저축 목적'),
                  items: purposes
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) => setState(() => purpose = v ?? purposes[0]),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: savingStatus,
                  decoration: const InputDecoration(labelText: '현재 저축 상태'),
                  items: savingStatuses
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => savingStatus = v ?? savingStatuses[0]),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: spendingStatus,
                  decoration: const InputDecoration(labelText: '현재 소비 상태'),
                  items: spendingStatuses
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => spendingStatus = v ?? spendingStatuses[0]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  decoration: const InputDecoration(labelText: '요청 내용'),
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final income =
                    int.tryParse(incomeCtrl.text.replaceAll(',', '').trim()) ??
                        0;
                final target =
                    int.tryParse(targetCtrl.text.replaceAll(',', '').trim()) ??
                        0;

                if (target <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('목표금액을 입력해주세요.')),
                  );
                  return;
                }

                final req = ExpertRequest(
                  id: const Uuid().v4(),
                  expertId: expertId,
                  createdAtMs: DateTime.now().millisecondsSinceEpoch,
                  monthlyIncomeWon: income,
                  targetAmountWon: target,
                  purpose: purpose,
                  savingStatus: savingStatus,
                  spendingStatus: spendingStatus,
                  message: msgCtrl.text.trim(),
                );

                Navigator.pop(ctx, req);
              },
              child: const Text('요청'),
            ),
          ],
        ),
      ),
    );
  }
}
