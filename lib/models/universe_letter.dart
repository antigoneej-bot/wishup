import 'dart:math';

/// 우주에 편지쓰기 (Letter to Universe) - 소원/목표를 담아 우주로 보내면,
/// 정해진 날짜에 "우주의 답장"이 도착하는 매니페스테이션 타임캡슐
class UniverseLetter {
  final String id;
  String content;
  DateTime createdAt;
  DateTime openDate; // 이 날짜가 지나야 열람 가능 (= 답장이 도착하는 날)
  bool isRead;

  /// 열람일에 도착하는 "우주의 답장" 메시지. 생성 시점에 미리 준비해두고,
  /// openDate가 지나면 함께 보여준다.
  String replyMessage;

  UniverseLetter({
    required this.id,
    required this.content,
    required this.openDate,
    DateTime? createdAt,
    this.isRead = false,
    String? replyMessage,
  })  : createdAt = createdAt ?? DateTime.now(),
        replyMessage = replyMessage ?? UniverseReply.generate();

  bool get isUnlocked => DateTime.now().isAfter(openDate);

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'openDate': openDate.toIso8601String(),
        'isRead': isRead,
        'replyMessage': replyMessage,
      };

  factory UniverseLetter.fromMap(Map map) => UniverseLetter(
        id: map['id'] as String,
        content: map['content'] as String? ?? '',
        openDate: map['openDate'] != null
            ? DateTime.tryParse(map['openDate'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        isRead: map['isRead'] as bool? ?? false,
        replyMessage: map['replyMessage'] as String?,
      );
}

/// "우주의 답장" 메시지 생성기.
/// 사용자가 쓴 소원이 이미 이루어졌다는 확신을 담은 짧은 답장을 무작위로 골라준다.
class UniverseReply {
  static final Random _rand = Random();

  static const List<String> _templates = [
    '당신이 보낸 소망이 무사히 도착했어요.\n우주는 이미 그 진동에 응답했고,\n지금 이 순간 당신의 소원은 현실로 이루어졌습니다. ✨',
    '편지 잘 받았어요.\n당신이 그렸던 그 장면은 이미 시작되었어요.\n필요한 모든 것이 지금 당신에게 오고 있습니다. 🌌',
    '축하해요 — 당신의 소원이 이루어졌어요!\n우주는 당신의 정성과 믿음을 알아봤고,\n그 에너지는 이미 현실이 되어 당신 곁에 있습니다. 🎉',
    '당신의 편지가 우주에 닿았어요.\n그리고 응답이 왔습니다: "이미 이루어졌다."\n이제 그 결과를 하나씩 발견해보세요. 💫',
    '기다려줘서 고마워요.\n당신이 믿었던 그 순간부터, 소원은 이미 현실이 되고 있었어요.\n오늘, 그 증거를 마주하게 될 거예요. 🌠',
    '우주가 응답했습니다.\n당신이 담았던 소망은 이미 이루어졌고,\n지금 그 결실이 당신 삶에 스며들고 있어요. 🌙',
    '당신의 목표는 이미 성취되었어요.\n의심하지 마세요 — 필요한 문들이 지금 열리고 있으니까요.\n오늘 하루, 그 흐름을 느껴보세요. 🔑',
    '소원 접수 완료, 그리고 이루어짐 확인!\n우주는 당신이 보낸 에너지를 그대로 되돌려주었어요.\n이제 당신의 삶에서 그 변화를 마주할 시간이에요. 🪐',
  ];

  static String generate() => _templates[_rand.nextInt(_templates.length)];
}
