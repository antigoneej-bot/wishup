import 'package:hive_flutter/hive_flutter.dart';

/// Hive 기반 로컬 저장소 초기화 및 박스 접근 헬퍼
/// (build_runner 없이 Map 형태로 저장하여 단순화)
class StorageService {
  static const String goalsBox = 'goals_box';
  static const String habitsBox = 'habits_box';
  static const String journalBox = 'journal_box';
  static const String visionBox = 'vision_box';
  static const String settingsBox = 'settings_box';
  static const String letterBox = 'letter_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(goalsBox);
    await Hive.openBox(habitsBox);
    await Hive.openBox(journalBox);
    await Hive.openBox(visionBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(letterBox);
  }

  static Box get goals => Hive.box(goalsBox);
  static Box get habits => Hive.box(habitsBox);
  static Box get journal => Hive.box(journalBox);
  static Box get vision => Hive.box(visionBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get letters => Hive.box(letterBox);
}
