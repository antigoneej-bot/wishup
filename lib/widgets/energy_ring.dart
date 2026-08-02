import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_theme.dart';

/// 홈 대시보드 상단의 "에너지/바이브레이션 스코어" 원형 게이지
class EnergyRing extends StatelessWidget {
  final int score; // 0~100
  final double radius;

  const EnergyRing({super.key, required this.score, this.radius = 70});

  Color get _color {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.gold;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: 10,
      percent: score / 100,
      animation: true,
      animationDuration: 800,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: AppColors.beige,
      progressColor: _color,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Text(
            '에너지 스코어',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
