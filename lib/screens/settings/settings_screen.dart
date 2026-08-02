import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          children: [
            const Text('알림', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('알림은 Android/iOS 앱에서 활성화됩니다.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 6),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('데일리 확언 알림', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('매일 오전 9시', style: TextStyle(fontSize: 12)),
                    activeThumbColor: AppColors.navy,
                    value: state.affirmationNotifEnabled,
                    onChanged: kIsWeb ? null : (v) => context.read<AppState>().setAffirmationNotif(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('습관 리마인더', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('매일 오후 8시', style: TextStyle(fontSize: 12)),
                    activeThumbColor: AppColors.navy,
                    value: state.habitNotifEnabled,
                    onChanged: kIsWeb ? null : (v) => context.read<AppState>().setHabitNotif(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('🌙 신월/보름 리츄얼 알림', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      '다음: ${state.moonPhaseInfo.nextNewMoon.isBefore(state.moonPhaseInfo.nextFullMoon) ? "신월 ${state.moonPhaseInfo.nextNewMoon.month}.${state.moonPhaseInfo.nextNewMoon.day}" : "보름 ${state.moonPhaseInfo.nextFullMoon.month}.${state.moonPhaseInfo.nextFullMoon.day}"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeThumbColor: AppColors.navy,
                    value: state.moonRitualNotifEnabled,
                    onChanged: kIsWeb ? null : (v) => context.read<AppState>().setMoonRitualNotif(v),
                  ),
                ],
              ),
            ),
            if (!kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () => NotificationService.showTestNotification(),
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
                  label: const Text('알림 테스트'),
                ),
              ),
            const SizedBox(height: 28),

            const Text('데이터', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.navy),
                title: const Text('앱 정보', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('WishUp v1.0.0 · 모든 데이터는 기기에 안전하게 저장됩니다', style: TextStyle(fontSize: 11.5)),
              ),
            ),
            const SizedBox(height: 28),

            const Text('WishUp 소개', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.beige.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: const Text(
                '위시업은 확언을 반복하는 앱이 아니라, 감정·행동·습관 데이터를 기반으로\n'
                'AI가 당신의 패턴을 분석하고 실제 현실의 변화를 돕는\n'
                '체계적인 목표 트래킹 플랫폼입니다.',
                style: TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
