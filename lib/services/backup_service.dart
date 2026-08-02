import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';

/// 백업 파일 요약 정보 (복원 전 사용자에게 미리 보여주는 용도)
class BackupSummary {
  final DateTime exportedAt;
  final int goalsCount;
  final int habitsCount;
  final int journalCount;
  final int visionCount;
  final int lettersCount;

  BackupSummary({
    required this.exportedAt,
    required this.goalsCount,
    required this.habitsCount,
    required this.journalCount,
    required this.visionCount,
    required this.lettersCount,
  });
}

/// 로컬(Hive) 전체 데이터를 하나의 JSON 파일로 내보내고, 다시 불러와 복원하는 서비스.
/// - 목적: 기기 변경/앱 재설치 시 데이터가 완전히 사라지는 것을 막는 "데이터 안전망"
/// - 클라우드 계정 없이도 즉시 사용 가능 (파일 공유/저장은 Android 자체 공유 시트를 이용)
/// - 추후 Firebase 등 실제 클라우드 자동 백업으로 고도화 가능한 전환용 임시 안전장치
class BackupService {
  static const String appId = 'com.wishup.goals';
  static const int exportVersion = 1;

  static Map<String, dynamic> _exportAll() {
    return {
      'appId': appId,
      'exportVersion': exportVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': Map<String, dynamic>.from(StorageService.settings.toMap().map(
        (k, v) => MapEntry(k.toString(), v),
      )),
      'goals': StorageService.goals.values.toList(),
      'habits': StorageService.habits.values.toList(),
      'journal': StorageService.journal.values.toList(),
      'vision': StorageService.vision.values.toList(),
      'letters': StorageService.letters.values.toList(),
    };
  }

  /// 백업 JSON 파일을 생성해 공유 시트(저장/전송)로 내보냄
  static Future<bool> exportAndShare() async {
    if (kIsWeb) return false; // 모바일(Android) 전용 기능
    try {
      final data = _exportAll();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fname =
          'WishUp_백업_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$fname');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'WishUp 데이터 백업 파일입니다. 클라우드 저장소나 이메일 등 안전한 곳에 보관해주세요.',
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('백업 내보내기 실패: $e');
      return false;
    }
  }

  /// 파일을 선택해 JSON으로 파싱 (아직 복원은 실행하지 않음 — 미리보기용)
  static Future<Map<String, dynamic>?> pickAndParse() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final bytes = result.files.first.bytes;
      if (bytes == null) return null;
      final content = utf8.decode(bytes);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (e) {
      if (kDebugMode) debugPrint('백업 파일 읽기 실패: $e');
      return null;
    }
  }

  /// 유효한 WishUp 백업 파일인지 확인하고 요약 정보 반환 (아니면 null)
  static BackupSummary? peekSummary(Map<String, dynamic> data) {
    if (data['appId'] != appId) return null;
    return BackupSummary(
      exportedAt: DateTime.tryParse(data['exportedAt'] as String? ?? '') ?? DateTime.now(),
      goalsCount: (data['goals'] as List?)?.length ?? 0,
      habitsCount: (data['habits'] as List?)?.length ?? 0,
      journalCount: (data['journal'] as List?)?.length ?? 0,
      visionCount: (data['vision'] as List?)?.length ?? 0,
      lettersCount: (data['letters'] as List?)?.length ?? 0,
    );
  }

  /// 실제 복원 실행 — 현재 기기의 데이터를 백업 파일 내용으로 전체 대체
  static Future<void> restore(Map<String, dynamic> data) async {
    await StorageService.goals.clear();
    await StorageService.habits.clear();
    await StorageService.journal.clear();
    await StorageService.vision.clear();
    await StorageService.letters.clear();

    Future<void> putAll(dynamic list, dynamic box) async {
      for (final item in (list as List? ?? [])) {
        final m = Map<String, dynamic>.from(item as Map);
        await box.put(m['id'], m);
      }
    }

    await putAll(data['goals'], StorageService.goals);
    await putAll(data['habits'], StorageService.habits);
    await putAll(data['journal'], StorageService.journal);
    await putAll(data['vision'], StorageService.vision);
    await putAll(data['letters'], StorageService.letters);

    final settings = Map<String, dynamic>.from(data['settings'] as Map? ?? {});
    for (final entry in settings.entries) {
      await StorageService.settings.put(entry.key, entry.value);
    }
  }
}
