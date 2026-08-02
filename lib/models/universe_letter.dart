/// 우주에 편지쓰기 (Letter to Universe) - 미래에 열어보는 매니페스테이션 타임캡슐
class UniverseLetter {
  final String id;
  String content;
  DateTime createdAt;
  DateTime openDate; // 이 날짜가 지나야 열람 가능
  bool isRead;

  UniverseLetter({
    required this.id,
    required this.content,
    required this.openDate,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isUnlocked => DateTime.now().isAfter(openDate);

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'openDate': openDate.toIso8601String(),
        'isRead': isRead,
      };

  factory UniverseLetter.fromMap(Map map) => UniverseLetter(
        id: map['id'] as String,
        content: map['content'] as String? ?? '',
        openDate: map['openDate'] != null
            ? DateTime.tryParse(map['openDate'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        isRead: map['isRead'] as bool? ?? false,
      );
}
