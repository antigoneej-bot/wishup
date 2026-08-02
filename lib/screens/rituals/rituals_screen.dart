import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ritual_audio.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../premium/paywall_screen.dart';
import 'ritual_player_screen.dart';

/// 리츄얼 오디오 목록 (시각화 / 명상 가이드 / 프리퀀시 시리즈)
class RitualsScreen extends StatelessWidget {
  const RitualsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremium;
    final basics = RitualAudio.all.where((r) => r.category == RitualCategory.basic).toList();
    final frequency = RitualAudio.all.where((r) => r.category == RitualCategory.frequency).toList();

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
            const SizedBox(height: 24),

            _sectionHeader('베이직 리추얼', '언제든 무료로 이용할 수 있는 짧은 데일리 가이드'),
            const SizedBox(height: 12),
            ...basics.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ritualCard(context, r, isPremium),
                )),

            const SizedBox(height: 20),
            _frequencyHeader(),
            const SizedBox(height: 12),
            ...frequency.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ritualCard(context, r, isPremium),
                )),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _frequencyHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎧 프리퀀시 리추얼',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.navy)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: const Text('PREMIUM',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: 0.3)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text('뇌파 유도음이 함께하는 목적별 시리즈 · 매달 새로운 트랙이 추가돼요',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, RitualAudio r, bool isPremium) {
    if (r.isPremium && !isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaywallScreen(triggerReason: '${r.title}은 프리퀀시 리추얼 — 프리미엄 멤버십 전용 콘텐츠예요.'),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => RitualPlayerScreen(ritual: r)));
  }

  Widget _ritualCard(BuildContext context, RitualAudio r, bool isPremium) {
    final locked = r.isPremium && !isPremium;
    return GestureDetector(
      onTap: () => _handleTap(context, r, isPremium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: locked ? AppColors.gold.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06),
            width: locked ? 1.2 : 1,
          ),
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
                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(r.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(r.durationLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.navy, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              locked ? Icons.lock_rounded : Icons.play_circle_fill,
              color: locked ? AppColors.gold : AppColors.navy,
              size: locked ? 26 : 32,
            ),
          ],
        ),
      ),
    );
  }
}
