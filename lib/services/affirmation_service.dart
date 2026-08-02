import 'dart:math';
import '../models/goal.dart';

/// 카테고리별 확언 + 정체성 선언문 라이브러리
class AffirmationService {
  static final Map<GoalCategory, List<String>> _library = {
    GoalCategory.career: [
      '나는 나의 재능을 세상에 자연스럽게 펼치는 사람이다.',
      '내가 하는 일은 점점 더 인정받고 성장하고 있다.',
      '나는 기회를 알아보고 행동으로 옮기는 사람이다.',
      '나의 경력은 매일 더 나은 방향으로 나아가고 있다.',
    ],
    GoalCategory.wealth: [
      '풍요는 다양한 방식으로 나에게 흘러들어온다.',
      '나는 돈과 건강한 관계를 맺고 있는 사람이다.',
      '나는 가치를 만들고, 그만큼 정당하게 보상받는다.',
      '나의 재정 상태는 매달 더 안정되고 커지고 있다.',
    ],
    GoalCategory.love: [
      '나는 사랑받고 존중받을 자격이 충분한 사람이다.',
      '나는 건강하고 안전한 관계를 끌어당긴다.',
      '나의 관계들은 서로 성장하게 돕는다.',
      '나는 있는 그대로 사랑스러운 사람이다.',
    ],
    GoalCategory.health: [
      '나는 내 몸을 존중하고 돌보는 사람이다.',
      '내 몸은 매일 회복되고 강해지고 있다.',
      '나는 활력과 에너지로 가득 차 있다.',
      '건강한 선택은 나에게 자연스러운 일이다.',
    ],
    GoalCategory.growth: [
      '나는 매일 조금씩 더 나은 사람이 되고 있다.',
      '나는 배우고 성장하는 것을 즐기는 사람이다.',
      '나의 한계는 내가 다시 정의할 수 있다.',
      '나는 불확실함 속에서도 나를 믿는다.',
    ],
    GoalCategory.family: [
      '나의 집은 평온하고 사랑이 흐르는 공간이다.',
      '나는 가족과 깊고 따뜻한 관계를 만들어간다.',
      '나는 내가 속한 공간에 안정감을 준다.',
      '우리 가족은 서로를 지지하며 함께 성장한다.',
    ],
  };

  static const List<String> _general = [
    '나는 내가 원하는 삶을 창조할 힘이 있다.',
    '우주는 나를 위해 움직이고 있다.',
    '나는 지금 이 순간에도 원하는 것을 향해 나아가고 있다.',
    '내가 집중하는 것이 곧 나의 현실이 된다.',
    '나는 오늘도 조금씩 더 원하는 나에게 가까워지고 있다.',
  ];

  /// 오늘의 확언 (날짜 시드로 고정되어, 하루 동안 동일한 확언 노출)
  static String dailyAffirmation({GoalCategory? preferredCategory}) {
    final pool = preferredCategory != null
        ? [..._library[preferredCategory]!, ..._general]
        : _general;
    final seed = DateTime.now().year * 1000 + DateTime.now().month * 31 + DateTime.now().day;
    final rnd = Random(seed);
    return pool[rnd.nextInt(pool.length)];
  }

  static String randomFor(GoalCategory category) {
    final list = _library[category] ?? _general;
    return list[Random().nextInt(list.length)];
  }

  static List<String> all(GoalCategory category) => _library[category] ?? _general;
}
