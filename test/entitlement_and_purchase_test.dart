// 프리미엄 엔타이틀먼트 & 결제 서비스(RevenueCat) 안전장치 회귀 테스트.
//
// 결제는 실패 시 매출에 직결되는 영역이라 가장 보수적으로 테스트한다.
// 실제 스토어 SDK 호출은 통합/실기기 테스트 영역이므로 여기서는
// "API 키가 설정되지 않은 현재 상태에서 절대 실 결제 SDK를 건드리지 않고
// 안전하게 notReady로 폴백하는지"를 검증하는 데 집중한다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wishup/services/entitlement_service.dart';
import 'package:wishup/services/purchase_service.dart';

import 'test_helpers/hive_test_helper.dart';

void main() {
  group('FreeLimits (무료 이용자 한도)', () {
    test('무료 한도 값이 기획 스펙과 일치한다', () {
      expect(FreeLimits.maxGoals, 3);
      expect(FreeLimits.maxHabits, 3);
      expect(FreeLimits.maxVisionItems, 5);
      expect(FreeLimits.maxLettersPerMonth, 1);
    });
  });

  group('EntitlementService (로컬 프리미엄 플래그)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await initHiveForTest();
    });

    tearDown(() async {
      await closeHiveForTest(tempDir);
    });

    test('초기 상태는 isPremium == false 이다', () {
      expect(EntitlementService.isPremium, false);
    });

    test('setPremium(true) 이후 isPremium이 true로 반영된다', () async {
      await EntitlementService.setPremium(true);
      expect(EntitlementService.isPremium, true);
    });

    test('setPremium(false)로 다시 되돌릴 수 있다(구독 만료/취소 시나리오)', () async {
      await EntitlementService.setPremium(true);
      expect(EntitlementService.isPremium, true);
      await EntitlementService.setPremium(false);
      expect(EntitlementService.isPremium, false);
    });
  });

  group('PurchaseService (RevenueCat 연동 안전장치)', () {
    test('플레이스홀더 API 키 상태에서는 isConfigured가 false다', () {
      // ⚠️ 이 값이 실수로 true가 되면 실제 API 키 없이 SDK 초기화를 시도해
      // 크래시로 이어질 수 있으므로 반드시 회귀 방지가 필요하다.
      expect(PurchaseService.isConfigured, false);
    });

    test('플랜 목록에 월간/연간 상품이 기획된 ID로 정확히 존재한다', () {
      expect(PurchaseService.plans, hasLength(2));
      final ids = PurchaseService.plans.map((p) => p.id).toList();
      expect(ids, contains('wishup_premium_monthly'));
      expect(ids, contains('wishup_premium_yearly'));
    });

    test('연간 플랜에는 할인 배지가 붙어있다', () {
      final yearly = PurchaseService.plans.firstWhere((p) => p.id == 'wishup_premium_yearly');
      expect(yearly.badge, isNotNull);
    });

    test('entitlementId는 RevenueCat 대시보드 설정과 동일한 "premium"이다', () {
      expect(PurchaseService.entitlementId, 'premium');
    });

    test('미설정 상태에서 purchase()는 SDK를 건드리지 않고 notReady를 반환한다', () async {
      final result = await PurchaseService.purchase('wishup_premium_monthly');
      expect(result, PurchaseResult.notReady);
    });

    test('미설정 상태에서 restore()도 안전하게 notReady를 반환한다', () async {
      final result = await PurchaseService.restore();
      expect(result, PurchaseResult.notReady);
    });

    test('미설정 상태에서 checkEntitlement()는 false를 반환한다(프리미엄 미인증 취급)', () async {
      final active = await PurchaseService.checkEntitlement();
      expect(active, false);
    });

    test('존재하지 않는 planId로 구매를 시도해도 크래시하지 않는다', () async {
      final result = await PurchaseService.purchase('no_such_plan_id');
      expect(result, PurchaseResult.notReady);
    });
  });
}
