import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/affirmation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/energy_ring.dart';
import '../../widgets/ai_insight_card.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/habit_tile.dart';
import '../../widgets/section_header.dart';
import '../goals/goals_screen.dart';
import '../goals/goal_detail_screen.dart';
import '../goals/add_goal_screen.dart';
import '../habits/habits_screen.dart';
import '../affirmations/affirmations_screen.dart';
import '../vision_board/vision_board_screen.dart';
import '../analytics/analytics_screen.dart';
import '../universe_letter/universe_letter_screen.dart';
import '../journal/scripting_screen.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/affirmation_share_card.dart';
import '../../services/share_service.dart';
import '../../models/ritual_audio.dart';
import '../rituals/rituals_screen.dart';
import '../rituals/ritual_player_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final greeting = _greeting();
    final affirmation = AffirmationService.dailyAffirmation(preferredCategory: state.primaryFocus);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<AppState>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting, ${state.userName}님', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('오늘도 현실을 창조해봐요 ✦', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (state.moonPhaseInfo.ritualMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.moonPhaseInfo.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('오늘은 ${state.moonPhaseInfo.phaseName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 4),
                            Text(state.moonPhaseInfo.ritualMessage!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 에너지 스코어
              Center(child: EnergyRing(score: state.energyScore)),
              const SizedBox(height: 24),

              // AI 인사이트
              AiInsightCard(insight: state.todaysInsight),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _quickAction(context, '📊', '현실화 분석', () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickAction(context, '✉️', '우주에 편지쓰기', () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UniverseLetterScreen()))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickAction(context, '📝', '369 스크립팅', () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScriptingScreen()))),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 오늘의 확언
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('☀️ 오늘의 확언', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => ShareService.shareAsCard(context, AffirmationShareCard(text: affirmation), text: '오늘의 확언 · WishUp'),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.ios_share, size: 17, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AffirmationsScreen())),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('"$affirmation"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 리츄얼 오디오
              SectionHeader(
                title: '🎧 리츄얼 오디오',
                actionLabel: '더보기',
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RitualsScreen())),
              ),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: RitualAudio.all
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RitualPlayerScreen(ritual: r))),
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.navy.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Text(r.emoji, style: const TextStyle(fontSize: 28)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(r.durationLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.play_circle_fill, color: AppColors.navy, size: 26),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 목표
              SectionHeader(
                title: '나의 목표',
                actionLabel: '전체보기',
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
              ),
              if (state.goals.isEmpty)
                _emptyCard(
                  context,
                  '아직 설정한 목표가 없어요',
                  '첫 목표를 만들고 정체성 선언문을 적어보세요',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGoalScreen())),
                )
              else
                ...state.goals.take(3).map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GoalCard(
                        goal: g,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: g.id))),
                      ),
                    )),
              const SizedBox(height: 24),

              // 습관
              SectionHeader(
                title: '오늘의 습관',
                actionLabel: '관리하기',
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen())),
              ),
              if (state.habits.isEmpty)
                _emptyCard(
                  context,
                  '정체성을 증명할 습관을 만들어보세요',
                  '작은 행동이 매일 당신을 원하는 사람으로 만들어요',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen())),
                )
              else
                ...state.habits.take(3).map((h) => HabitTile(
                      habit: h,
                      onToggle: () async {
                        final celebration = await context.read<AppState>().toggleHabitToday(h.id);
                        if (celebration != null && context.mounted) {
                          CelebrationOverlay.show(context, celebration);
                        }
                      },
                    )),
              const SizedBox(height: 24),

              // 비전보드 바로가기
              SectionHeader(title: '비전보드', actionLabel: '보러가기', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisionBoardScreen()))),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisionBoardScreen())),
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.navy.withValues(alpha: 0.1)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    state.visionItems.isEmpty ? '🖼  이미 이루어진 것처럼, 비전보드를 채워보세요' : '🖼  ${state.visionItems.length}개의 비전이 담겨있어요',
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String title, String subtitle, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.add_circle, color: AppColors.navy),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return '고요한 새벽';
    if (h < 12) return '좋은 아침';
    if (h < 18) return '활기찬 오후';
    return '편안한 저녁';
  }
}
