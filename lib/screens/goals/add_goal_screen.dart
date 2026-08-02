import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleController = TextEditingController();
  final _identityController = TextEditingController();
  GoalCategory _category = GoalCategory.growth;
  DateTime? _targetDate;

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    final state = context.read<AppState>();
    await state.addGoal(
      title: _titleController.text.trim(),
      identityStatement: _identityController.text.trim().isEmpty
          ? '나는 이 목표를 이루어가는 사람이다.'
          : _identityController.text.trim(),
      category: _category,
      targetDate: _targetDate,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('새로운 목표')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('무엇을 이루고 싶나요?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: '예: 원하는 회사로 이직하기'),
              ),
              const SizedBox(height: 24),

              const Text('카테고리', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GoalCategory.values.map((c) {
                  final selected = _category == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.navy : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.navy : Colors.black12),
                      ),
                      child: Text(
                        '${c.emoji} ${c.label}',
                        style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('정체성 선언문', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              const Text('"나는 ~한 사람이다" 형태로 적어보세요', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              TextField(
                controller: _identityController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: '예: 나는 매일 성장하며 원하는 커리어를 만들어가는 사람이다'),
              ),
              const SizedBox(height: 24),

              const Text('목표 날짜 (선택)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (d != null) setState(() => _targetDate = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_targetDate == null
                    ? '날짜 선택하기'
                    : '${_targetDate!.year}.${_targetDate!.month}.${_targetDate!.day}'),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text('목표 만들기')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
