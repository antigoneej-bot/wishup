/// 비전보드 아이템 (이미지 or 텍스트 카드)
class VisionItem {
  final String id;
  String? imagePath; // 로컬 경로 (image_picker)
  String caption;
  DateTime createdAt;

  VisionItem({
    required this.id,
    this.imagePath,
    this.caption = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'caption': caption,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VisionItem.fromMap(Map map) => VisionItem(
        id: map['id'] as String,
        imagePath: map['imagePath'] as String?,
        caption: map['caption'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
