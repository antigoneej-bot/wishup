import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';

/// AI 인사이트 엔진 (MVP: 온디바이스 규칙 기반)
/// - 저널/무드/습관/목표 데이터를 분석해 개인화된 통찰을 생성
/// - 추후 실제 LLM API 연동으로 고도화 가능한 인터페이스로 설계
class AiInsight {
  final String title;
  final String message;
  final InsightType type;

  AiInsight({required this.title, required this.message, required this.type});
}

enum InsightType { encouragement, reframe, pattern, celebration, nudge }

class AiInsightService {
  static const List<String> _limitingKeywords = [
    '못', '안될', '안 될', '불가능', '어렵', '힘들', '포기', '실패', 'never', "can't", '할수없',
  ];

  /// 종합 인사이트 생성 (홈 대시보드에 노출)
  static AiInsight generate({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
  }) {
    // 1. 최근 7일 무드 평균
    final recent = journalEntries.where(
      (e) => DateTime.now().difference(e.createdAt).inDays <= 7,
    ).toList();

    final avgMood = recent.isEmpty
        ? 3.0
        : recent.map((e) => e.moodScore).reduce((a, b) => a + b) / recent.length;

    // 2. 한계 신념 감지
    final limitingEntry = recent.where((e) => _limitingKeywords.any((k) => e.content.contains(k))).toList();
    if (limitingEntry.isNotEmpty) {
      return AiInsight(
        title: '🧠 리프레이밍 제안',
        message: '최근 기록에서 스스로를 제한하는 표현이 감지됐어요. "나는 ~할 수 없다" 대신 '
            '"나는 ~하는 방법을 배우고 있다"로 바꿔 다시 적어보면 어떨까요?',
        type: InsightType.reframe,
      );
    }

    // 3. 습관 완료율 기반
    if (habits.isNotEmpty) {
      final doneToday = habits.where((h) => h.isDoneToday()).length;
      final rate = doneToday / habits.length;
      if (rate == 1.0) {
        return AiInsight(
          title: '🔥 정체성이 강화되고 있어요',
          message: '오늘 모든 습관을 완료했어요! 작은 행동이 쌓여 당신이 원하는 정체성을 매일 증명하고 있습니다.',
          type: InsightType.celebration,
        );
      } else if (rate < 0.4 && avgMood < 3) {
        return AiInsight(
          title: '💛 오늘은 부드럽게',
          message: '최근 에너지가 조금 낮아 보여요. 완벽하지 않아도 괜찮아요. 습관 중 딱 하나만 골라 실천해보세요.',
          type: InsightType.nudge,
        );
      }
    }

    // 4. 목표 진행 정체 감지
    final stalled = goals.where((g) => g.progress > 0 && g.progress < 0.3 &&
        DateTime.now().difference(g.createdAt).inDays > 14).toList();
    if (stalled.isNotEmpty) {
      return AiInsight(
        title: '📊 패턴 분석',
        message: '"${stalled.first.title}" 목표가 2주 이상 큰 변화가 없어요. '
            '목표를 더 작은 행동 단위로 나눠보면 다시 흐름을 만들 수 있어요.',
        type: InsightType.pattern,
      );
    }

    // 5. 기본 격려
    if (avgMood >= 4) {
      return AiInsight(
        title: '✨ 좋은 흐름이에요',
        message: '최근 감정 에너지가 높아요. 지금 느끼는 확신을 오늘의 확언과 비전보드에 다시 새겨보세요.',
        type: InsightType.encouragement,
      );
    }

    return AiInsight(
      title: '🌙 오늘의 통찰',
      message: '매일의 작은 기록이 무의식을 재프로그래밍합니다. 오늘 감사한 일 한 가지를 적어보세요.',
      type: InsightType.encouragement,
    );
  }

  /// 0~100 "에너지/바이브레이션 스코어" 산출
  static int energyScore({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
  }) {
    if (goals.isEmpty && habits.isEmpty && journalEntries.isEmpty) return 50;

    final recent = journalEntries.where(
      (e) => DateTime.now().difference(e.createdAt).inDays <= 7,
    ).toList();
    final moodScore = recent.isEmpty
        ? 50.0
        : (recent.map((e) => e.moodScore).reduce((a, b) => a + b) / recent.length) / 5 * 100;

    final habitScore = habits.isEmpty
        ? 50.0
        : habits.where((h) => h.isDoneToday()).length / habits.length * 100;

    final goalScore = goals.isEmpty
        ? 50.0
        : goals.map((g) => g.progress).reduce((a, b) => a + b) / goals.length * 100;

    final score = (moodScore * 0.4 + habitScore * 0.35 + goalScore * 0.25);
    return score.clamp(0, 100).round();
  }
}
