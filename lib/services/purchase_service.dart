/// 결제 플랜 정의 및 구매 처리 스텁.
///
/// ⚠️ 매우 중요: 이 클래스는 실제 스토어 결제와 연동되어 있지 않습니다.
/// 실제 서비스 오픈 전, 아래 두 가지가 준비되면 [purchase] 메서드의 내부 구현을
/// RevenueCat(`purchases_flutter`) SDK 호출로 교체해야 합니다.
///   1) Google Play Console / App Store Connect에 인앱 구독 상품 등록
///   2) RevenueCat(또는 유사 서비스) 계정 생성 및 API 키 발급
/// 그 전까지는 구매 버튼을 눌러도 결제가 발생하지 않으며, [PurchaseResult.notReady]를
/// 반환해 "준비 중" 안내만 표시합니다.
library;

class PurchasePlan {
  final String id;
  final String title;
  final String price;
  final String periodLabel;
  final String? badge;
  final String? subLabel;

  const PurchasePlan({
    required this.id,
    required this.title,
    required this.price,
    required this.periodLabel,
    this.badge,
    this.subLabel,
  });
}

enum PurchaseResult { success, cancelled, notReady, failed }

class PurchaseService {
  /// 예시 가격입니다. 실제 스토어 상품 등록 시 정확한 가격으로 교체해주세요.
  static const List<PurchasePlan> plans = [
    PurchasePlan(
      id: 'wishup_premium_monthly',
      title: '월간 멤버십',
      price: '₩4,900',
      periodLabel: '월',
    ),
    PurchasePlan(
      id: 'wishup_premium_yearly',
      title: '연간 멤버십',
      price: '₩29,900',
      periodLabel: '년',
      badge: '48% 할인',
      subLabel: '월 ₩2,491 상당',
    ),
  ];

  /// 구매 시도. 실제 결제 SDK가 연동되기 전까지는 항상 [PurchaseResult.notReady]를
  /// 반환합니다.
  static Future<PurchaseResult> purchase(String planId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return PurchaseResult.notReady;
  }

  /// 구매 복원 시도(기기 변경 시 등). 결제 SDK 연동 전까지는 항상 실패 처리합니다.
  static Future<PurchaseResult> restore() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return PurchaseResult.notReady;
  }
}
