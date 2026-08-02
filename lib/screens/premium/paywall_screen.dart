import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/purchase_service.dart';
import '../../services/entitlement_service.dart';
import '../../theme/app_theme.dart';

/// 프리미엄 멤버십 안내 및 구독 화면.
///
/// [triggerReason]을 전달하면 어떤 한도 때문에 이 화면에 도달했는지에 맞춰
/// 상단 안내 문구가 달라집니다(예: 목표 개수 제한, 습관 개수 제한 등).
class PaywallScreen extends StatefulWidget {
  final String? triggerReason;
  const PaywallScreen({super.key, this.triggerReason});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlanId = PurchaseService.plans.last.id; // 기본 선택: 연간(할인)
  bool _busy = false;

  Future<void> _handlePurchase() async {
    setState(() => _busy = true);
    final result = await PurchaseService.purchase(_selectedPlanId);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case PurchaseResult.success:
        await context.read<AppState>().setPremiumStatus(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 프리미엄 멤버십이 시작되었어요!')),
        );
        Navigator.pop(context);
        break;
      case PurchaseResult.notReady:
        _showNotReadyDialog();
        break;
      case PurchaseResult.cancelled:
        break;
      case PurchaseResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제에 실패했어요. 잠시 후 다시 시도해주세요.')),
        );
        break;
    }
  }

  void _showNotReadyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('곧 만나요! 🚀'),
        content: const Text(
          '프리미엄 결제 기능은 스토어 심사 및 결제 시스템 연동이 완료되는 대로 순차적으로 오픈될 예정이에요.\n'
          '오픈 시 알림으로 안내드릴게요!',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alreadyPremium = EntitlementService.isPremium;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✦', style: TextStyle(fontSize: 36, color: AppColors.gold)),
                    const SizedBox(height: 12),
                    const Text(
                      'WishUp 프리미엄',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.triggerReason ?? '더 많은 목표와 습관을, 제한 없이 기록하세요.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    if (alreadyPremium)
                      _buildAlreadyPremiumBanner()
                    else ...[
                      ..._features.map(_featureRow),
                      const SizedBox(height: 28),
                      ...PurchaseService.plans.map(_planCard),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _handlePurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.navyDark,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark),
                                )
                              : const Text('프리미엄 시작하기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _busy ? null : _handleRestore,
                          child: const Text('구매 복원', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '언제든지 스토어(구글 플레이/앱스토어)에서 자동 갱신을 취소할 수 있어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRestore() async {
    setState(() => _busy = true);
    final result = await PurchaseService.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == PurchaseResult.success) {
      await context.read<AppState>().setPremiumStatus(true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('구매가 복원되었어요.')));
    } else {
      _showNotReadyDialog();
    }
  }

  Widget _buildAlreadyPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified, color: AppColors.gold),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '이미 프리미엄 멤버십을 이용 중이에요. 모든 기능이 무제한으로 열려있어요!',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _features = [
    {'icon': '🎯', 'title': '무제한 목표', 'desc': '동시에 몇 개든 목표를 만들고 관리하세요 (무료: 최대 3개)'},
    {'icon': '🔁', 'title': '무제한 습관', 'desc': '정체성 습관을 원하는 만큼 추적하세요 (무료: 최대 3개)'},
    {'icon': '🖼', 'title': '무제한 비전보드', 'desc': '이미지·글 카드를 자유롭게 채워보세요 (무료: 최대 5개)'},
    {'icon': '✉️', 'title': '우주편지 무제한 작성', 'desc': '월 1회 제한 없이 미래의 나에게 편지를 쓰세요'},
    {'icon': '📊', 'title': '전체 히스토리 분석', 'desc': '기록이 쌓일수록 더 깊어지는 인사이트를 확인하세요'},
  ];

  Widget _featureRow(Map<String, String> f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f['icon']!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(f['desc']!, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(PurchasePlan plan) {
    final selected = _selectedPlanId == plan.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = plan.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.gold : Colors.white24, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.gold : Colors.white38,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                          child: Text(plan.badge!, style: const TextStyle(color: AppColors.navyDark, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  if (plan.subLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(plan.subLabel!, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            Text('${plan.price} / ${plan.periodLabel}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
