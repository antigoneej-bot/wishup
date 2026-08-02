/// 축하 모먼트 타입 (행동과학 - 도파민 루프 강화)
enum CelebrationType { streak7, streak30, streak100, goalComplete, scriptingComplete }

extension CelebrationTypeX on CelebrationType {
  String get emoji {
    switch (this) {
      case CelebrationType.streak7:
        return '🔥';
      case CelebrationType.streak30:
        return '⭐';
      case CelebrationType.streak100:
        return '👑';
      case CelebrationType.goalComplete:
        return '🎉';
      case CelebrationType.scriptingComplete:
        return '✨';
    }
  }

  String get title {
    switch (this) {
      case CelebrationType.streak7:
        return '7일 연속 달성!';
      case CelebrationType.streak30:
        return '30일 연속 달성!';
      case CelebrationType.streak100:
        return '100일 연속 달성!';
      case CelebrationType.goalComplete:
        return '목표를 이루었어요!';
      case CelebrationType.scriptingComplete:
        return '오늘의 369 스크립팅 완료!';
    }
  }

  String get message {
    switch (this) {
      case CelebrationType.streak7:
        return '일주일 동안 매일 정체성을 증명했어요. 이 흐름을 계속 이어가보세요.';
      case CelebrationType.streak30:
        return '30일이면 뇌가 새로운 습관을 진짜 정체성으로 받아들이기 시작해요. 놀라운 일관성이에요!';
      case CelebrationType.streak100:
        return '100일! 이건 이미 당신의 일부가 된 습관이에요. 진짜 정체성이 바뀌었어요.';
      case CelebrationType.goalComplete:
        return '생각이 현실이 되는 걸 직접 증명했어요. 이 성취를 충분히 느껴보세요.';
      case CelebrationType.scriptingComplete:
        return '369법을 완료하며 무의식에 소망을 새겼어요. 오늘도 한 걸음 더 가까워졌어요.';
    }
  }
}
