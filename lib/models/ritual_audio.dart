/// 리츄얼 카테고리: 무료 베이직 vs 프리미엄 뇌파 유도 시리즈
enum RitualCategory { basic, frequency }

/// 리츄얼 오디오 (시각화 / 명상 가이드) 데이터 모델
class RitualAudio {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String assetPath;
  final String durationLabel;
  final RitualCategory category;

  /// true면 프리미엄 멤버십 전용 콘텐츠(무료 이용자는 잠금 화면 → 결제 유도)
  final bool isPremium;

  const RitualAudio({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.assetPath,
    required this.durationLabel,
    this.category = RitualCategory.basic,
    this.isPremium = false,
  });

  static const List<RitualAudio> all = [
    // ── 베이직 리추얼 (무료) ──
    RitualAudio(
      id: 'visualization',
      title: '정체성 시각화',
      subtitle: '이미 이루어진 미래의 나를 생생하게 그려보는 시각화 가이드',
      emoji: '🌅',
      assetPath: 'audio/visualization_guide.mp3',
      durationLabel: '2분 31초',
    ),
    RitualAudio(
      id: 'meditation',
      title: '호흡 명상',
      subtitle: '4-2-6 호흡으로 마음을 가라앉히는 짧은 명상 가이드',
      emoji: '🧘',
      assetPath: 'audio/meditation_guide.mp3',
      durationLabel: '2분 33초',
    ),

    // ── 🎧 프리퀀시 리추얼 (프리미엄, 뇌파 유도 시리즈) ──
    RitualAudio(
      id: 'sleep_visualization',
      title: '수면 시각화',
      subtitle: '알파 → 세타 → 델타파로 이어지는 뇌파 유도음과 속삭이는 시각화 내레이션으로 깊은 잠에 들어요',
      emoji: '🌙',
      assetPath: 'audio/sleep_visualization_brainwave.mp3',
      durationLabel: '11분 40초',
      category: RitualCategory.frequency,
      isPremium: true,
    ),
    RitualAudio(
      id: 'morning_awakening',
      title: '아침 각성 리추얼',
      subtitle: '세타 → 알파 → 베타파로 점진적으로 각성하며 오늘 하루의 의도를 설정해요',
      emoji: '☀️',
      assetPath: 'audio/morning_awakening_ritual.mp3',
      durationLabel: '6분 40초',
      category: RitualCategory.frequency,
      isPremium: true,
    ),
  ];
}
