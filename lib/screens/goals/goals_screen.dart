import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/goal_card.dart';
import 'add_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('나의 목표')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGoalScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: state.goals.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text('아직 설정한 목표가 없어요', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                        '원하는 것을 구체적으로 적어보는 것부터\n현실 창조가 시작돼요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGoalScreen())),
                        child: const Text('첫 목표 만들기'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: state.goals.length,
                itemBuilder: (context, i) {
                  final g = state.goals[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalCard(
                      goal: g,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: g.id))),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
