import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 정체성 성장 레벨 (누적 포인트 기반, 절대 감소하지 않음 - 장기 동기부여)
enum IdentityLevel { seed, sprout, bud, bloom, tree }

extension IdentityLevelX on IdentityLevel {
  String get emoji {
    switch (this) {
      case IdentityLevel.seed:
        return '🌱';
      case IdentityLevel.sprout:
        return '🌿';
      case IdentityLevel.bud:
        return '🌼';
      case IdentityLevel.bloom:
        return '🌸';
      case IdentityLevel.tree:
        return '🌳';
    }
  }

  String get label {
    switch (this) {
      case IdentityLevel.seed:
        return '씨앗';
      case IdentityLevel.sprout:
        return '새싹';
      case IdentityLevel.bud:
        return '꽃봉오리';
      case IdentityLevel.bloom:
        return '만개';
      case IdentityLevel.tree:
        return '나무';
    }
  }

  int get minPoints {
    switch (this) {
      case IdentityLevel.seed:
        return 0;
      case IdentityLevel.sprout:
        return 100;
      case IdentityLevel.bud:
        return 300;
      case IdentityLevel.bloom:
        return 600;
      case IdentityLevel.tree:
        return 1000;
    }
  }

  static IdentityLevel fromPoints(int points) {
    if (points >= IdentityLevel.tree.minPoints) return IdentityLevel.tree;
    if (points >= IdentityLevel.bloom.minPoints) return IdentityLevel.bloom;
    if (points >= IdentityLevel.bud.minPoints) return IdentityLevel.bud;
    if (points >= IdentityLevel.sprout.minPoints) return IdentityLevel.sprout;
    return IdentityLevel.seed;
  }

  IdentityLevel? get next {
    const order = IdentityLevel.values;
    final i = order.indexOf(this);
    return i < order.length - 1 ? order[i + 1] : null;
  }
}

class LevelBadge extends StatelessWidget {
  final int points;

  const LevelBadge({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final level = IdentityLevelX.fromPoints(points);
    final next = level.next;
    final progress = next == null
        ? 1.0
        : (points - level.minPoints) / (next.minPoints - level.minPoints);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beige.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${level.label} 단계', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    const SizedBox(width: 6),
                    Text('· $points pt', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation(AppColors.navy),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next == null ? '최고 단계에 도달했어요!' : '다음 단계(${next.label})까지 ${next.minPoints - points}pt',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
