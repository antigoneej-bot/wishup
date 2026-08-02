/// 달의 위상(신월/보름) 계산 서비스
/// - 명상/끌어당김 리츄얼에서 신월(New Moon)은 "새 소망을 심는 때",
///   보름(Full Moon)은 "감사와 놓아주기의 때"로 널리 활용됨
class MoonPhaseInfo {
  final String phaseName;
  final String emoji;
  final bool isNewMoon;
  final bool isFullMoon;
  final DateTime nextNewMoon;
  final DateTime nextFullMoon;
  final String? ritualMessage;

  MoonPhaseInfo({
    required this.phaseName,
    required this.emoji,
    required this.isNewMoon,
    required this.isFullMoon,
    required this.nextNewMoon,
    required this.nextFullMoon,
    this.ritualMessage,
  });
}

class MoonPhaseService {
  static const double _synodicMonth = 29.530588853;
  static final DateTime _knownNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  static double _phaseFraction(DateTime date) {
    final days = date.toUtc().difference(_knownNewMoon).inMinutes / 1440.0;
    double frac = (days % _synodicMonth) / _synodicMonth;
    if (frac < 0) frac += 1;
    return frac;
  }

  static MoonPhaseInfo getInfo([DateTime? date]) {
    final d = date ?? DateTime.now();
    final frac = _phaseFraction(d);

    final isNew = frac < 0.035 || frac > 0.965;
    final isFull = (frac - 0.5).abs() < 0.035;

    String phaseName;
    String emoji;
    if (frac < 0.035 || frac > 0.965) {
      phaseName = '신월';
      emoji = '🌑';
    } else if (frac < 0.22) {
      phaseName = '초승달';
      emoji = '🌒';
    } else if (frac < 0.285) {
      phaseName = '상현달';
      emoji = '🌓';
    } else if (frac < 0.465) {
      phaseName = '보름을 향해 차오르는 달';
      emoji = '🌔';
    } else if (frac < 0.535) {
      phaseName = '보름달';
      emoji = '🌕';
    } else if (frac < 0.715) {
      phaseName = '기울어가는 달';
      emoji = '🌖';
    } else if (frac < 0.78) {
      phaseName = '하현달';
      emoji = '🌗';
    } else {
      phaseName = '그믐달';
      emoji = '🌘';
    }

    final nextNew = _findNext(d, target: 0.0);
    final nextFull = _findNext(d, target: 0.5);

    String? ritual;
    if (isNew) {
      ritual = '신월(New Moon)은 새로운 소망을 심는 가장 강력한 시간이에요. 오늘 새 목표를 세우거나 확언을 다시 적어보세요.';
    } else if (isFull) {
      ritual = '보름(Full Moon)은 감사하고 놓아줄 시간이에요. 이루어진 것에 감사하고, 더 이상 필요하지 않은 것을 흘려보내세요.';
    }

    return MoonPhaseInfo(
      phaseName: phaseName,
      emoji: emoji,
      isNewMoon: isNew,
      isFullMoon: isFull,
      nextNewMoon: nextNew,
      nextFullMoon: nextFull,
      ritualMessage: ritual,
    );
  }

  static DateTime _findNext(DateTime from, {required double target}) {
    DateTime cursor = from;
    for (int i = 0; i < 160; i++) {
      final f = _phaseFraction(cursor);
      final diff = (f - target).abs();
      if (diff < 0.018 || (target == 0.0 && f > 0.982)) {
        return DateTime(cursor.year, cursor.month, cursor.day, 9, 0);
      }
      cursor = cursor.add(const Duration(hours: 4));
    }
    return from.add(const Duration(days: 15));
  }
}
