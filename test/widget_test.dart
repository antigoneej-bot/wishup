// WishUp 기본 스모크 테스트
import 'package:flutter_test/flutter_test.dart';

import 'package:wishup/main.dart';

void main() {
  testWidgets('WishUp app launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WishUpApp());
    await tester.pump(const Duration(milliseconds: 500));
    // 앱이 크래시 없이 렌더링되는지 확인
    expect(find.byType(WishUpApp), findsOneWidget);
  });
}
