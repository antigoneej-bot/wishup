/// 비전보드 아이템 (이미지 or 텍스트 카드)
class VisionItem {
  final String id;
  String? imagePath; // 로컬 파일 경로(image_picker) 또는 앱 내 asset 경로
  String caption;
  DateTime createdAt;

  /// true면 imagePath가 앱에 내장된 asset 경로(예: 예시 이미지),
  /// false면 사용자가 갤러리에서 고른 실제 파일 경로.
  bool isAssetImage;

  VisionItem({
    required this.id,
    this.imagePath,
    this.caption = '',
    DateTime? createdAt,
    this.isAssetImage = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'caption': caption,
        'createdAt': createdAt.toIso8601String(),
        'isAssetImage': isAssetImage,
      };

  factory VisionItem.fromMap(Map map) => VisionItem(
        id: map['id'] as String,
        imagePath: map['imagePath'] as String?,
        caption: map['caption'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        isAssetImage: map['isAssetImage'] as bool? ?? false,
      );
}

/// 비전보드 예시 이미지 카테고리
class VisionExample {
  final String id;
  final String assetPath;
  final String caption;
  final String category;
  final String emoji;

  const VisionExample({
    required this.id,
    required this.assetPath,
    required this.caption,
    required this.category,
    required this.emoji,
  });

  static const List<VisionExample> all = [
    VisionExample(
      id: 'ex_wealth',
      assetPath: 'assets/images/vision_examples/wealth.jpg',
      caption: '풍요로운 나의 삶',
      category: '풍요/재정',
      emoji: '💰',
    ),
    VisionExample(
      id: 'ex_health',
      assetPath: 'assets/images/vision_examples/health.jpg',
      caption: '건강하고 활력 넘치는 나',
      category: '건강/몸',
      emoji: '🌿',
    ),
    VisionExample(
      id: 'ex_career',
      assetPath: 'assets/images/vision_examples/career.jpg',
      caption: '성취를 이룬 나의 커리어',
      category: '커리어/사업성취',
      emoji: '💼',
    ),
    VisionExample(
      id: 'ex_love',
      assetPath: 'assets/images/vision_examples/love.jpg',
      caption: '사랑으로 충만한 관계',
      category: '사랑/관계',
      emoji: '💗',
    ),
  ];
}
