// AI 인사이트 / 에너지 스코어 로직 회귀 테스트.
// 홈 대시보드의 핵심 위젯(에너지 링, 오늘의 인사이트 카드)이 의존하는
// 순수 로직이므로, 여기서 회귀가 생기면 전체 홈 화면 체감 품질에 영향을 준다.
import 'package:flutter_test/flutter_test.dart';
import 'package:wishup/models/goal.dart';
import 'package:wishup/models/habit.dart';
import 'package:wishup/models/journal_entry.dart';
import 'package:wishup/services/ai_insight_service.dart';

Goal _goal({double progress = 0.0, DateTime? createdAt}) => Goal(
      id: 'g',
      title: '목표',
      identityStatement: '나는 목표를 이루는 사람이다',
      category: GoalCategory.growth,
      progress: progress,
      createdAt: createdAt,
    );

Habit _habit({bool doneToday = false}) => Habit(
      id: 'h',
      title: '습관',
      completedDates: doneToday ? [_todayStr()] : [],
    );

String _todayStr() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

JournalEntry _journal({required int moodScore, String content = '오늘도 감사한 하루', DateTime? createdAt}) =>
    JournalEntry(id: 'j', type: JournalType.gratitude, content: content, moodScore: moodScore, createdAt: createdAt);

void main() {
  group('AiInsightService.energyScore', () {
    test('모든 데이터가 비어있으면 중립값 50을 반환한다', () {
      final score = AiInsightService.energyScore(goals: [], habits: [], journalEntries: []);
      expect(score, 50);
    });

    test('습관을 모두 완료하고 목표 진행률/무드가 높으면 점수가 높다', () {
      final score = AiInsightService.energyScore(
        goals: [_goal(progress: 1.0)],
        habits: [_habit(doneToday: true), _habit(doneToday: true)],
        journalEntries: [_journal(moodScore: 5)],
      );
      expect(score, greaterThanOrEqualTo(90));
      expect(score, lessThanOrEqualTo(100));
    });

    test('습관을 모두 건너뛰고 무드가 낮으면 점수가 낮다', () {
      final score = AiInsightService.energyScore(
        goals: [_goal(progress: 0.0)],
        habits: [_habit(doneToday: false), _habit(doneToday: false)],
        journalEntries: [_journal(moodScore: 1)],
      );
      expect(score, lessThanOrEqualTo(20));
    });

    test('점수는 항상 0~100 범위 안에 있다(clamp 검증)', () {
      final score = AiInsightService.energyScore(
        goals: [_goal(progress: 1.0), _goal(progress: 1.0)],
        habits: [_habit(doneToday: true)],
        journalEntries: [_journal(moodScore: 5), _journal(moodScore: 5)],
      );
      expect(score, inInclusiveRange(0, 100));
    });

    test('7일 이전 저널은 무드 평균 계산에서 제외된다', () {
      final oldEntry = _journal(moodScore: 1, createdAt: DateTime.now().subtract(const Duration(days: 30)));
      final scoreWithOnlyOldEntry = AiInsightService.energyScore(
        goals: [],
        habits: [],
        journalEntries: [oldEntry],
      );
      // 최근 데이터가 없으므로 저널 항목이 있어도 중립(50) 기준으로 계산되어야 한다
      final scoreEmpty = AiInsightService.energyScore(goals: [], habits: [], journalEntries: []);
      expect(scoreWithOnlyOldEntry, scoreEmpty);
    });
  });

  group('AiInsightService.generate', () {
    test('제한적 신념 키워드가 감지되면 리프레이밍 인사이트를 반환한다', () {
      final insight = AiInsightService.generate(
        goals: [],
        habits: [],
        journalEntries: [_journal(moodScore: 3, content: '오늘도 목표에 실패한 것 같아')],
      );
      expect(insight.type, InsightType.reframe);
    });

    test('오늘 모든 습관을 완료하면 축하 인사이트를 반환한다', () {
      final insight = AiInsightService.generate(
        goals: [],
        habits: [_habit(doneToday: true), _habit(doneToday: true)],
        journalEntries: [],
      );
      expect(insight.type, InsightType.celebration);
    });

    test('습관 완료율이 낮고 무드도 낮으면 부드러운 넛지를 반환한다', () {
      final insight = AiInsightService.generate(
        goals: [],
        habits: [_habit(doneToday: false), _habit(doneToday: false), _habit(doneToday: true)],
        journalEntries: [_journal(moodScore: 1)],
      );
      expect(insight.type, InsightType.nudge);
    });

    test('2주 이상 정체된 목표가 있으면 패턴 분석 인사이트를 반환한다', () {
      final insight = AiInsightService.generate(
        goals: [_goal(progress: 0.1, createdAt: DateTime.now().subtract(const Duration(days: 20)))],
        habits: [],
        journalEntries: [],
      );
      expect(insight.type, InsightType.pattern);
    });

    test('데이터가 전혀 없으면 기본 격려 인사이트를 반환하며 크래시하지 않는다', () {
      final insight = AiInsightService.generate(goals: [], habits: [], journalEntries: []);
      expect(insight.title, isNotEmpty);
      expect(insight.message, isNotEmpty);
    });
  });
}
