import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// 로컬 알림 서비스 (Android/iOS 전용, Web에서는 kIsWeb 체크로 자동 스킵)
/// - 데일리 확언 리마인더
/// - 습관 실천 리마인더
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int affirmationNotifId = 1001;
  static const int habitNotifId = 1002;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // 타임존 초기화 실패 시 UTC로 폴백
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    try {
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // 플러그인 초기화 실패해도 앱 전체가 멈추지 않도록 방어
    }
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> scheduleDailyAffirmation({int hour = 9, int minute = 0}) async {
    if (kIsWeb) return;
    try {
      await _plugin.zonedSchedule(
        affirmationNotifId,
        '✦ 오늘의 확언이 도착했어요',
        '원하는 현실에 한 걸음 더 가까워지고 있어요. 지금 확인해보세요.',
        _nextInstance(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_affirmation',
            '데일리 확언 알림',
            channelDescription: '매일 정해진 시간에 확언을 알려드려요',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> scheduleHabitReminder({int hour = 20, int minute = 0}) async {
    if (kIsWeb) return;
    try {
      await _plugin.zonedSchedule(
        habitNotifId,
        '🔁 오늘의 습관, 완료하셨나요?',
        '작은 행동이 당신이 원하는 정체성을 매일 증명합니다.',
        _nextInstance(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminder',
            '습관 리마인더',
            channelDescription: '매일 정해진 시간에 습관 실천을 알려드려요',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> cancelAffirmation() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(affirmationNotifId);
    } catch (_) {}
  }

  static Future<void> cancelHabitReminder() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(habitNotifId);
    } catch (_) {}
  }

  /// 특정 미래 날짜에 1회 알림 (신월/보름 리츄얼, 우주에 편지 열람일 등에 사용)
  static Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (kIsWeb) return;
    if (dateTime.isBefore(DateTime.now())) return;
    try {
      final tzTime = tz.TZDateTime.from(dateTime, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'one_off_ritual',
            '리츄얼 알림',
            channelDescription: '신월/보름 등 특별한 날의 알림',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> cancelOneOff(int id) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb) return;
    try {
      await _plugin.show(
        9999,
        '✦ WishUp 알림 테스트',
        '알림이 정상적으로 도착했어요!',
        const NotificationDetails(
          android: AndroidNotificationDetails('test_channel', '테스트 알림', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
