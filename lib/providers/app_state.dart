import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/vision_item.dart';
import '../models/universe_letter.dart';
import '../models/celebration.dart';
import '../services/storage_service.dart';
import '../services/ai_insight_service.dart';
import '../services/notification_service.dart';
import '../services/moon_phase_service.dart';
import '../services/entitlement_service.dart';
import '../services/purchase_service.dart';
import '../widgets/level_badge.dart';

const _uuid = Uuid();

/// 스토어 스크린샷 촬영 등 데모 목적일 때만 활성화되는 샘플 데이터 시드 플래그.
/// 빌드 시 --dart-define=SEED_DEMO=true 를 명시적으로 넘기지 않으면 항상 false이며,
/// 일반 프로덕션 빌드에는 절대 영향을 주지 않습니다.
const bool kSeedDemoData = bool.fromEnvironment('SEED_DEMO', defaultValue: false);

/// 앱 전역 상태 관리 (Provider)
/// 모든 데이터 CRUD + 파생 데이터(에너지 스코어, AI 인사이트) 계산
class AppState extends ChangeNotifier {
  bool onboardingCompleted = false;
  String userName = '';
  List<GoalCategory> focusAreas = [];

  List<Goal> goals = [];
  List<Habit> habits = [];
  List<JournalEntry> journalEntries = [];
  List<VisionItem> visionItems = [];
  List<UniverseLetter> letters = [];

  bool affirmationNotifEnabled = false;
  bool habitNotifEnabled = false;
  bool moonRitualNotifEnabled = false;
  String scriptingWish = '';

  Future<void> load() async {
    final settings = StorageService.settings;
    onboardingCompleted =
        settings.get('onboardingCompleted', defaultValue: false) as bool;
    userName = settings.get('userName', defaultValue: '') as String;
    final areas = settings.get('focusAreas', defaultValue: <String>[]) as List;
    focusAreas = areas
        .map(
          (a) => GoalCategory.values.firstWhere(
            (c) => c.name == a,
            orElse: () => GoalCategory.growth,
          ),
        )
        .toList();

    goals =
        StorageService.goals.values.map((m) => Goal.fromMap(m as Map)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    habits = StorageService.habits.values
        .map((m) => Habit.fromMap(m as Map))
        .toList();
    journalEntries =
        StorageService.journal.values
            .map((m) => JournalEntry.fromMap(m as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    visionItems =
        StorageService.vision.values
            .map((m) => VisionItem.fromMap(m as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    letters =
        StorageService.letters.values
            .map((m) => UniverseLetter.fromMap(m as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    affirmationNotifEnabled =
        settings.get('affirmationNotifEnabled', defaultValue: false) as bool;
    habitNotifEnabled =
        settings.get('habitNotifEnabled', defaultValue: false) as bool;
    moonRitualNotifEnabled =
        settings.get('moonRitualNotifEnabled', defaultValue: false) as bool;
    scriptingWish = settings.get('scriptingWish', defaultValue: '') as String;

    if (moonRitualNotifEnabled) {
      await _rescheduleMoonRitual();
    }

    notifyListeners();
    // 서버(RevenueCat)의 실제 구독 상태와 로컬 프리미엄 플래그를 동기화.
    // 결제 SDK 미설정 상태에서는 항상 false를 반환해 안전하게 무시됩니다.
    unawaited(_syncEntitlementFromStore());
  }

  /// RevenueCat에 저장된 실제 구독 상태를 조회해 로컬 프리미엄 플래그를 갱신합니다.
  /// 다른 기기에서 결제했거나, 구독이 만료/취소된 경우를 반영합니다.
  Future<void> _syncEntitlementFromStore() async {
    if (!PurchaseService.isConfigured) return;
    try {
      final active = await PurchaseService.checkEntitlement();
      if (active != EntitlementService.isPremium) {
        await setPremiumStatus(active);
      }
    } catch (_) {}
  }

  // ---------------- Onboarding ----------------
  Future<void> completeOnboarding({
    required String name,
    required List<GoalCategory> areas,
  }) async {
    userName = name;
    focusAreas = areas;
    onboardingCompleted = true;
    await StorageService.settings.put('userName', name);
    await StorageService.settings.put(
      'focusAreas',
      areas.map((a) => a.name).toList(),
    );
    await StorageService.settings.put('onboardingCompleted', true);
    notifyListeners();
    if (kSeedDemoData) {
      await seedDemoDataIfNeeded();
    }
  }

  /// 스토어 스크린샷 촬영용 샘플 데이터 주입.
  /// kSeedDemoData 빌드 플래그가 켜져 있고 아직 아무 데이터도 없을 때만 동작합니다.
  Future<void> seedDemoDataIfNeeded() async {
    if (!kSeedDemoData) return;
    if (goals.isNotEmpty || habits.isNotEmpty) return;

    final now = DateTime.now();

    final demoGoals = [
      Goal(
        id: _uuid.v4(),
        title: '이상적인 몸과 에너지 만들기',
        identityStatement: '나는 매일 활력 넘치는 건강한 사람이다',
        category: GoalCategory.health,
        progress: 0.65,
        targetDate: now.add(const Duration(days: 60)),
        milestones: [
          Milestone(id: _uuid.v4(), title: '주 3회 운동 루틴 만들기', isDone: true),
          Milestone(id: _uuid.v4(), title: '식단 기록 앱 사용하기', isDone: true),
          Milestone(id: _uuid.v4(), title: '체지방률 목표 도달', isDone: false),
        ],
      ),
      Goal(
        id: _uuid.v4(),
        title: '월 1,000만원 파이프라인 만들기',
        identityStatement: '나는 풍요와 기회를 끌어당기는 사람이다',
        category: GoalCategory.wealth,
        progress: 0.4,
        targetDate: now.add(const Duration(days: 180)),
        milestones: [
          Milestone(id: _uuid.v4(), title: '사이드 프로젝트 런칭', isDone: true),
          Milestone(id: _uuid.v4(), title: '첫 매출 발생', isDone: false),
        ],
      ),
      Goal(
        id: _uuid.v4(),
        title: '평생 함께할 인연 만나기',
        identityStatement: '나는 사랑받고 사랑을 주는 사람이다',
        category: GoalCategory.love,
        progress: 0.8,
        milestones: [
          Milestone(id: _uuid.v4(), title: '나를 먼저 사랑하기 연습', isDone: true),
          Milestone(id: _uuid.v4(), title: '새로운 인연 시도해보기', isDone: true),
        ],
      ),
    ];
    for (final g in demoGoals) {
      await StorageService.goals.put(g.id, g.toMap());
    }
    goals = demoGoals;

    final demoHabits = [
      Habit(
        id: _uuid.v4(),
        title: '아침 확언 외치기',
        streak: 12,
        completedDates: _lastNDays(12),
        linkedGoalId: demoGoals[0].id,
      ),
      Habit(
        id: _uuid.v4(),
        title: '감사 일기 쓰기',
        streak: 7,
        completedDates: _lastNDays(7),
      ),
      Habit(
        id: _uuid.v4(),
        title: '시각화 명상 5분',
        streak: 3,
        completedDates: _lastNDays(3),
        linkedGoalId: demoGoals[2].id,
      ),
    ];
    for (final h in demoHabits) {
      await StorageService.habits.put(h.id, h.toMap());
    }
    habits = demoHabits;

    final demoJournal = [
      JournalEntry(
        id: _uuid.v4(),
        type: JournalType.gratitude,
        content: '오늘 아침 따뜻한 햇살과 맛있는 커피 한 잔에 감사해요.',
        moodScore: 5,
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        type: JournalType.evidence,
        content: '우연히 예전에 꿈꾸던 회사에서 채용 제안 메일이 왔어요. 우주가 응답하고 있어요!',
        moodScore: 5,
        linkedGoalId: demoGoals[1].id,
        createdAt: now.subtract(const Duration(minutes: 90)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        type: JournalType.script,
        content: '나는 이미 원하는 삶을 살고 있다',
        period: ScriptPeriod.morning.name,
        createdAt: now.subtract(const Duration(minutes: 100)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        type: JournalType.script,
        content: '나는 이미 원하는 삶을 살고 있다',
        period: ScriptPeriod.morning.name,
        createdAt: now.subtract(const Duration(minutes: 105)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        type: JournalType.script,
        content: '나는 이미 원하는 삶을 살고 있다',
        period: ScriptPeriod.morning.name,
        createdAt: now.subtract(const Duration(minutes: 110)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        type: JournalType.moodOnly,
        content: '오늘은 컨디션이 아주 좋아요',
        moodScore: 4,
        createdAt: now.subtract(const Duration(minutes: 200)),
      ),
    ];
    for (final j in demoJournal) {
      await StorageService.journal.put(j.id, j.toMap());
    }
    journalEntries = demoJournal;
    scriptingWish = '나는 이미 원하는 삶을 살고 있다';
    await StorageService.settings.put('scriptingWish', scriptingWish);

    final demoVision = [
      VisionItem(
        id: _uuid.v4(),
        imagePath: 'assets/images/vision_examples/wealth.jpg',
        caption: '풍요로운 나의 삶',
        isAssetImage: true,
      ),
      VisionItem(
        id: _uuid.v4(),
        imagePath: 'assets/images/vision_examples/career.jpg',
        caption: '성취를 이룬 나의 커리어',
        isAssetImage: true,
      ),
      VisionItem(
        id: _uuid.v4(),
        imagePath: 'assets/images/vision_examples/love.jpg',
        caption: '사랑으로 충만한 관계',
        isAssetImage: true,
      ),
    ];
    for (final v in demoVision) {
      await StorageService.vision.put(v.id, v.toMap());
    }
    visionItems = demoVision;

    final demoLetter = UniverseLetter(
      id: _uuid.v4(),
      content: '나는 이미 꿈꾸던 삶을 살고 있고, 모든 것이 완벽한 타이밍에 이루어지고 있다.',
      createdAt: now.subtract(const Duration(days: 5)),
      openDate: now.subtract(const Duration(days: 1)),
      isRead: false,
    );
    await StorageService.letters.put(demoLetter.id, demoLetter.toMap());
    letters = [demoLetter];

    notifyListeners();
  }

  List<String> _lastNDays(int n) {
    final today = DateTime.now();
    return List.generate(n, (i) => _fmtDate(today.subtract(Duration(days: i))));
  }

  // ---------------- Goals ----------------
  Future<Goal> addGoal({
    required String title,
    required String identityStatement,
    required GoalCategory category,
    DateTime? targetDate,
  }) async {
    final goal = Goal(
      id: _uuid.v4(),
      title: title,
      identityStatement: identityStatement,
      category: category,
      targetDate: targetDate,
    );
    goals.insert(0, goal);
    await StorageService.goals.put(goal.id, goal.toMap());
    notifyListeners();
    return goal;
  }

  Future<void> updateGoalProgress(String goalId, double progress) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    goal.progress = progress.clamp(0.0, 1.0);
    await StorageService.goals.put(goal.id, goal.toMap());
    notifyListeners();
  }

  Future<CelebrationType?> toggleMilestone(
    String goalId,
    String milestoneId,
  ) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    final m = goal.milestones.firstWhere((m) => m.id == milestoneId);
    final wasComplete = goal.progress >= 1.0;
    m.isDone = !m.isDone;
    if (goal.milestones.isNotEmpty) {
      goal.progress =
          goal.milestones.where((m) => m.isDone).length /
          goal.milestones.length;
    }
    await StorageService.goals.put(goal.id, goal.toMap());
    notifyListeners();
    if (!wasComplete && goal.progress >= 1.0) {
      return CelebrationType.goalComplete;
    }
    return null;
  }

  Future<void> addMilestone(String goalId, String title) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    goal.milestones.add(Milestone(id: _uuid.v4(), title: title));
    await StorageService.goals.put(goal.id, goal.toMap());
    notifyListeners();
  }

  Future<void> deleteGoal(String goalId) async {
    goals.removeWhere((g) => g.id == goalId);
    await StorageService.goals.delete(goalId);
    notifyListeners();
  }

  // ---------------- Habits ----------------
  Future<void> addHabit(String title, {String? linkedGoalId}) async {
    final habit = Habit(
      id: _uuid.v4(),
      title: title,
      linkedGoalId: linkedGoalId,
    );
    habits.add(habit);
    await StorageService.habits.put(habit.id, habit.toMap());
    notifyListeners();
  }

  Future<CelebrationType?> toggleHabitToday(String habitId) async {
    final habit = habits.firstWhere((h) => h.id == habitId);
    final today = _fmtDate(DateTime.now());
    CelebrationType? celebration;
    if (habit.completedDates.contains(today)) {
      habit.completedDates.remove(today);
      habit.streak = (habit.streak - 1).clamp(0, 999999);
    } else {
      habit.completedDates.add(today);
      habit.streak += 1;
      habit.lastCompletedAt = DateTime.now();
      if (habit.streak == 7) {
        celebration = CelebrationType.streak7;
      } else if (habit.streak == 30) {
        celebration = CelebrationType.streak30;
      } else if (habit.streak == 100) {
        celebration = CelebrationType.streak100;
      }
    }
    await StorageService.habits.put(habit.id, habit.toMap());
    notifyListeners();
    return celebration;
  }

  Future<void> deleteHabit(String habitId) async {
    habits.removeWhere((h) => h.id == habitId);
    await StorageService.habits.delete(habitId);
    notifyListeners();
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------- Journal ----------------
  Future<void> addJournalEntry({
    required JournalType type,
    required String content,
    int moodScore = 3,
    String? linkedGoalId,
    String? period,
  }) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      type: type,
      content: content,
      moodScore: moodScore,
      linkedGoalId: linkedGoalId,
      period: period,
    );
    journalEntries.insert(0, entry);
    await StorageService.journal.put(entry.id, entry.toMap());
    notifyListeners();
  }

  /// 오늘 작성된 369 스크립팅 개수 (시간대별)
  int scriptCountToday(ScriptPeriod p) {
    final today = _fmtDate(DateTime.now());
    return journalEntries
        .where(
          (e) =>
              e.type == JournalType.script &&
              e.period == p.name &&
              _fmtDate(e.createdAt) == today,
        )
        .length;
  }

  bool get scriptingAllCompleteToday =>
      ScriptPeriod.values.every((p) => scriptCountToday(p) >= p.target);

  Future<void> setScriptingWish(String wish) async {
    scriptingWish = wish;
    await StorageService.settings.put('scriptingWish', wish);
    notifyListeners();
  }

  Future<void> deleteJournalEntry(String id) async {
    journalEntries.removeWhere((e) => e.id == id);
    await StorageService.journal.delete(id);
    notifyListeners();
  }

  // ---------------- Vision Board ----------------
  Future<void> addVisionItem({
    String? imagePath,
    String caption = '',
    bool isAssetImage = false,
  }) async {
    final item = VisionItem(
      id: _uuid.v4(),
      imagePath: imagePath,
      caption: caption,
      isAssetImage: isAssetImage,
    );
    visionItems.insert(0, item);
    await StorageService.vision.put(item.id, item.toMap());
    notifyListeners();
  }

  Future<void> deleteVisionItem(String id) async {
    visionItems.removeWhere((v) => v.id == id);
    await StorageService.vision.delete(id);
    notifyListeners();
  }

  // ---------------- Universe Letter ----------------
  Future<void> addLetter({
    required String content,
    required DateTime openDate,
  }) async {
    final letter = UniverseLetter(
      id: _uuid.v4(),
      content: content,
      openDate: openDate,
    );
    letters.insert(0, letter);
    await StorageService.letters.put(letter.id, letter.toMap());
    await NotificationService.scheduleUniverseReply(
      id: _letterNotifId(letter.id),
      dateTime: openDate,
    );
    notifyListeners();
  }

  Future<void> markLetterRead(String id) async {
    final letter = letters.firstWhere((l) => l.id == id);
    letter.isRead = true;
    await StorageService.letters.put(letter.id, letter.toMap());
    notifyListeners();
  }

  Future<void> deleteLetter(String id) async {
    letters.removeWhere((l) => l.id == id);
    await StorageService.letters.delete(id);
    await NotificationService.cancelOneOff(_letterNotifId(id));
    notifyListeners();
  }

  /// 편지 id를 알림 스케줄용 고유 int id로 변환 (양수로 고정)
  int _letterNotifId(String letterId) =>
      20000 + (letterId.hashCode & 0x0FFFFFFF) % 70000;

  // ---------------- Notification Settings ----------------
  Future<void> setAffirmationNotif(bool enabled) async {
    affirmationNotifEnabled = enabled;
    await StorageService.settings.put('affirmationNotifEnabled', enabled);
    if (enabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyAffirmation();
    } else {
      await NotificationService.cancelAffirmation();
    }
    notifyListeners();
  }

  Future<void> setHabitNotif(bool enabled) async {
    habitNotifEnabled = enabled;
    await StorageService.settings.put('habitNotifEnabled', enabled);
    if (enabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleHabitReminder();
    } else {
      await NotificationService.cancelHabitReminder();
    }
    notifyListeners();
  }

  // ---------------- Moon Ritual ----------------
  Future<void> setMoonRitualNotif(bool enabled) async {
    moonRitualNotifEnabled = enabled;
    await StorageService.settings.put('moonRitualNotifEnabled', enabled);
    if (enabled) {
      await NotificationService.requestPermission();
      await _rescheduleMoonRitual();
    } else {
      await NotificationService.cancelOneOff(2001);
    }
    notifyListeners();
  }

  Future<void> _rescheduleMoonRitual() async {
    final info = MoonPhaseService.getInfo();
    final target = info.nextNewMoon.isBefore(info.nextFullMoon)
        ? info.nextNewMoon
        : info.nextFullMoon;
    final isNew = info.nextNewMoon.isBefore(info.nextFullMoon);
    await NotificationService.scheduleOneOff(
      id: 2001,
      title: isNew ? '🌑 오늘은 신월이에요' : '🌕 오늘은 보름이에요',
      body: isNew
          ? '새로운 소망을 심는 강력한 시간이에요. 새 목표를 세워보세요.'
          : '감사하고 놓아줄 시간이에요. 오늘의 저널을 남겨보세요.',
      dateTime: target,
    );
  }

  MoonPhaseInfo get moonPhaseInfo => MoonPhaseService.getInfo();

  // ---------------- Identity Level (누적 포인트, 절대 감소하지 않음) ----------------
  int get totalPoints {
    final journalPts = journalEntries.length * 5;
    final habitPts =
        habits.fold<int>(0, (sum, h) => sum + h.completedDates.length) * 3;
    final goalPts = goals.fold<int>(
      0,
      (sum, g) => sum + (g.progress * 100).round(),
    );
    return journalPts + habitPts + goalPts;
  }

  IdentityLevel get identityLevel => IdentityLevelX.fromPoints(totalPoints);

  // ---------------- AI / Derived ----------------
  int get energyScore => AiInsightService.energyScore(
    goals: goals,
    habits: habits,
    journalEntries: journalEntries,
  );

  AiInsight get todaysInsight => AiInsightService.generate(
    goals: goals,
    habits: habits,
    journalEntries: journalEntries,
  );

  GoalCategory? get primaryFocus =>
      focusAreas.isNotEmpty ? focusAreas.first : null;

  // ---------------- 프리미엄 / 무료 한도 ----------------
  bool get isPremium => EntitlementService.isPremium;

  /// 결제 SDK 연동 후, 구매 성공 콜백에서 호출해 상태를 갱신하는 용도.
  Future<void> setPremiumStatus(bool value) async {
    await EntitlementService.setPremium(value);
    notifyListeners();
  }

  bool get canAddGoal => isPremium || goals.length < FreeLimits.maxGoals;
  bool get canAddHabit => isPremium || habits.length < FreeLimits.maxHabits;
  bool get canAddVisionItem =>
      isPremium || visionItems.length < FreeLimits.maxVisionItems;

  int get lettersThisMonth {
    final now = DateTime.now();
    return letters
        .where(
          (l) => l.createdAt.year == now.year && l.createdAt.month == now.month,
        )
        .length;
  }

  bool get canWriteLetterThisMonth =>
      isPremium || lettersThisMonth < FreeLimits.maxLettersPerMonth;
}
