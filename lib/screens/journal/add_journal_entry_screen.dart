import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/journal_entry.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final JournalType? initialType;
  final String? linkedGoalId;
  const AddJournalEntryScreen({super.key, this.initialType, this.linkedGoalId});

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  late JournalType _type;
  int _mood = 3;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? JournalType.gratitude;
  }

  String get _hint {
    switch (_type) {
      case JournalType.gratitude:
        return '오늘 감사했던 순간은 무엇인가요?';
      case JournalType.evidence:
        return '내 소망이 이루어지고 있다는 신호는 무엇이었나요?';
      case JournalType.script:
        return '이루고 싶은 목표를 지금 이루어진 것처럼 적어보세요 (369법)';
      case JournalType.moodOnly:
        return '지금 느끼는 감정을 자유롭게 적어보세요';
      case JournalType.release:
        return '더 이상 필요하지 않은 감정이나 생각은 무엇인가요? 인정하고 놓아주세요';
    }
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    await context.read<AppState>().addJournalEntry(
          type: _type,
          content: _controller.text.trim(),
          moodScore: _mood,
          linkedGoalId: widget.linkedGoalId,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('새 기록')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('종류', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: JournalType.values.where((t) => t != JournalType.script).map((t) {
                  final selected = _type == t;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.navy : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.navy : Colors.black12),
                      ),
                      child: Text(t.label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('지금 기분은 어떤가요?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final score = i + 1;
                  final selected = _mood == score;
                  return GestureDetector(
                    onTap: () => setState(() => _mood = score),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.navy.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppColors.navy : Colors.black12),
                      ),
                      alignment: Alignment.center,
                      child: Text(_emoji(score), style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              Text(_hint, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 6,
                decoration: const InputDecoration(hintText: '자유롭게 적어보세요...'),
              ),
              const SizedBox(height: 32),

              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('저장하기'))),
            ],
          ),
        ),
      ),
    );
  }

  String _emoji(int score) {
    switch (score) {
      case 1: return '😞';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }
}
