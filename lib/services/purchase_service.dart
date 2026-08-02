/// 결제 플랜 정의 및 RevenueCat(Google Play Billing) 연동 처리.
///
/// ⚠️ 실제 결제가 동작하려면 아래 설정이 반드시 필요합니다 (2026년 기준 RevenueCat
/// 대시보드 플로우 — docs.revenuecat.com 기준으로 검증됨).
///
///   1) Google Play Console (https://play.google.com/console)
///      - 개발자 계정 등록 (최초 1회, $25 등록비) 및 앱 생성 (패키지명: com.wishup.goals)
///      - 서명된 AAB를 내부 테스트(Internal testing) 트랙에 최소 1회 업로드
///        (구독 상품을 만들려면 앱이 최소 한 번 업로드되어 있어야 함)
///      - 수익 창출 → 상품 → 구독 메뉴에서 아래와 동일한 ID로 구독 상품 2개 등록:
///          - wishup_premium_monthly (월간)
///          - wishup_premium_yearly  (연간)
///
///   2) RevenueCat (https://app.revenuecat.com) — 계정 생성 후:
///      a. Project 생성 → Apps → "+ New" → Google Play Store 선택
///         → App name / Package name(com.wishup.goals) 입력
///      b. **Service Credentials(중요, 신규 필수 단계)**: Google Play와의 실시간
///         구독 상태 검증을 위해 Google Cloud 서비스 계정 JSON 키가 필요합니다.
///         RevenueCat 대시보드의 "Where do I find my service credentials?" 가이드
///         (Project Settings → Google Play App Settings → Service account
///         credentials)를 그대로 따라가면 자동화 스크립트를 제공합니다:
///           - Google Cloud Console → 프로젝트 선택 → Cloud Shell 실행
///           - RevenueCat 문서에 있는 setup 스크립트 실행 (androidpublisher API,
///             Pub/Sub API 활성화 + 서비스 계정 생성 + 키 발급을 자동 처리)
///           - 발급된 revenuecat-key.json을 RevenueCat에 업로드
///           - Google Play Console → 사용자 및 권한에서 해당 서비스 계정에
///             "계정 관리" 권한 부여 필요
///      c. 위 App 연결이 완료되면 자동 발급되는 **"Public API key(SDK API key)"**
///         (goog_로 시작)를 아래 [_androidApiKey]에 붙여넣기
///      d. Product catalog → Entitlements에서 "premium" 식별자로 Entitlement 생성
///      e. 위 2개 구독 상품을 Google Play에서 가져와(Import) "premium" Entitlement에
///         연결(Attach)
///      f. Offerings에서 "default" Offering을 만들고 두 상품을 Package로 추가
///
/// 위 설정이 완료되고 [_androidApiKey]가 채워지기 전까지는 [purchase]/[restore]가
/// 항상 [PurchaseResult.notReady]를 반환해 "준비 중" 안내만 표시합니다(안전한 기본값).
///
/// 참고: Service Credentials 설정 없이 Public API key만 넣어도 SDK 초기화 자체는
/// 되지만, Google Play가 구독 상태를 RevenueCat에 실시간으로 통보하지 못해 구매
/// 검증/복원이 불안정할 수 있습니다. 반드시 b) 단계까지 완료할 것을 권장합니다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
// ⚠️ 별칭(as rc) 필수: purchases_flutter 패키지도 'PurchaseResult'라는 이름의
// 클래스를 export하므로, 별칭 없이 import하면 아래 앱 자체 enum과 이름이 충돌해
// 타입 추론이 잘못됩니다 (예: result.entitlements 접근 시 컴파일 에러 발생).
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

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
  /// RevenueCat 대시보드 → Project settings → API keys →
  /// "Public app-specific API key"(Google Play Store)를 여기에 붙여넣으세요.
  /// 예: goog_XXXXXXXXXXXXXXXXXXXXXXXXXXX
  static const String _androidApiKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';

  /// RevenueCat 대시보드에서 생성한 Entitlement 식별자(기본값 "premium").
  static const String entitlementId = 'premium';

  static bool _initialized = false;

  /// 실제 API 키가 채워졌는지 여부. 채워지기 전까지는 모든 결제 기능이 안전하게
  /// notReady 상태로 동작합니다.
  static bool get isConfigured =>
      _androidApiKey != 'YOUR_REVENUECAT_ANDROID_API_KEY' &&
      _androidApiKey.isNotEmpty;

  /// 예시 가격입니다. 실제 스토어 상품 등록 시 정확한 가격으로 교체해주세요.
  /// id 값은 Google Play Console에 등록한 구독 상품 ID와 정확히 일치해야 합니다.
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

  /// 앱 시작 시 1회 호출 (main.dart에서 kIsWeb 가드 후 호출).
  /// RevenueCat은 웹을 지원하지 않으므로 웹에서는 아무 동작도 하지 않습니다.
  static Future<void> init() async {
    if (kIsWeb || _initialized || !isConfigured) return;
    try {
      await rc.Purchases.setLogLevel(
        kDebugMode ? rc.LogLevel.debug : rc.LogLevel.info,
      );
      final config = rc.PurchasesConfiguration(_androidApiKey);
      await rc.Purchases.configure(config);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseService.init failed: $e');
    }
  }

  /// 현재 로그인된 고객의 CustomerInfo를 조회해 "premium" Entitlement가
  /// 활성 상태인지 확인합니다. 앱 시작 시 로컬 저장된 프리미엄 상태를
  /// 서버 상태와 동기화하는 용도로 사용하세요.
  static Future<bool> checkEntitlement() async {
    if (kIsWeb || !isConfigured || !_initialized) return false;
    try {
      final info = await rc.Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseService.checkEntitlement failed: $e');
      return false;
    }
  }

  /// 구매 시도. RevenueCat에서 현재 Offering의 패키지 중 [planId]와 일치하는
  /// 상품을 찾아 구매를 진행합니다.
  static Future<PurchaseResult> purchase(String planId) async {
    if (kIsWeb || !isConfigured) {
      await Future.delayed(const Duration(milliseconds: 350));
      return PurchaseResult.notReady;
    }
    if (!_initialized) await init();
    if (!_initialized) return PurchaseResult.notReady;

    try {
      final offerings = await rc.Purchases.getOfferings();
      final current = offerings.current;
      rc.Package? package;

      if (current != null) {
        for (final pkg in current.availablePackages) {
          if (pkg.storeProduct.identifier == planId ||
              pkg.identifier == planId) {
            package = pkg;
            break;
          }
        }
      }
      // current Offering에 없다면 전체 Offerings에서 탐색
      if (package == null) {
        for (final offering in offerings.all.values) {
          for (final pkg in offering.availablePackages) {
            if (pkg.storeProduct.identifier == planId ||
                pkg.identifier == planId) {
              package = pkg;
              break;
            }
          }
          if (package != null) break;
        }
      }

      if (package == null) {
        if (kDebugMode) {
          debugPrint(
            'PurchaseService.purchase: no package found for $planId (Offerings/상품 설정 확인 필요)',
          );
        }
        return PurchaseResult.notReady;
      }

      final result = await rc.Purchases.purchase(
        rc.PurchaseParams.package(package),
      );
      final active = result.customerInfo.entitlements.active.containsKey(
        entitlementId,
      );
      return active ? PurchaseResult.success : PurchaseResult.failed;
    } catch (e) {
      if (e is PlatformException) {
        final code = rc.PurchasesErrorHelper.getErrorCode(e);
        if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
          return PurchaseResult.cancelled;
        }
      }
      if (kDebugMode) debugPrint('PurchaseService.purchase failed: $e');
      return PurchaseResult.failed;
    }
  }

  /// 구매 복원 시도(기기 변경 시 등).
  static Future<PurchaseResult> restore() async {
    if (kIsWeb || !isConfigured) {
      await Future.delayed(const Duration(milliseconds: 350));
      return PurchaseResult.notReady;
    }
    if (!_initialized) await init();
    if (!_initialized) return PurchaseResult.notReady;

    try {
      final info = await rc.Purchases.restorePurchases();
      final active = info.entitlements.active.containsKey(entitlementId);
      return active ? PurchaseResult.success : PurchaseResult.failed;
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseService.restore failed: $e');
      return PurchaseResult.failed;
    }
  }
}
