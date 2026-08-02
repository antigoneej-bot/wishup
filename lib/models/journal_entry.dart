enum JournalType { gratitude, evidence, script, moodOnly, release }

extension JournalTypeX on JournalType {
  String get label {
    switch (this) {
      case JournalType.gratitude:
        return '감사일기';
      case JournalType.evidence:
        return '증거 기록';
      case JournalType.script:
        return '369 스크립팅';
      case JournalType.moodOnly:
        return '감정 체크인';
      case JournalType.release:
        return '놓아주기';
    }
  }
}

/// 369 스크립팅용 시간대 구분
enum ScriptPeriod { morning, afternoon, evening }

extension ScriptPeriodX on ScriptPeriod {
  String get label {
    switch (this) {
      case ScriptPeriod.morning:
        return '아침';
      case ScriptPeriod.afternoon:
        return '오후';
      case ScriptPeriod.evening:
        return '저녁';
    }
  }

  String get emoji {
    switch (this) {
      case ScriptPeriod.morning:
        return '🌅';
      case ScriptPeriod.afternoon:
        return '🌇';
      case ScriptPeriod.evening:
        return '🌙';
    }
  }

  int get target {
    switch (this) {
      case ScriptPeriod.morning:
        return 3;
      case ScriptPeriod.afternoon:
        return 6;
      case ScriptPeriod.evening:
        return 9;
    }
  }
}

/// 저널(감사일기/증거기록/스크립팅/감정체크인) 통합 엔트리
class JournalEntry {
  final String id;
  JournalType type;
  String content;
  int moodScore; // 1(매우 안좋음) ~ 5(매우 좋음)
  String? linkedGoalId;
  String? period; // 369 스크립팅용 (morning/afternoon/evening), 그 외는 null
  DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.type,
    required this.content,
    this.moodScore = 3,
    this.linkedGoalId,
    this.period,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'content': content,
        'moodScore': moodScore,
        'linkedGoalId': linkedGoalId,
        'period': period,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map map) => JournalEntry(
        id: map['id'] as String,
        type: JournalType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => JournalType.gratitude,
        ),
        content: map['content'] as String? ?? '',
        moodScore: map['moodScore'] as int? ?? 3,
        linkedGoalId: map['linkedGoalId'] as String?,
        period: map['period'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
