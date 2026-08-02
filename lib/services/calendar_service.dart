import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

/// Android Intent 시스템을 활용한 캘린더 연동 (직접 Calendar API 대신 Intent 사용 → 호환성 우수)
class CalendarService {
  static Future<bool> addEvent({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    if (kIsWeb) return false;
    try {
      final begin = DateTime(date.year, date.month, date.day, 9, 0);
      final end = begin.add(const Duration(hours: 1));
      final intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
        arguments: <String, dynamic>{
          'title': title,
          'description': description,
          'beginTime': begin.millisecondsSinceEpoch,
          'endTime': end.millisecondsSinceEpoch,
        },
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }
}
