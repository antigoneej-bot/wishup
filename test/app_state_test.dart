// AppState 핵심 CRUD / 게이미피케이션 로직 회귀 테스트.
//
// 목표·습관·저널·비전보드·우주편지는 앱의 핵심 사용자 흐름(critical path)이다.
// 여기서 회귀가 생기면 "데이터가 저장이 안 됨", "스트릭이 잘못 계산됨",
// "무료 한도가 뚫림" 같은 사용자 체감 버그로 즉시 이어진다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wishup/models/celebration.dart';
import 'package:wishup/models/goal.dart';
import 'package:wishup/models/journal_entry.dart';
import 'package:wishup/providers/app_state.dart';
import 'package:wishup/services/entitlement_service.dart';

import 'test_helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;
  late AppState appState;

  setUp(() async {
    tempDir = await initHiveForTest();
    await clearHiveBoxesForTest();
    appState = AppState();
    await appState.load();
  });

  tearDown(() async {
    await closeHiveForTest(tempDir);
  });

  group('온보딩', () {
    test('completeOnboarding 이후 이름/영역/완료플래그가 저장되고 재로딩 후에도 유지된다', () async {
      await appState.completeOnboarding(name: '민지', areas: [GoalCategory.wealth, GoalCategory.health]);

      expect(appState.userName, '민지');
      expect(appState.onboardingCompleted, true);
      expect(appState.focusAreas, [GoalCategory.wealth, GoalCategory.health]);

      // 앱을 재시작한 것처럼 새 AppState 인스턴스로 다시 로드해도 값이 남아있어야 한다
      final reloaded = AppState();
      await reloaded.load();
      expect(reloaded.userName, '민지');
      expect(reloaded.onboardingCompleted, true);
      expect(reloaded.focusAreas, [GoalCategory.wealth, GoalCategory.health]);
    });
  });

  group('목표(Goals) CRUD', () {
    test('addGoal은 목록 맨 앞에 추가되고 Hive에도 영속화된다', () async {
      await appState.addGoal(title: '첫 목표', identityStatement: '나는 해낸다', category: GoalCategory.growth);
      await appState.addGoal(title: '두번째 목표', identityStatement: '나는 계속한다', category: GoalCategory.career);

      expect(appState.goals, hasLength(2));
      expect(appState.goals.first.title, '두번째 목표'); // 최신 항목이 앞에 온다

      final reloaded = AppState();
      await reloaded.load();
      expect(reloaded.goals, hasLength(2));
    });

    test('updateGoalProgress는 0.0~1.0 범위로 clamp된다', () async {
      final goal = await appState.addGoal(title: '목표', identityStatement: '나는 성장한다', category: GoalCategory.growth);

      await appState.updateGoalProgress(goal.id, 1.5);
      expect(appState.goals.first.progress, 1.0);

      await appState.updateGoalProgress(goal.id, -0.5);
      expect(appState.goals.first.progress, 0.0);
    });

    test('마일스톤을 모두 완료하면 목표 완료 축하 이벤트가 발생한다', () async {
      final goal = await appState.addGoal(title: '목표', identityStatement: '나는 이룬다', category: GoalCategory.growth);
      await appState.addMilestone(goal.id, '1단계');
      await appState.addMilestone(goal.id, '2단계');

      final milestone1Id = appState.goals.first.milestones[0].id;
      final milestone2Id = appState.goals.first.milestones[1].id;

      // 첫 마일스톤만 완료 -> 아직 50%, 축하 없음
      final firstResult = await appState.toggleMilestone(goal.id, milestone1Id);
      expect(firstResult, isNull);
      expect(appState.goals.first.progress, closeTo(0.5, 0.0001));

      // 두번째 마일스톤까지 완료 -> 100%, 목표 완료 축하 발생
      final secondResult = await appState.toggleMilestone(goal.id, milestone2Id);
      expect(secondResult, CelebrationType.goalComplete);
      expect(appState.goals.first.progress, 1.0);
    });

    test('deleteGoal은 목록과 저장소 양쪽에서 제거된다', () async {
      final goal = await appState.addGoal(title: '삭제될 목표', identityStatement: '나는 정리한다', category: GoalCategory.growth);
      await appState.deleteGoal(goal.id);

      expect(appState.goals, isEmpty);
      final reloaded = AppState();
      await reloaded.load();
      expect(reloaded.goals, isEmpty);
    });

    test('무료 사용자는 FreeLimits.maxGoals(3)개까지만 추가 가능하다', () async {
      expect(appState.canAddGoal, true);
      for (var i = 0; i < 3; i++) {
        await appState.addGoal(title: '목표$i', identityStatement: '나는 $i번째', category: GoalCategory.growth);
      }
      expect(appState.goals, hasLength(3));
      expect(appState.canAddGoal, false); // 한도 도달
    });

    test('프리미엄 사용자는 목표 개수 한도가 없다', () async {
      await appState.setPremiumStatus(true);
      for (var i = 0; i < 5; i++) {
        await appState.addGoal(title: '목표$i', identityStatement: '나는 $i번째', category: GoalCategory.growth);
      }
      expect(appState.canAddGoal, true);
    });
  });

  group('습관(Habits) & 스트릭', () {
    test('addHabit으로 습관을 추가할 수 있다', () async {
      await appState.addHabit('아침 확언 읽기');
      expect(appState.habits, hasLength(1));
      expect(appState.habits.first.streak, 0);
    });

    test('오늘 처음 완료 체크 시 스트릭이 1 증가한다', () async {
      await appState.addHabit('습관');
      final result = await appState.toggleHabitToday(appState.habits.first.id);
      expect(appState.habits.first.streak, 1);
      expect(appState.habits.first.isDoneToday(), true);
      expect(result, isNull); // 7/30/100 이 아니므로 축하 없음
    });

    test('같은 날 다시 토글하면 완료가 취소되고 스트릭이 다시 감소한다', () async {
      await appState.addHabit('습관');
      final id = appState.habits.first.id;
      await appState.toggleHabitToday(id);
      expect(appState.habits.first.streak, 1);

      await appState.toggleHabitToday(id);
      expect(appState.habits.first.streak, 0);
      expect(appState.habits.first.isDoneToday(), false);
    });

    test('스트릭이 0 밑으로 내려가지 않는다(clamp 방어)', () async {
      await appState.addHabit('습관');
      final id = appState.habits.first.id;
      // 완료 상태가 아닌데 취소 로직이 실수로 타지 않는지 확인하는 방어 테스트
      await appState.toggleHabitToday(id); // streak 1, 완료
      await appState.toggleHabitToday(id); // streak 0, 취소
      expect(appState.habits.first.streak, greaterThanOrEqualTo(0));
    });

    test('스트릭이 정확히 7이 되면 streak7 축하 이벤트가 발생한다', () async {
      await appState.addHabit('습관');
      final habit = appState.habits.first;
      habit.streak = 6; // 이미 6일 연속 달성한 상태를 시뮬레이션
      final result = await appState.toggleHabitToday(habit.id);
      expect(habit.streak, 7);
      expect(result, CelebrationType.streak7);
    });

    test('스트릭이 정확히 30이 되면 streak30 축하 이벤트가 발생한다', () async {
      await appState.addHabit('습관');
      final habit = appState.habits.first;
      habit.streak = 29;
      final result = await appState.toggleHabitToday(habit.id);
      expect(result, CelebrationType.streak30);
    });

    test('deleteHabit으로 습관을 제거할 수 있다', () async {
      await appState.addHabit('삭제될 습관');
      final id = appState.habits.first.id;
      await appState.deleteHabit(id);
      expect(appState.habits, isEmpty);
    });

    test('무료 사용자는 습관을 3개까지만 추가할 수 있다', () async {
      for (var i = 0; i < 3; i++) {
        await appState.addHabit('습관$i');
      }
      expect(appState.canAddHabit, false);
    });
  });

  group('저널 & 369 스크립팅', () {
    test('addJournalEntry로 저널을 추가하면 최신 항목이 맨 앞에 온다', () async {
      await appState.addJournalEntry(type: JournalType.gratitude, content: '첫 감사');
      await appState.addJournalEntry(type: JournalType.gratitude, content: '두번째 감사');
      expect(appState.journalEntries.first.content, '두번째 감사');
    });

    test('scriptCountToday는 오늘 작성한 해당 시간대 스크립팅 개수만 센다', () async {
      await appState.addJournalEntry(type: JournalType.script, content: '아침1', period: ScriptPeriod.morning.name);
      await appState.addJournalEntry(type: JournalType.script, content: '아침2', period: ScriptPeriod.morning.name);
      await appState.addJournalEntry(type: JournalType.script, content: '저녁1', period: ScriptPeriod.evening.name);

      expect(appState.scriptCountToday(ScriptPeriod.morning), 2);
      expect(appState.scriptCountToday(ScriptPeriod.evening), 1);
      expect(appState.scriptCountToday(ScriptPeriod.afternoon), 0);
    });

    test('scriptingAllCompleteToday는 3/6/9 목표를 모두 채워야 true다', () async {
      expect(appState.scriptingAllCompleteToday, false);

      for (var i = 0; i < ScriptPeriod.morning.target; i++) {
        await appState.addJournalEntry(type: JournalType.script, content: '아침$i', period: ScriptPeriod.morning.name);
      }
      // 아침만 채웠으므로 아직 전체 완료는 아니다
      expect(appState.scriptingAllCompleteToday, false);

      for (var i = 0; i < ScriptPeriod.afternoon.target; i++) {
        await appState.addJournalEntry(type: JournalType.script, content: '오후$i', period: ScriptPeriod.afternoon.name);
      }
      for (var i = 0; i < ScriptPeriod.evening.target; i++) {
        await appState.addJournalEntry(type: JournalType.script, content: '저녁$i', period: ScriptPeriod.evening.name);
      }
      expect(appState.scriptingAllCompleteToday, true);
    });

    test('deleteJournalEntry로 항목을 제거할 수 있다', () async {
      await appState.addJournalEntry(type: JournalType.gratitude, content: '삭제될 항목');
      final id = appState.journalEntries.first.id;
      await appState.deleteJournalEntry(id);
      expect(appState.journalEntries, isEmpty);
    });
  });

  group('비전보드', () {
    test('addVisionItem / deleteVisionItem이 정상 동작한다', () async {
      await appState.addVisionItem(caption: '풍요로운 삶', isAssetImage: true, imagePath: 'assets/images/vision_examples/wealth.jpg');
      expect(appState.visionItems, hasLength(1));

      await appState.deleteVisionItem(appState.visionItems.first.id);
      expect(appState.visionItems, isEmpty);
    });

    test('무료 사용자는 비전보드 카드를 5개까지만 추가할 수 있다', () async {
      for (var i = 0; i < 5; i++) {
        await appState.addVisionItem(caption: '카드$i');
      }
      expect(appState.canAddVisionItem, false);
    });
  });

  group('우주편지', () {
    test('addLetter 후 markLetterRead로 읽음 처리할 수 있다', () async {
      await appState.addLetter(content: '미래의 나에게', openDate: DateTime.now().add(const Duration(days: 1)));
      final id = appState.letters.first.id;
      expect(appState.letters.first.isRead, false);

      await appState.markLetterRead(id);
      expect(appState.letters.first.isRead, true);
    });

    test('이번 달 편지 개수가 무료 한도(1개)를 넘으면 canWriteLetterThisMonth가 false다', () async {
      expect(appState.canWriteLetterThisMonth, true);
      await appState.addLetter(content: '편지1', openDate: DateTime.now().add(const Duration(days: 1)));
      expect(appState.lettersThisMonth, 1);
      expect(appState.canWriteLetterThisMonth, false);
    });

    test('deleteLetter로 편지를 제거할 수 있다', () async {
      await appState.addLetter(content: '삭제될 편지', openDate: DateTime.now());
      final id = appState.letters.first.id;
      await appState.deleteLetter(id);
      expect(appState.letters, isEmpty);
    });
  });

  group('정체성 포인트 & 레벨', () {
    test('아무 활동이 없으면 totalPoints는 0이다', () {
      expect(appState.totalPoints, 0);
    });

    test('저널/습관/목표 활동이 누적되면 포인트가 증가한다', () async {
      await appState.addJournalEntry(type: JournalType.gratitude, content: '감사'); // +5pt
      await appState.addHabit('습관');
      await appState.toggleHabitToday(appState.habits.first.id); // +3pt
      final goal = await appState.addGoal(title: '목표', identityStatement: '나는 이룬다', category: GoalCategory.growth);
      await appState.updateGoalProgress(goal.id, 0.5); // +50pt

      expect(appState.totalPoints, 5 + 3 + 50);
    });
  });

  group('프리미엄 엔타이틀먼트 연동', () {
    test('setPremiumStatus는 AppState.isPremium과 EntitlementService를 함께 갱신한다', () async {
      expect(appState.isPremium, false);
      await appState.setPremiumStatus(true);
      expect(appState.isPremium, true);
      expect(EntitlementService.isPremium, true);
    });
  });
}
