class Milestone {
  final String id;
  final String title;
  bool isDone;

  Milestone({required this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory Milestone.fromMap(Map map) => Milestone(
        id: map['id'] as String,
        title: map['title'] as String,
        isDone: map['isDone'] as bool? ?? false,
      );
}

/// 목표(소망) 카테고리
enum GoalCategory { career, wealth, love, health, growth, family }

extension GoalCategoryX on GoalCategory {
  String get label {
    switch (this) {
      case GoalCategory.career:
        return '커리어';
      case GoalCategory.wealth:
        return '풍요/재정';
      case GoalCategory.love:
        return '사랑/관계';
      case GoalCategory.health:
        return '건강/몸';
      case GoalCategory.growth:
        return '자기성장';
      case GoalCategory.family:
        return '가족/집';
    }
  }

  String get emoji {
    switch (this) {
      case GoalCategory.career:
        return '💼';
      case GoalCategory.wealth:
        return '💰';
      case GoalCategory.love:
        return '💗';
      case GoalCategory.health:
        return '🌿';
      case GoalCategory.growth:
        return '🌱';
      case GoalCategory.family:
        return '🏡';
    }
  }
}

class Goal {
  final String id;
  String title;
  String identityStatement; // "나는 ~한 사람이다" 정체성 선언문
  GoalCategory category;
  double progress; // 0.0 ~ 1.0
  DateTime? targetDate;
  DateTime createdAt;
  List<Milestone> milestones;
  bool isArchived;

  Goal({
    required this.id,
    required this.title,
    required this.identityStatement,
    required this.category,
    this.progress = 0.0,
    this.targetDate,
    DateTime? createdAt,
    List<Milestone>? milestones,
    this.isArchived = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        milestones = milestones ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'identityStatement': identityStatement,
        'category': category.name,
        'progress': progress,
        'targetDate': targetDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'milestones': milestones.map((m) => m.toMap()).toList(),
        'isArchived': isArchived,
      };

  factory Goal.fromMap(Map map) => Goal(
        id: map['id'] as String,
        title: map['title'] as String,
        identityStatement: map['identityStatement'] as String? ?? '',
        category: GoalCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => GoalCategory.growth,
        ),
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        targetDate: map['targetDate'] != null ? DateTime.tryParse(map['targetDate'] as String) : null,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        milestones: (map['milestones'] as List? ?? [])
            .map((m) => Milestone.fromMap(m as Map))
            .toList(),
        isArchived: map['isArchived'] as bool? ?? false,
      );
}
