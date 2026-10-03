import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wishup/models/goal.dart';
import 'package:wishup/models/journal_entry.dart';
import 'package:wishup/providers/app_state.dart';
import 'package:wishup/services/backup_service.dart';
import 'package:wishup/services/storage_service.dart';
import 'package:wishup/widgets/daily_ritual_card.dart';
import 'test_helpers/hive_test_helper.dart';

void main() {
  late Directory dir;
  late AppState state;
  late DateTime now;
  setUp(() async {
    dir = await initHiveForTest();
    now = DateTime(2026, 10, 4, 10);
    state = AppState(clock: () => now);
    await state.load();
  });
  tearDown(() async {
    state.dispose();
    await closeHiveForTest(dir);
  });
  test(
    'daily progress survives reload and resets on the next calendar date',
    () async {
      await state.readRitualAffirmation(state.ritualDate);
      await state.planRitualAction(state.ritualDate, '  Read one page  ');
      await state.completeRitualAction(state.ritualDate);
      final reloaded = AppState(clock: () => now);
      await reloaded.load();
      expect(reloaded.ritualActionTitle, 'Read one page');
      expect(reloaded.ritualCompletedSteps, 2);
      now = DateTime(2026, 10, 5);
      expect(reloaded.ritualCompletedSteps, 0);
      expect(reloaded.ritualActionTitle, isEmpty);
      await expectLater(
        reloaded.planRitualAction('2026-10-04', 'Yesterday'),
        throwsStateError,
      );
      reloaded.dispose();
    },
  );
  test(
    'linked habit completion is idempotent and respects manual undo',
    () async {
      final g = await state.addGoal(
        title: 'Read',
        identityStatement: '',
        category: GoalCategory.growth,
      );
      await state.addHabit('One page', linkedGoalId: g.id);
      final h = state.habits.first;
      await state.planRitualAction(
        state.ritualDate,
        h.title,
        goalId: g.id,
        habitId: h.id,
      );
      await state.completeRitualAction(state.ritualDate);
      await state.completeRitualAction(state.ritualDate);
      expect(h.completedDates, ['2026-10-04']);
      expect(h.streak, 1);
      expect(state.ritualActionDone, true);
      expect(g.progress, 0);
      await state.toggleHabitToday(h.id);
      expect(state.ritualActionDone, false);
    },
  );
  test('blank action and removed goal leave prior action intact', () async {
    await state.planRitualAction(state.ritualDate, 'Walk');
    await expectLater(
      state.planRitualAction(state.ritualDate, ' '),
      throwsArgumentError,
    );
    await expectLater(
      state.planRitualAction(state.ritualDate, 'Read', goalId: 'missing'),
      throwsStateError,
    );
    expect(state.ritualActionTitle, 'Walk');
  });
  test('same-day journal counts but scripting and other dates do not', () {
    state.journalEntries.add(
      JournalEntry(
        id: '1',
        type: JournalType.script,
        content: 'Wish',
        createdAt: now,
      ),
    );
    expect(state.ritualJournalDone, false);
    state.journalEntries.add(
      JournalEntry(
        id: '2',
        type: JournalType.gratitude,
        content: 'Thanks',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    );
    expect(state.ritualJournalDone, false);
    state.journalEntries.add(
      JournalEntry(
        id: '3',
        type: JournalType.gratitude,
        content: 'Thanks',
        createdAt: now,
      ),
    );
    expect(state.ritualJournalDone, true);
  });
  test('backup preserves rituals and rejects invalid ritual status', () async {
    await state.readRitualAffirmation(state.ritualDate);
    final data = <String, dynamic>{
      'appId': BackupService.appId,
      'exportVersion': BackupService.exportVersion,
      'exportedAt': now.toIso8601String(),
      'settings': {'dailyRituals': StorageService.settings.get('dailyRituals')},
      'goals': [],
      'habits': [],
      'journal': [],
      'vision': [],
      'letters': [],
    };
    await StorageService.settings.clear();
    await BackupService.restore(data);
    expect(state.ritualAffirmationRead, true);
    data['settings'] = {
      'dailyRituals': {
        '2026-10-04': {'actionDone': 'yes'},
      },
    };
    expect(BackupService.peekSummary(data), isNull);
  });
  testWidgets(
    'small screen guides through affirmation, planning and completion',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: DailyRitualCard()),
            ),
          ),
        ),
      );
      expect(find.text('확언을 읽었어요'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('확언을 읽었어요'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('오늘의 행동 정하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '책 한 쪽 읽기');
      await tester.runAsync(() async {
        await tester.tap(find.text('행동 저장'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(find.text('책 한 쪽 읽기'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('이 행동을 했어요'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(find.text('한 줄 기록하기'), findsOneWidget);
      await tester.tap(find.text('한 줄 기록하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '오늘 책을 읽어서 기뻤어요');
      await tester.ensureVisible(find.text('저장하기'));
      await tester.runAsync(() async {
        await tester.tap(find.text('저장하기'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(find.text('오늘의 리추얼을 마쳤어요'), findsOneWidget);
      expect(state.ritualCompletedSteps, 3);
      expect(state.journalEntries.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
