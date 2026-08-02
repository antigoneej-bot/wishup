import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/notification_service.dart';
import '../../services/backup_service.dart';
import '../../theme/app_theme.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_screen.dart';
import '../premium/paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _handleExport() async {
    setState(() => _busy = true);
    final ok = await BackupService.exportAndShare();
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '백업 파일을 내보냈어요. 안전한 곳에 저장해주세요.' : '백업 내보내기에 실패했어요. 다시 시도해주세요.')),
    );
  }

  Future<void> _handleImport() async {
    setState(() => _busy = true);
    final data = await BackupService.pickAndParse();
    setState(() => _busy = false);
    if (!mounted) return;
    if (data == null) return; // 사용자가 선택을 취소한 경우 조용히 종료
    final summary = BackupService.peekSummary(data);
    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WishUp 백업 파일이 아니에요. 올바른 파일을 선택해주세요.')),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('백업 복원'),
        content: Text(
          '${summary.exportedAt.year}.${summary.exportedAt.month}.${summary.exportedAt.day} 백업 파일이에요.\n\n'
          '목표 ${summary.goalsCount}개 · 습관 ${summary.habitsCount}개 · 저널 ${summary.journalCount}개\n'
          '비전보드 ${summary.visionCount}개 · 우주편지 ${summary.lettersCount}개\n\n'
          '⚠️ 지금 기기의 모든 데이터는 이 백업 내용으로 대체됩니다. 계속할까요?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('복원하기')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    await BackupService.restore(data);
    if (!mounted) return;
    await context.read<AppState>().load();
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 백업이 복원되었어요!')));
  }

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
            const Text('멤버십', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: state.isPremium ? AppColors.navy : AppColors.navyDark,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(state.isPremium ? Icons.verified : Icons.workspace_premium_outlined, color: AppColors.gold, size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isPremium ? 'WishUp 프리미엄 이용 중' : '무료 플랜 이용 중',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.isPremium ? '모든 기능을 제한 없이 이용하고 있어요' : '목표·습관·비전보드 개수 제한을 없애보세요',
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

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

            const Text('데이터 백업', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                '모든 데이터는 이 기기에만 저장돼요. 기기를 바꾸거나 앱을 재설치하기 전에\n반드시 백업 파일을 내보내 안전한 곳(이메일, 클라우드 등)에 보관해주세요.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('백업/복원은 Android 앱에서 이용할 수 있어요.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    enabled: !kIsWeb && !_busy,
                    leading: const Icon(Icons.ios_share, color: AppColors.navy),
                    title: const Text('백업 파일 내보내기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('전체 데이터를 JSON 파일로 저장/전송', style: TextStyle(fontSize: 12)),
                    trailing: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    onTap: kIsWeb || _busy ? null : _handleExport,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: !kIsWeb && !_busy,
                    leading: const Icon(Icons.file_download_outlined, color: AppColors.navy),
                    title: const Text('백업 파일 가져오기(복원)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('백업 파일로 데이터를 복원해요', style: TextStyle(fontSize: 12)),
                    onTap: kIsWeb || _busy ? null : _handleImport,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('약관 및 정책', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.navy),
                    title: const Text('개인정보처리방침', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.navy),
                    title: const Text('이용약관', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('앱 정보', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.navy),
                title: const Text('WishUp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('v1.0.0 · 모든 데이터는 기기에 안전하게 저장됩니다', style: TextStyle(fontSize: 11.5)),
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
                '스마트 인사이트가 당신의 패턴을 분석하고 실제 현실의 변화를 돕는\n'
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
