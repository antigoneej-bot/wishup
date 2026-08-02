// 데이터 모델 직렬화(toMap/fromMap) 회귀 테스트.
//
// WishUp은 백엔드 없이 Hive에 Map 형태로 저장하므로, toMap/fromMap 왕복이
// 깨지면 "저장했는데 다음 실행 시 데이터가 사라지거나 크래시" 하는
// 치명적 버그로 이어진다. 실기기 QA 전에 가장 먼저 잡아야 하는 영역.
import 'package:flutter_test/flutter_test.dart';
import 'package:wishup/models/goal.dart';
import 'package:wishup/models/habit.dart';
import 'package:wishup/models/journal_entry.dart';
import 'package:wishup/models/vision_item.dart';
import 'package:wishup/models/universe_letter.dart';

void main() {
  group('Milestone 직렬화', () {
    test('toMap -> fromMap 왕복 시 값이 보존된다', () {
      final m = Milestone(id: 'm1', title: '첫 발걸음', isDone: true);
      final restored = Milestone.fromMap(m.toMap());
      expect(restored.id, 'm1');
      expect(restored.title, '첫 발걸음');
      expect(restored.isDone, true);
    });

    test('isDone 누락 시 기본값 false로 안전하게 복원된다', () {
      final restored = Milestone.fromMap({'id': 'm2', 'title': '제목만 있음'});
      expect(restored.isDone, false);
    });
  });

  group('Goal 직렬화', () {
    test('마일스톤을 포함한 목표가 온전히 왕복된다', () {
      final goal = Goal(
        id: 'g1',
        title: '경제적 자유 달성',
        identityStatement: '나는 풍요를 끌어당기는 사람이다',
        category: GoalCategory.wealth,
        progress: 0.42,
        targetDate: DateTime(2026, 12, 31),
        milestones: [Milestone(id: 'm1', title: '첫 마일스톤')],
      );

      final restored = Goal.fromMap(goal.toMap());

      expect(restored.id, 'g1');
      expect(restored.title, '경제적 자유 달성');
      expect(restored.category, GoalCategory.wealth);
      expect(restored.progress, closeTo(0.42, 0.0001));
      expect(restored.targetDate, DateTime(2026, 12, 31));
      expect(restored.milestones, hasLength(1));
      expect(restored.milestones.first.title, '첫 마일스톤');
      expect(restored.isArchived, false);
    });

    test('targetDate가 null이어도 크래시 없이 복원된다', () {
      final goal = Goal(
        id: 'g2',
        title: '무기한 목표',
        identityStatement: '나는 성장하는 사람이다',
        category: GoalCategory.growth,
      );
      final restored = Goal.fromMap(goal.toMap());
      expect(restored.targetDate, isNull);
    });

    test('알 수 없는 category 문자열은 growth로 안전하게 폴백된다', () {
      final restored = Goal.fromMap({
        'id': 'g3',
        'title': '깨진 데이터',
        'category': 'unknown_category_value',
      });
      expect(restored.category, GoalCategory.growth);
      // 필수값 누락 시에도 identityStatement가 빈 문자열로 안전 처리되어야 함
      expect(restored.identityStatement, '');
    });
  });

  group('Habit 직렬화', () {
    test('스트릭과 완료일 목록이 온전히 왕복된다', () {
      final habit = Habit(
        id: 'h1',
        title: '아침 확언 읽기',
        streak: 7,
        completedDates: ['2026-08-01', '2026-08-02'],
        lastCompletedAt: DateTime(2026, 8, 2),
      );
      final restored = Habit.fromMap(habit.toMap());

      expect(restored.streak, 7);
      expect(restored.completedDates, ['2026-08-01', '2026-08-02']);
      expect(restored.lastCompletedAt, DateTime(2026, 8, 2));
    });

    test('completedDates가 없는 맵도 빈 리스트로 안전하게 처리된다', () {
      final restored = Habit.fromMap({'id': 'h2', 'title': '새 습관'});
      expect(restored.completedDates, isEmpty);
      expect(restored.streak, 0);
    });

    test('isDoneToday()는 오늘 날짜가 completedDates에 있을 때만 true', () {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final habit = Habit(id: 'h3', title: '테스트', completedDates: [todayStr]);
      expect(habit.isDoneToday(), true);

      final habitNotDone = Habit(id: 'h4', title: '테스트2', completedDates: []);
      expect(habitNotDone.isDoneToday(), false);
    });
  });

  group('JournalEntry 직렬화', () {
    test('369 스크립팅 엔트리가 period 포함 온전히 왕복된다', () {
      final entry = JournalEntry(
        id: 'j1',
        type: JournalType.script,
        content: '나는 매일 성장한다',
        moodScore: 5,
        period: ScriptPeriod.morning.name,
      );
      final restored = JournalEntry.fromMap(entry.toMap());

      expect(restored.type, JournalType.script);
      expect(restored.period, 'morning');
      expect(restored.moodScore, 5);
    });

    test('알 수 없는 type은 gratitude로 폴백된다', () {
      final restored = JournalEntry.fromMap({
        'id': 'j2',
        'type': 'not_a_real_type',
        'content': '내용',
      });
      expect(restored.type, JournalType.gratitude);
    });
  });

  group('VisionItem 직렬화', () {
    test('asset 이미지 플래그가 올바르게 왕복된다', () {
      final item = VisionItem(id: 'v1', imagePath: 'assets/images/vision_examples/wealth.jpg', caption: '풍요', isAssetImage: true);
      final restored = VisionItem.fromMap(item.toMap());
      expect(restored.isAssetImage, true);
      expect(restored.caption, '풍요');
    });

    test('VisionExample.all은 4개의 카테고리를 제공한다', () {
      expect(VisionExample.all, hasLength(4));
      final ids = VisionExample.all.map((e) => e.id).toSet();
      expect(ids, {'ex_wealth', 'ex_health', 'ex_career', 'ex_love'});
    });
  });

  group('UniverseLetter 직렬화 & 우주의 답장', () {
    test('열람일 이전에는 isUnlocked가 false다', () {
      final letter = UniverseLetter(
        id: 'l1',
        content: '내년 이맘때 나에게',
        openDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(letter.isUnlocked, false);
    });

    test('열람일이 지나면 isUnlocked가 true다', () {
      final letter = UniverseLetter(
        id: 'l2',
        content: '과거의 나에게',
        openDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(letter.isUnlocked, true);
    });

    test('replyMessage는 생성 시 자동으로 채워지고 직렬화 후에도 보존된다', () {
      final letter = UniverseLetter(id: 'l3', content: '소원', openDate: DateTime.now());
      expect(letter.replyMessage, isNotEmpty);

      final restored = UniverseLetter.fromMap(letter.toMap());
      expect(restored.replyMessage, letter.replyMessage);
    });

    test('UniverseReply.generate()는 매번 비어있지 않은 문자열을 반환한다', () {
      for (var i = 0; i < 20; i++) {
        expect(UniverseReply.generate(), isNotEmpty);
      }
    });
  });
}
