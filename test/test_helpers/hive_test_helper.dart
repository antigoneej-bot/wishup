import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:wishup/services/storage_service.dart';

/// 테스트 전용 Hive 초기화 헬퍼.
///
/// 실제 앱은 [StorageService.init]에서 `Hive.initFlutter()`를 호출해
/// path_provider 플러그인으로 기기의 문서 디렉터리를 가져오지만,
/// `flutter test`(VM) 환경에는 플랫폼 채널이 없어 그대로 사용하면
/// `MissingPluginException`이 발생합니다.
///
/// 대신 임시 디렉터리를 직접 만들어 `Hive.init()`으로 초기화하고,
/// [StorageService]가 사용하는 것과 동일한 이름으로 박스를 열어두면
/// 앱 코드의 `Hive.box(name)` 호출이 정상적으로 동작합니다.
Future<Directory> initHiveForTest() async {
  final dir = await Directory.systemTemp.createTemp('wishup_test_');
  Hive.init(dir.path);
  await Hive.openBox(StorageService.goalsBox);
  await Hive.openBox(StorageService.habitsBox);
  await Hive.openBox(StorageService.journalBox);
  await Hive.openBox(StorageService.visionBox);
  await Hive.openBox(StorageService.settingsBox);
  await Hive.openBox(StorageService.letterBox);
  return dir;
}

/// 각 테스트 사이에 상태가 새지 않도록 모든 박스를 비웁니다(닫지는 않음).
Future<void> clearHiveBoxesForTest() async {
  await StorageService.goals.clear();
  await StorageService.habits.clear();
  await StorageService.journal.clear();
  await StorageService.vision.clear();
  await StorageService.settings.clear();
  await StorageService.letters.clear();
}

/// 테스트 종료 후 Hive를 닫고 임시 디렉터리를 삭제합니다.
Future<void> closeHiveForTest(Directory dir) async {
  await Hive.close();
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
