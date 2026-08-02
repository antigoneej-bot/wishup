/// 리츄얼 오디오 (시각화 / 명상 가이드) 데이터 모델
class RitualAudio {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String assetPath;
  final String durationLabel;

  const RitualAudio({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.assetPath,
    required this.durationLabel,
  });

  static const List<RitualAudio> all = [
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
  ];
}
