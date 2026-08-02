import '../services/storage_service.dart';

/// 무료 이용자에게 적용되는 한도.
/// "기능을 잠그기보다 양(量)과 지속성을 제한한다"는 프리미엄 전략에 따라,
/// 핵심 기능은 누구나 사용할 수 있고 개수/빈도만 제한합니다.
class FreeLimits {
  static const int maxGoals = 3; // 동시에 진행 가능한 목표 수
  static const int maxHabits = 3; // 동시에 추적 가능한 습관 수
  static const int maxVisionItems = 5; // 비전보드 카드 수
  static const int maxLettersPerMonth = 1; // 우주편지 작성 개수(월)
}

/// 프리미엄 구독 상태를 로컬에 저장/조회하는 서비스.
///
/// ⚠️ 참고: 현재는 실제 스토어 결제(RevenueCat/App Store/Play Billing)가 연동되지
/// 않은 상태이므로, 이 값은 향후 결제 SDK 연동 시 구매 성공/구독 갱신 콜백에서
/// [setPremium]을 호출하여 갱신하도록 설계되어 있습니다.
class EntitlementService {
  static const _key = 'isPremium';

  static bool get isPremium =>
      StorageService.settings.get(_key, defaultValue: false) as bool;

  static Future<void> setPremium(bool value) async {
    await StorageService.settings.put(_key, value);
  }
}
