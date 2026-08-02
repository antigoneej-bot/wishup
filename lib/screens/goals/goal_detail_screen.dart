import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/affirmation_service.dart';
import '../../services/calendar_service.dart';
import '../../widgets/celebration_overlay.dart';
import '../journal/add_journal_entry_screen.dart';
import '../../models/journal_entry.dart';

class GoalDetailScreen extends StatelessWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  Future<void> _toggleMilestone(BuildContext context, String milestoneId) async {
    final celebration = await context.read<AppState>().toggleMilestone(goalId, milestoneId);
    if (celebration != null && context.mounted) {
      CelebrationOverlay.show(context, celebration);
    }
  }

  Future<void> _addToCalendar(BuildContext context, Goal goal) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('캘린더 연동은 Android 앱에서 이용할 수 있어요')));
      return;
    }
    final ok = await CalendarService.addEvent(
      title: goal.title,
      description: goal.identityStatement,
      date: goal.targetDate!,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '캘린더 앱이 열렸어요' : '캘린더를 열 수 없어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goal = state.goals.firstWhere((g) => g.id == goalId);
    final color = AppColors.categoryColors[goal.category.index % AppColors.categoryColors.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(goal.category.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await context.read<AppState>().deleteGoal(goal.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(goal.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Text('🪞 ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(goal.identityStatement, style: TextStyle(fontStyle: FontStyle.italic, color: color, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 10,
                      backgroundColor: AppColors.beige,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(goal.progress * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _addToCalendar(context, goal),
                icon: const Icon(Icons.event_available, size: 16),
                label: Text('${goal.targetDate!.year}.${goal.targetDate!.month}.${goal.targetDate!.day} 캘린더에 추가'),
              ),
            ],
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('마일스톤', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                TextButton.icon(
                  onPressed: () => _showAddMilestone(context, goal.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('추가'),
                ),
              ],
            ),
            if (goal.milestones.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('작은 단계로 나눠보면 진행이 더 쉬워져요', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ...goal.milestones.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: m.isDone,
                    onChanged: (_) => _toggleMilestone(context, m.id),
                    title: Text(m.title, style: TextStyle(decoration: m.isDone ? TextDecoration.lineThrough : null)),
                    activeColor: AppColors.navy,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                )),
            const SizedBox(height: 20),

            const Text('이 목표를 위한 확언', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            ...AffirmationService.all(goal.category).take(3).map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.beige.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                  child: Text('"$a"', style: const TextStyle(fontSize: 13.5, height: 1.4)),
                )),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddJournalEntryScreen(
                    initialType: JournalType.evidence,
                    linkedGoalId: goal.id,
                  )),
                ),
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('현실화 증거 기록하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestone(BuildContext context, String goalId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('새 마일스톤', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '작은 단계를 적어보세요')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    context.read<AppState>().addMilestone(goalId, controller.text.trim());
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
