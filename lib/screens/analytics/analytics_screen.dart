import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../premium/paywall_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final days = 14;
    final moodSpots = <FlSpot>[];
    final habitBars = <BarChartGroupData>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayKey = _fmt(date);
      final dayEntries = state.journalEntries.where((e) => _fmt(e.createdAt) == dayKey).toList();
      final avgMood = dayEntries.isEmpty
          ? null
          : dayEntries.map((e) => e.moodScore).reduce((a, b) => a + b) / dayEntries.length;
      moodSpots.add(FlSpot((days - 1 - i).toDouble(), avgMood ?? 0));
    }

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayKey = _fmt(date);
      final count = state.habits.where((h) => h.completedDates.contains(dayKey)).length;
      habitBars.add(BarChartGroupData(x: 6 - i, barRods: [
        BarChartRodData(toY: count.toDouble(), color: AppColors.navy, width: 14, borderRadius: BorderRadius.circular(4)),
      ]));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('현실화 분석')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          children: [
            _summaryRow(state),
            const SizedBox(height: 20),
            if (!state.isPremium) _premiumBanner(context),
            const SizedBox(height: 8),

            const Text('최근 14일 감정 흐름', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('감사일기/저널을 기록한 날의 평균 감정 점수', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 5,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: moodSpots,
                      isCurved: true,
                      color: AppColors.navy,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppColors.navy.withValues(alpha: 0.08)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text('최근 7일 습관 완료', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: habitBars,
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text('목표별 진행률', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),
            if (state.goals.isEmpty)
              const Text('아직 목표가 없어요', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
            else
              ...state.goals.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(g.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('${(g.progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: g.progress,
                            minHeight: 8,
                            backgroundColor: AppColors.beige,
                            valueColor: const AlwaysStoppedAnimation(AppColors.navy),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _premiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            triggerReason: '목표·습관을 더 많이 기록할수록 인사이트가 더 깊어져요.\n프리미엄으로 제한 없이 기록해보세요.',
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, color: AppColors.gold, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '기록이 쌓일수록 분석이 정교해져요. 프리미엄으로 목표·습관 제한 없이 기록해보세요.',
                style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(AppState state) {
    return Row(
      children: [
        _statCard('에너지 스코어', '${state.energyScore}', AppColors.navy),
        const SizedBox(width: 10),
        _statCard('총 기록 수', '${state.journalEntries.length}', AppColors.gold),
        const SizedBox(width: 10),
        _statCard('활성 목표', '${state.goals.length}', AppColors.success),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
