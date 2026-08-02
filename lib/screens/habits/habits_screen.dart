import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/habit_tile.dart';
import '../../widgets/celebration_overlay.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('정체성 습관')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () => _showAddHabit(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.beige.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Text('🔁 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      '습관은 정체성을 매일 증명하는 증거입니다. "나는 ~한 사람이다"를 행동으로 보여주세요.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.habits.isEmpty
                  ? const Center(child: Text('아직 습관이 없어요. + 버튼으로 추가해보세요', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: state.habits.length,
                      itemBuilder: (context, i) {
                        final h = state.habits[i];
                        return HabitTile(
                          habit: h,
                          onToggle: () async {
                            final celebration = await context.read<AppState>().toggleHabitToday(h.id);
                            if (celebration != null && context.mounted) {
                              CelebrationOverlay.show(context, celebration);
                            }
                          },
                          onDelete: () => context.read<AppState>().deleteHabit(h.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabit(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
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
            const Text('새 습관', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('예: "나는 건강한 사람이다" → 물 8잔 마시기', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '습관을 적어보세요')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    context.read<AppState>().addHabit(controller.text.trim());
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('추가하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
