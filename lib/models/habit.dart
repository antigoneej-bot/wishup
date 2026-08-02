/// 정체성 기반 습관 (Identity-based Habit)
/// "나는 OO 사람이다"를 증명하는 작은 행동
class Habit {
  final String id;
  String title;
  String? linkedGoalId;
  int streak;
  DateTime? lastCompletedAt;
  List<String> completedDates; // yyyy-MM-dd 문자열 목록
  DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    this.linkedGoalId,
    this.streak = 0,
    this.lastCompletedAt,
    List<String>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool isDoneToday() {
    final today = _fmt(DateTime.now());
    return completedDates.contains(today);
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'linkedGoalId': linkedGoalId,
        'streak': streak,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'completedDates': completedDates,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromMap(Map map) => Habit(
        id: map['id'] as String,
        title: map['title'] as String,
        linkedGoalId: map['linkedGoalId'] as String?,
        streak: map['streak'] as int? ?? 0,
        lastCompletedAt:
            map['lastCompletedAt'] != null ? DateTime.tryParse(map['lastCompletedAt'] as String) : null,
        completedDates: (map['completedDates'] as List? ?? []).map((e) => e.toString()).toList(),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
