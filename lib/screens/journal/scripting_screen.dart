import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/celebration.dart';
import '../../models/journal_entry.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/celebration_overlay.dart';

/// 369 스크립팅 전용 화면
/// 아침 3회 / 오후 6회 / 저녁 9회, 소망 문장을 반복해서 적으며 무의식에 새기는 리츄얼
class ScriptingScreen extends StatefulWidget {
  const ScriptingScreen({super.key});

  @override
  State<ScriptingScreen> createState() => _ScriptingScreenState();
}

class _ScriptingScreenState extends State<ScriptingScreen> {
  late TextEditingController _wishController;

  @override
  void initState() {
    super.initState();
    _wishController = TextEditingController(text: context.read<AppState>().scriptingWish);
  }

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  Future<void> _write(ScriptPeriod period) async {
    final wish = _wishController.text.trim();
    if (wish.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('먼저 오늘의 소망 문장을 적어주세요')));
      return;
    }
    final state = context.read<AppState>();
    await state.setScriptingWish(wish);
    if (!mounted) return;

    final controller = TextEditingController(text: wish);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${period.emoji} ${period.label} 스크립팅', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${state.scriptCountToday(period)}/${period.target}회 · 손으로 직접 적듯 한 번 더 써보세요', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(controller: controller, maxLines: 3, autofocus: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('적었어요'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.isEmpty) return;
    final wasAllComplete = state.scriptingAllCompleteToday;
    await state.addJournalEntry(type: JournalType.script, content: result, period: period.name);

    if (!wasAllComplete && state.scriptingAllCompleteToday && mounted) {
      CelebrationOverlay.show(context, CelebrationType.scriptingComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('369 스크립팅')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.beige.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
              child: const Text(
                '네빌 고다드의 369법: 이미 이루어진 것처럼 소망 문장을 아침 3번, 오후 6번, 저녁 9번 반복해서 적으며 무의식에 새겨보세요.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text('오늘의 소망 문장', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _wishController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '예: 나는 이미 원하는 회사에서 즐겁게 일하고 있다'),
              onChanged: (v) => context.read<AppState>().setScriptingWish(v),
            ),
            const SizedBox(height: 28),
            ...ScriptPeriod.values.map((p) => _periodCard(context, state, p)),
          ],
        ),
      ),
    );
  }

  Widget _periodCard(BuildContext context, AppState state, ScriptPeriod p) {
    final count = state.scriptCountToday(p);
    final done = count >= p.target;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: done ? AppColors.success.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: done ? AppColors.success.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Text(p.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${p.label} · ${p.target}회', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    if (done) const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (count / p.target).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.beige,
                    valueColor: AlwaysStoppedAnimation(done ? AppColors.success : AppColors.navy),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$count / ${p.target}회 완료', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: done ? null : () => _write(p),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('쓰기'),
          ),
        ],
      ),
    );
  }
}
