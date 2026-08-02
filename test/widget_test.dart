// WishUp 앱 스모크 & 핵심 네비게이션 흐름 테스트.
//
// ⚠️ 참고 1: 기존에는 Hive 박스를 열지 않은 채 WishUpApp을 pumpWidget 하여
// "Box not found" HiveError로 조용히 실패하고 있었다(그린 표시였지만 실제로는
// 크래시하는 테스트). test_helpers/hive_test_helper로 실제 앱과 동일한
// 이름의 박스를 임시 디렉터리에 열어 정상적으로 앱 부팅 경로를 검증하도록 고쳤다.
//
// ⚠️ 참고 2 (중요): flutter_test의 기본 위젯 테스트 바인딩은 "가짜(fake) 비동기"
// 환경에서 동작하기 때문에, 버튼 탭 콜백 내부에서 실행되는 실제 디스크 I/O
// (Hive box.put() 등)는 tester.pump()/pumpAndSettle() 만으로는 절대 완료되지
// 않고 무한 대기한다(공식적으로 문서화된 Flutter 테스트 함정). 이 문제는
// "온보딩 완료" 버튼처럼 실제 비동기 저장 작업을 트리거하는 탭에 한해
// tester.runAsync()로 감싸 실제 이벤트 루프를 잠깐 열어주는 방식으로 해결한다.
// (이 이슈는 이번 세션에서 새로 발견되어 수정되었다 — 상세는 QA 문서 참고)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wishup/main.dart';
import 'package:wishup/screens/main_navigation.dart';
import 'package:wishup/screens/onboarding/onboarding_screen.dart';

import 'test_helpers/hive_test_helper.dart';

/// 온보딩 3단계(환영 → 이름 입력 → 관심 영역 선택)를 완료하고
/// 메인 화면으로 전환될 때까지 진행하는 공용 헬퍼.
///
/// 마지막 "시작하기" 탭은 실제 Hive 디스크 쓰기(completeOnboarding)를
/// 트리거하므로 반드시 tester.runAsync()로 감싸야 한다.
Future<void> _completeOnboarding(
  WidgetTester tester, {
  required String name,
  required String areaKeyword,
}) async {
  // 1) 환영 페이지 -> 이름 페이지
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();

  // 2) 이름 입력 -> 관심 영역 페이지
  await tester.enterText(find.byType(TextField), name);
  await tester.pumpAndSettle();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();

  // 3) 관심 영역 선택
  await tester.tap(find.textContaining(areaKeyword));
  await tester.pumpAndSettle();

  // 4) 온보딩 완료: 실제 Hive 저장(await StorageService.settings.put ...)이
  //    발생하므로 runAsync로 감싸 진짜 이벤트 루프에서 완료되도록 한다.
  await tester.runAsync(() async {
    await tester.tap(find.text('시작하기'), warnIfMissed: true);
    // completeOnboarding()의 3번의 Hive put + notifyListeners + Navigator
    // pushReplacement가 실제로 처리될 시간을 준다.
    await Future.delayed(const Duration(milliseconds: 300));
  });
  await tester.pumpAndSettle();
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveForTest();
    await clearHiveBoxesForTest();
  });

  tearDown(() async {
    await closeHiveForTest(tempDir);
  });

  testWidgets('앱이 크래시 없이 부팅되어 온보딩 화면을 보여준다 (신규 사용자)', (WidgetTester tester) async {
    await tester.pumpWidget(const WishUpApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(WishUpApp), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('WishUp'), findsWidgets);
  });

  testWidgets('온보딩을 완료하면 하단 탭 4개가 있는 메인 화면으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const WishUpApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await _completeOnboarding(tester, name: '테스트유저', areaKeyword: '자기성장');

    expect(find.byType(MainNavigation), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('목표'), findsOneWidget);
    expect(find.text('저널'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
  });

  testWidgets('기존에 온보딩을 완료한 사용자는 바로 메인 화면으로 진입한다', (WidgetTester tester) async {
    await tester.pumpWidget(const WishUpApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await _completeOnboarding(tester, name: '재방문유저', areaKeyword: '건강');

    expect(find.byType(MainNavigation), findsOneWidget);

    // 앱을 다시 부팅해도(온보딩 재실행 없이) 바로 메인 화면으로 진입해야 한다.
    await tester.pumpWidget(const WishUpApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(MainNavigation), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('하단 탭을 눌러 화면을 전환할 수 있다', (WidgetTester tester) async {
    await tester.pumpWidget(const WishUpApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await _completeOnboarding(tester, name: '탭유저', areaKeyword: '커리어');

    await tester.tap(find.text('목표'));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigation), findsOneWidget);

    await tester.tap(find.text('저널'));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigation), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigation), findsOneWidget);
  });
}
