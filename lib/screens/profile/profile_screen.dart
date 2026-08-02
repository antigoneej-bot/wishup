import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../vision_board/vision_board_screen.dart';
import '../habits/habits_screen.dart';
import '../affirmations/affirmations_screen.dart';
import '../analytics/analytics_screen.dart';
import '../universe_letter/universe_letter_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/level_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('마이')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(state.userName.isNotEmpty ? state.userName.characters.first : '✦',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('에너지 스코어 ${state.energyScore}점', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            LevelBadge(points: state.totalPoints),
            const SizedBox(height: 20),

            Row(
              children: [
                _statBox('목표', '${state.goals.length}'),
                const SizedBox(width: 10),
                _statBox('습관', '${state.habits.length}'),
                const SizedBox(width: 10),
                _statBox('기록', '${state.journalEntries.length}'),
              ],
            ),
            const SizedBox(height: 28),

            const Text('관심 영역', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.focusAreas.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(12)),
                    child: Text('${c.emoji} ${c.label}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  )).toList(),
            ),
            const SizedBox(height: 28),

            const Text('둘러보기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            _menuTile(context, Icons.image_outlined, '비전보드', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisionBoardScreen()))),
            _menuTile(context, Icons.check_circle_outline, '정체성 습관', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen()))),
            _menuTile(context, Icons.auto_awesome_outlined, '확언 라이브러리', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AffirmationsScreen()))),
            _menuTile(context, Icons.insights_outlined, '현실화 분석', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
            _menuTile(context, Icons.mail_outline, '우주에 편지쓰기', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UniverseLetterScreen()))),
            _menuTile(context, Icons.settings_outlined, '설정', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.navy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
