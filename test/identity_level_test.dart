// 정체성 레벨(게이미피케이션) 로직 회귀 테스트.
// 레벨은 "절대 감소하지 않는" 장기 동기부여 장치이므로 경계값 계산이
// 틀리면 사용자가 레벨업/다운을 오인해 신뢰를 잃을 수 있는 민감한 로직이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:wishup/widgets/level_badge.dart';

void main() {
  group('IdentityLevel.fromPoints 경계값', () {
    test('0pt는 seed', () {
      expect(IdentityLevelX.fromPoints(0), IdentityLevel.seed);
    });

    test('99pt는 여전히 seed (경계 직전)', () {
      expect(IdentityLevelX.fromPoints(99), IdentityLevel.seed);
    });

    test('100pt 정확히 sprout으로 승급', () {
      expect(IdentityLevelX.fromPoints(100), IdentityLevel.sprout);
    });

    test('299pt는 sprout', () {
      expect(IdentityLevelX.fromPoints(299), IdentityLevel.sprout);
    });

    test('300pt 정확히 bud로 승급', () {
      expect(IdentityLevelX.fromPoints(300), IdentityLevel.bud);
    });

    test('600pt 정확히 bloom으로 승급', () {
      expect(IdentityLevelX.fromPoints(600), IdentityLevel.bloom);
    });

    test('1000pt 정확히 tree(최고 레벨)로 승급', () {
      expect(IdentityLevelX.fromPoints(1000), IdentityLevel.tree);
    });

    test('1000pt를 초과해도 tree를 유지한다(오버플로 방지)', () {
      expect(IdentityLevelX.fromPoints(999999), IdentityLevel.tree);
    });

    test('음수 포인트가 들어와도 크래시 없이 seed로 처리된다(방어 로직)', () {
      expect(IdentityLevelX.fromPoints(-10), IdentityLevel.seed);
    });
  });

  group('IdentityLevel.next 진행 순서', () {
    test('seed -> sprout -> bud -> bloom -> tree 순서를 따른다', () {
      expect(IdentityLevel.seed.next, IdentityLevel.sprout);
      expect(IdentityLevel.sprout.next, IdentityLevel.bud);
      expect(IdentityLevel.bud.next, IdentityLevel.bloom);
      expect(IdentityLevel.bloom.next, IdentityLevel.tree);
    });

    test('tree(최고 레벨)의 next는 null이다', () {
      expect(IdentityLevel.tree.next, isNull);
    });
  });

  group('IdentityLevel 표시 속성', () {
    test('모든 레벨은 비어있지 않은 emoji와 label을 가진다', () {
      for (final level in IdentityLevel.values) {
        expect(level.emoji, isNotEmpty);
        expect(level.label, isNotEmpty);
      }
    });

    test('minPoints는 레벨 순서대로 오름차순이다', () {
      final points = IdentityLevel.values.map((l) => l.minPoints).toList();
      for (var i = 1; i < points.length; i++) {
        expect(points[i], greaterThan(points[i - 1]));
      }
    });
  });
}
