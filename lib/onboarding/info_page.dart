//asset_secretary\lib\onboarding\info_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'money_formatter.dart';
import 'fixed_costs_page.dart';

enum InfoPageMode { onboarding, edit }

class InfoPage extends StatefulWidget {
  const InfoPage({super.key, required this.mode});
  final InfoPageMode mode;

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  static const bgTop = Color(0xFF0A1730);
  static const bgBottom = Color(0xFF070F1F);
  static const accent = Color(0xFF0AA3E3);

  bool _loading = true;
  bool _saving = false;

  // 내부 스텝: 0 = 2/5(개인정보), 1 = 3/5(자산선택)
  int _stepIndex = 0;

  final _ageCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _mainIncomeCtrl = TextEditingController();
  final _subIncomeCtrl = TextEditingController();

  static const assetItems = [
    '금',
    'ELS',
    '채권',
    '가상화폐',
    '펀드',
    '예금',
    '적금',
    '주식',
    '부동산',
    '기타',
  ];
  final Set<String> _selectedAssets = {};
  final Map<String, TextEditingController> _assetCtrls = {
    for (final k in assetItems) k: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _jobCtrl.dispose();
    _regionCtrl.dispose();
    _mainIncomeCtrl.dispose();
    _subIncomeCtrl.dispose();
    super.dispose();
    for (final c in _assetCtrls.values) {c.dispose();}

  }

  Future<void> _prefill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};

    _ageCtrl.text = (profile['age'] ?? '').toString();
    _jobCtrl.text = (profile['job'] ?? '').toString();
    _regionCtrl.text = (profile['region'] ?? '').toString();

    final mainIncome = (profile['mainIncome'] as num?)?.toInt() ?? 0;
    final subIncome = (profile['subIncome'] as num?)?.toInt() ?? 0;

    if (mainIncome > 0) {
      _mainIncomeCtrl.text = ThousandsFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: mainIncome.toString()),
      ).text;
    }
    if (subIncome > 0) {
      _subIncomeCtrl.text = ThousandsFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: subIncome.toString()),
      ).text;
    }

    final tools = (profile['managementTools'] as Map<String, dynamic>?) ?? {};
    for (final k in tools.keys) {
      if (!assetItems.contains(k)) continue;
      _selectedAssets.add(k);

      final v = (tools[k] is num) ? (tools[k] as num).toInt() : 0;
      if (v > 0) {
        _assetCtrls[k]!.text = ThousandsFormatter().formatEditUpdate(
          const TextEditingValue(text: ''),
          TextEditingValue(text: v.toString()),
        ).text;
      } else {
        _assetCtrls[k]!.text = '';
      }
    }
    

    if (mounted) setState(() => _loading = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool get _personalValid {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final job = _jobCtrl.text.trim();
    final region = _regionCtrl.text.trim();
    final mainIncome = parseMoney(_mainIncomeCtrl.text);
    return age > 0 && job.isNotEmpty && region.isNotEmpty && mainIncome > 0;
  }

  Future<void> _next() async {
    if (_stepIndex == 0) {
      if (!_personalValid) {
        _snack('나이/직업/거주지역/주수익은 필수야.');
        return;
      }
      setState(() => _stepIndex = 1);
      return;
    }

    // ✅ 3/5 -> 4/5 이동 (저장은 4/5에서)
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final job = _jobCtrl.text.trim();
    final region = _regionCtrl.text.trim();
    final mainIncome = parseMoney(_mainIncomeCtrl.text);
    final subIncome = parseMoney(_subIncomeCtrl.text);
    final assets = <String, int>{
      for (final k in _selectedAssets) k: parseMoney(_assetCtrls[k]!.text),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FixedCostsPage(
          age: age,
          job: job,
          region: region,
          mainIncome: mainIncome,
          subIncome: subIncome,
          selectedAssets: _selectedAssets.toList(),
          selectedAssetsMoney: assets,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_stepIndex > 0) {
      setState(() => _stepIndex = 0);
      return false;
    }
    return widget.mode == InfoPageMode.edit;
  }

  // 스타일 helpers
  BoxDecoration get _cardDeco => BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      );

  InputDecoration _fieldDec(String label, {String? hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
      hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
      filled: true,
      fillColor: const Color(0x1AFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accent),
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
    );
  }

  Widget _topProgress() {
    if (widget.mode == InfoPageMode.edit) return const SizedBox.shrink();

    final stepText = _stepIndex == 0 ? '2/5' : '3/5';
    final section = _stepIndex == 0 ? '기본 정보' : '자산 정보';
    final progress = _stepIndex == 0 ? 0.40 : 0.60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(section, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(stepText, style: const TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0x1FFFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('개인 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 14),

            TextField(
              controller: _ageCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _fieldDec('나이'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _jobCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDec('직업'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _regionCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDec('거주 지역'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _mainIncomeCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
              decoration: _fieldDec(
                '주 수익 (월)',
                prefix: const Icon(Icons.attach_money, color: Color(0xFF3EDC85), size: 20),
                suffix: const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('₩', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
                ),
              ),
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _subIncomeCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
              decoration: _fieldDec(
                '부 수익 (월) (선택사항)',
                prefix: const Icon(Icons.monetization_on_outlined, color: Color(0xFFFFD54A), size: 20),
                suffix: const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('₩', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
                ),
              ),
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assetStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: accent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text('현재 관리 중인 자산', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '현재 관리 자산을 선택하고 금액을 입력해주세요 (선택사항)',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
            ),
            const SizedBox(height: 12),

            ...assetItems.map((label) {
              final checked = _selectedAssets.contains(label);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (checked) {
                        _selectedAssets.remove(label);
                      } else {
                        _selectedAssets.add(label);
                      }
                    });
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Checkbox(
                          value: checked,
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                _selectedAssets.remove(label);
                                _assetCtrls[label]!.text = '';
                              } else {
                                _selectedAssets.add(label);
                              }
                            });
                          },
                          activeColor: accent,
                          checkColor: Colors.white,
                          side: const BorderSide(color: Color(0x66FFFFFF)),
                        ),
                        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (checked) _moneyBox(_assetCtrls[label]!),
                        const SizedBox(width: 10),
                      ],
                    ),

                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton() {
    final enabled = _stepIndex == 0 ? _personalValid : true;

    return Positioned(
      left: 18,
      right: 18,
      bottom: 18,
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: const Color(0xFF103A4D),
            disabledForegroundColor: const Color(0x66FFFFFF),
          ),
          onPressed: (_saving || !enabled) ? null : _next,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('다음', style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(width: 8),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == InfoPageMode.onboarding ? '회원가입' : '나의 정보 수정';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.account_balance_wallet_rounded, color: accent, size: 18),
              SizedBox(width: 8),
              Text('회원가입', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgBottom],
            ),
          ),
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : AbsorbPointer(
                    absorbing: _saving,
                    child: Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(top: 8),
                          children: [
                            _topProgress(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _stepIndex == 0 ? _personalStep() : _assetStep(),
                            ),
                          ],
                        ),
                        _bottomButton(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  Widget _moneyBox(TextEditingController ctrl) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
          filled: true,
          fillColor: const Color(0x1AFFFFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x33FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent),
          ),
          suffixText: '원',
          suffixStyle: const TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

}
