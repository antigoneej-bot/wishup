import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/vision_item.dart';
import '../models/universe_letter.dart';

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
  static const int exportVersion = 2;

  static Map<String, dynamic> _exportAll() {
    return {
      'appId': appId,
      'exportVersion': exportVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': Map<String, dynamic>.from(
        StorageService.settings.toMap().map(
          (k, v) => MapEntry(k.toString(), v),
        ),
      )..remove('isPremium'),
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
      final vision = <Map<String, dynamic>>[];
      for (final raw in data['vision'] as List) {
        final item = Map<String, dynamic>.from(raw as Map);
        final path = item['imagePath'];
        if (item['isAssetImage'] != true && path is String) {
          final file = File(path);
          if (await file.exists()) {
            item['imageBase64'] = base64Encode(await file.readAsBytes());
          }
          item['imagePath'] = null;
        }
        vision.add(item);
      }
      data['vision'] = vision;
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fname =
          'WishUp_백업_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$fname');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'WishUp 데이터 백업 파일입니다. 클라우드 저장소나 이메일 등 안전한 곳에 보관해주세요.');
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
    try {
      _validate(data);
      return BackupSummary(
        exportedAt: DateTime.parse(data['exportedAt'] as String),
        goalsCount: (data['goals'] as List).length,
        habitsCount: (data['habits'] as List).length,
        journalCount: (data['journal'] as List).length,
        visionCount: (data['vision'] as List).length,
        lettersCount: (data['letters'] as List).length,
      );
    } catch (_) {
      return null;
    }
  }

  static const _boolSettings = [
    'onboardingCompleted',
    'affirmationNotifEnabled',
    'habitNotifEnabled',
    'moonRitualNotifEnabled',
  ];
  static const _stringSettings = ['userName', 'scriptingWish'];

  /// Validate every section before touching existing records.
  static void _validate(Map<String, dynamic> data) {
    if (data['appId'] != appId ||
        ![1, exportVersion].contains(data['exportVersion'])) {
      throw const FormatException('Unsupported WishUp backup');
    }
    DateTime.parse(data['exportedAt'] as String);
    final parsers = <String, void Function(Map)>{
      'goals': (m) {
        final goal = Goal.fromMap(m);
        if (!goal.progress.isFinite || goal.progress < 0 || goal.progress > 1) {
          throw const FormatException('Invalid progress');
        }
      },
      'habits': (m) {
        Habit.fromMap(m);
      },
      'journal': (m) {
        final entry = JournalEntry.fromMap(m);
        if (entry.moodScore < 1 || entry.moodScore > 5) {
          throw const FormatException('Invalid mood');
        }
      },
      'vision': (m) {
        VisionItem.fromMap(m);
        if (m['imageBase64'] != null) base64Decode(m['imageBase64'] as String);
      },
      'letters': (m) {
        UniverseLetter.fromMap(m);
      },
    };
    for (final entry in parsers.entries) {
      final ids = <String>{};
      for (final raw in data[entry.key] as List) {
        final item = Map<String, dynamic>.from(raw as Map);
        final id = item['id'];
        if (id is! String || id.isEmpty || !ids.add(id)) {
          throw const FormatException('Missing or duplicate ID');
        }
        entry.value(item);
      }
    }
    final settings = Map<String, dynamic>.from(data['settings'] as Map);
    if (settings.containsKey('dailyRituals')) {
      final rituals = Map<String, dynamic>.from(
        settings['dailyRituals'] as Map,
      );
      for (final entry in rituals.entries) {
        final date = DateTime.parse(entry.key);
        final normalized =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        if (entry.key != normalized) {
          throw const FormatException('Invalid ritual date');
        }
        final value = Map<String, dynamic>.from(entry.value as Map);
        for (final key in ['affirmationRead', 'actionDone']) {
          if (value.containsKey(key) && value[key] is! bool) {
            throw const FormatException('Invalid ritual status');
          }
        }
        for (final key in ['actionTitle', 'goalId', 'habitId']) {
          if (value[key] != null && value[key] is! String) {
            throw const FormatException('Invalid ritual field');
          }
        }
      }
    }

    for (final key in _boolSettings) {
      if (settings.containsKey(key) && settings[key] is! bool) {
        throw const FormatException('Invalid setting');
      }
    }
    for (final key in _stringSettings) {
      if (settings.containsKey(key) && settings[key] is! String) {
        throw const FormatException('Invalid setting');
      }
    }
    if (settings.containsKey('focusAreas') &&
        (settings['focusAreas'] is! List ||
            (settings['focusAreas'] as List).any(
              (value) => value is! String,
            ))) {
      throw const FormatException('Invalid focus areas');
    }
  }

  /// 실제 복원 실행 — 현재 기기의 데이터를 백업 파일 내용으로 전체 대체
  static Future<void> restore(Map<String, dynamic> data) async {
    _validate(data);
    final boxes = <String, Box>{
      'goals': StorageService.goals,
      'habits': StorageService.habits,
      'journal': StorageService.journal,
      'vision': StorageService.vision,
      'letters': StorageService.letters,
      'settings': StorageService.settings,
    };
    final before = {for (final e in boxes.entries) e.key: e.value.toMap()};
    final incoming = <String, Map<dynamic, dynamic>>{};
    for (final key in boxes.keys.where((key) => key != 'settings')) {
      incoming[key] = {
        for (final item in data[key] as List)
          (item as Map)['id']: Map<String, dynamic>.from(item),
      };
    }
    final createdImages = <File>[];
    try {
      for (final item in incoming['vision']!.values) {
        final encoded = item.remove('imageBase64');
        if (encoded != null) {
          final dir = await getApplicationSupportDirectory();
          final images = await Directory(
            '${dir.path}/vision_images',
          ).create(recursive: true);
          final file = File('${images.path}/${const Uuid().v4()}.jpg');
          createdImages.add(file);
          await file.writeAsBytes(base64Decode(encoded as String), flush: true);
          item['imagePath'] = file.path;
          item['isAssetImage'] = false;
        }
      }
    } catch (_) {
      for (final file in createdImages) {
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
    final settings = data['settings'] as Map;
    incoming['settings'] = {
      // A backup must never grant or revoke paid access.
      'isPremium': StorageService.settings.get(
        'isPremium',
        defaultValue: false,
      ),
      for (final key in [
        ..._boolSettings,
        ..._stringSettings,
        'focusAreas',
        'dailyRituals',
      ])
        if (settings.containsKey(key)) key: settings[key],
    };
    try {
      for (final entry in boxes.entries) {
        await entry.value.clear();
        await entry.value.putAll(incoming[entry.key]!);
      }
    } catch (_) {
      // Best-effort rollback for write failures; not a crash-safe transaction.
      for (final entry in boxes.entries) {
        await entry.value.clear();
        await entry.value.putAll(before[entry.key]!);
      }
      rethrow;
    }
    await NotificationService.cancelAll();
  }
}
