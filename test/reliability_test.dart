import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wishup/models/habit.dart';
import 'package:wishup/models/goal.dart';
import 'package:wishup/providers/app_state.dart';
import 'package:wishup/services/backup_service.dart';
import 'package:wishup/services/storage_service.dart';
import 'test_helpers/hive_test_helper.dart';

Map<String, dynamic> backup() => {
  'appId': BackupService.appId,
  'exportVersion': BackupService.exportVersion,
  'exportedAt': '2026-10-04T00:00:00',
  'settings': <String, dynamic>{},
  'goals': <dynamic>[],
  'habits': <dynamic>[],
  'journal': <dynamic>[],
  'vision': <dynamic>[],
  'letters': <dynamic>[],
};

void main() {
  test('streak resets across gaps and ignores duplicate dates', () {
    final h = Habit(
      id: 'h',
      title: 'Walk',
      completedDates: ['2026-10-01', '2026-10-03', '2026-10-03', '2026-10-04'],
    );
    expect(h.currentStreak(now: DateTime(2026, 10, 4)), 2);
    expect(h.currentStreak(now: DateTime(2026, 10, 5)), 2);
    expect(h.currentStreak(now: DateTime(2026, 10, 6)), 0);
  });

  group('data safety', () {
    late Directory directory;
    setUp(() async {
      directory = await initHiveForTest();
    });
    tearDown(() async {
      await closeHiveForTest(directory);
    });

    test('malformed late section leaves existing data untouched', () async {
      await StorageService.goals.put('keep', {'id': 'keep', 'title': 'Keep'});
      final data = backup()
        ..['letters'] = [
          {'id': 'bad', 'isRead': 'wrong'},
        ];
      expect(BackupService.peekSummary(data), isNull);
      await expectLater(BackupService.restore(data), throwsA(anything));
      expect(StorageService.goals.get('keep')['title'], 'Keep');
    });
    test('duplicate ids and invalid settings are rejected', () {
      final g = Goal(
        id: 'g',
        title: 'Goal',
        identityStatement: '',
        category: GoalCategory.growth,
      ).toMap();
      expect(BackupService.peekSummary(backup()..['goals'] = [g, g]), isNull);
      expect(
        BackupService.peekSummary(backup()..['settings'] = {'userName': 5}),
        isNull,
      );
      expect(
        BackupService.peekSummary(backup()..['exportVersion'] = 999),
        isNull,
      );
    });
    test(
      'backup cannot grant paid access, omitted old settings are cleared',
      () async {
        await StorageService.settings.put('scriptingWish', 'old');
        final data = backup()
          ..['settings'] = {'isPremium': true, 'userName': 'Restored'};
        await BackupService.restore(data);
        expect(StorageService.settings.get('isPremium'), false);
        expect(StorageService.settings.get('scriptingWish'), isNull);
        final state = AppState();
        await state.load();
        expect(state.userName, 'Restored');
        state.dispose();
      },
    );
    test('backup cannot revoke this device paid access', () async {
      await StorageService.settings.put('isPremium', true);
      await BackupService.restore(backup());
      expect(StorageService.settings.get('isPremium'), true);
    });
    test('legacy v1 backups are accepted', () async {
      final data = backup()..['exportVersion'] = 1;
      expect(BackupService.peekSummary(data), isNotNull);
      await BackupService.restore(data);
    });
    test('invalid image payload cannot erase records', () async {
      await StorageService.settings.put('userName', 'Keep');
      final data = backup()
        ..['vision'] = [
          {'id': 'v', 'imageBase64': '%%%'},
        ];
      await expectLater(BackupService.restore(data), throwsA(anything));
      expect(StorageService.settings.get('userName'), 'Keep');
    });
    test('adding a milestone updates completed goal progress', () async {
      final state = AppState();
      await state.load();
      final g = await state.addGoal(
        title: 'Goal',
        identityStatement: '',
        category: GoalCategory.growth,
      );
      await state.addMilestone(g.id, 'one');
      await state.toggleMilestone(g.id, g.milestones.first.id);
      await state.addMilestone(g.id, 'two');
      expect(g.progress, 0.5);
      state.dispose();
    });
  });
}
