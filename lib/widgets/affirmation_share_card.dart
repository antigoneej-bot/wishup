import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// SNS 공유용 확언 카드 (캡처되어 이미지로 공유됨)
class AffirmationShareCard extends StatelessWidget {
  final String text;

  const AffirmationShareCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✦', style: TextStyle(color: Colors.white, fontSize: 28)),
          const SizedBox(height: 18),
          Text(
            '"$text"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'WishUp · 위시업',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
