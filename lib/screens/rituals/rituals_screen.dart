import 'package:flutter/material.dart';
import '../../models/ritual_audio.dart';
import '../../theme/app_theme.dart';
import 'ritual_player_screen.dart';

/// 리츄얼 오디오 목록 (시각화 / 명상 가이드)
class RitualsScreen extends StatelessWidget {
  const RitualsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('리츄얼 오디오')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            const Text('무의식에 새기는 시간', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('눈을 감고, 목소리를 따라가보세요', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ...RitualAudio.all.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ritualCard(context, r),
                )),
          ],
        ),
      ),
    );
  }

  Widget _ritualCard(BuildContext context, RitualAudio r) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RitualPlayerScreen(ritual: r))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(r.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 4),
                  Text(r.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(r.durationLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.navy, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.play_circle_fill, color: AppColors.navy, size: 32),
          ],
        ),
      ),
    );
  }
}
