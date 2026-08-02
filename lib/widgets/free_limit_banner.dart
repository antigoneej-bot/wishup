import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 무료 플랜 사용량(예: "목표 2/3개")을 보여주고, 탭하면 프리미엄 안내로 연결하는
/// 작은 배너. 목표/습관/비전보드 화면에서 공통으로 사용합니다.
class FreeLimitBanner extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const FreeLimitBanner({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, size: 16, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
