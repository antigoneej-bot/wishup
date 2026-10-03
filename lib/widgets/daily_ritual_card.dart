import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../providers/app_state.dart';
import '../services/affirmation_service.dart';
import '../screens/journal/add_journal_entry_screen.dart';
import '../theme/app_theme.dart';

class DailyRitualCard extends StatefulWidget {
  const DailyRitualCard({super.key});
  @override
  State<DailyRitualCard> createState() => _DailyRitualCardState();
}

class _DailyRitualCardState extends State<DailyRitualCard>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false;
  String? _date;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshDay());
  }

  void _refreshDay() {
    if (mounted && _date != context.read<AppState>().ritualDate) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장하지 못했어요. 날짜가 바뀌었다면 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _plan() async {
    final state = context.read<AppState>();
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: _ActionDialog(date: state.ritualDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final date = state.ritualDate;
    _date = date;
    final count = state.ritualCompletedSteps;
    final read = state.ritualAffirmationRead;
    final planned = state.ritualActionTitle.isNotEmpty;
    final done = state.ritualActionDone;
    final goal = state.goals.where((goal) => goal.id == state.ritualGoalId);
    final String title;
    final String body;
    final String button;
    final Future<void> Function() action;
    if (!read) {
      title = '1. 오늘의 마음 정하기';
      body =
          '“${AffirmationService.dailyAffirmation(preferredCategory: state.primaryFocus)}”';
      button = '확언을 읽었어요';
      action = () => state.readRitualAffirmation(date);
    } else if (!planned) {
      title = '2. 작은 행동 하나 정하기';
      body = '오늘 할 수 있는 만큼만 정해요. 기존 목표나 습관과 연결할 수도 있어요.';
      button = '오늘의 행동 정하기';
      action = _plan;
    } else if (!done) {
      title = '2. 오늘의 작은 행동';
      body = state.ritualActionTitle;
      button = '이 행동을 했어요';
      action = () => state.completeRitualAction(date);
    } else if (!state.ritualJournalDone) {
      title = '3. 하루를 한 줄로 남기기';
      body = '오늘 한 일이나 감사한 순간을 적어봐요. 저녁에 돌아와 남겨도 괜찮아요.';
      button = '한 줄 기록하기';
      action = () async {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AddJournalEntryScreen(
              initialType: JournalType.gratitude,
              linkedGoalId: state.ritualGoalId,
            ),
          ),
        );
      };
    } else {
      title = '오늘의 리추얼을 마쳤어요';
      body = '작은 실천과 기록이 쌓이고 있어요. 내일도 나의 속도로 만나요.';
      button = '';
      action = () async {};
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 3분 리추얼',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '마음 정하기와 기록은 짧게 · 행동은 내 속도로  $count/3',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: count / 3,
            color: AppColors.gold,
            backgroundColor: Colors.white24,
            semanticsLabel: '오늘의 리추얼',
            semanticsValue: '3단계 중 $count단계 완료',
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (read && planned && goal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '연결 목표 · ${goal.first.title}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (button.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                ),
                onPressed: _busy ? null : () => _run(action),
                child: Text(_busy ? '잠시만요…' : button),
              ),
            ),
          ],
          if (read && planned && !done)
            TextButton(
              onPressed: _busy ? null : () => _run(_plan),
              child: const Text(
                '행동 바꾸기',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            '한 번에 다 하지 않아도 괜찮아요.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionDialog extends StatefulWidget {
  const _ActionDialog({required this.date});
  final String date;
  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  final _text = TextEditingController();
  String? _goalId;
  String? _habitId;
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _text.text = state.ritualActionTitle;
    _goalId = state.ritualGoalId;
    _habitId = state.todayRitual['habitId'] as String?;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_text.text.trim().isEmpty) {
      setState(() => _error = '오늘 할 행동을 적어주세요.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AppState>().planRitualAction(
        widget.date,
        _text.text,
        goalId: _goalId,
        habitId: _habitId,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '저장하지 못했어요. 날짜와 선택한 목표를 확인하고 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.goals
        .where((goal) => !goal.isArchived || goal.id == _goalId)
        .toList();
    final habits = state.habits
        .where((habit) => _goalId == null || habit.linkedGoalId == _goalId)
        .toList();
    return AlertDialog(
      title: const Text('오늘의 작은 행동'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('목표가 없어도 시작할 수 있어요. 오늘 할 수 있는 행동 하나만 정해봐요.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: goals.any((goal) => goal.id == _goalId)
                  ? _goalId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '연결할 목표 (선택)'),
              items: [
                const DropdownMenuItem(value: '', child: Text('목표 없이 시작')),
                ...goals.map(
                  (goal) => DropdownMenuItem(
                    value: goal.id,
                    child: Text(goal.title, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (id) => setState(() {
                      _goalId = id == '' ? null : id;
                      _habitId = null;
                    }),
            ),
            if (habits.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '기존 습관에서 고르기',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: habits
                    .map(
                      (habit) => ChoiceChip(
                        label: Text(habit.title),
                        selected: _habitId == habit.id,
                        onSelected: _saving
                            ? null
                            : (selected) => setState(() {
                                _habitId = selected ? habit.id : null;
                                if (selected) {
                                  _text.text = habit.title;
                                }
                              }),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              enabled: !_saving,
              maxLength: 100,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '오늘 할 행동',
                hintText: '예: 이력서 한 항목 수정하기',
              ),
              onChanged: (_) => setState(() {
                _habitId = null;
                _error = null;
              }),
            ),
            if (_habitId != null) const Text('완료하면 선택한 습관에도 오늘의 실천이 체크돼요.'),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '저장 중…' : '행동 저장'),
        ),
      ],
    );
  }
}
