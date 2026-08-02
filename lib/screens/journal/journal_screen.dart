import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/journal_entry.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'add_journal_entry_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  JournalType? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = _filter == null
        ? state.journalEntries
        : state.journalEntries.where((e) => e.type == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('저널')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddJournalEntryScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _chip('전체', null),
                  ...JournalType.values.map((t) => _chip(t.label, t)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('📝', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text('아직 기록이 없어요', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 6),
                            Text('오늘의 감사한 일이나 감정을 적어보세요', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return Dismissible(
                          key: ValueKey(e.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => context.read<AppState>().deleteJournalEntry(e.id),
                          background: Container(
                            decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(8)),
                                        child: Text(e.type.label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                                      ),
                                      const Spacer(),
                                      Text(_moodEmoji(e.moodScore), style: const TextStyle(fontSize: 15)),
                                      const SizedBox(width: 6),
                                      Text('${e.createdAt.month}.${e.createdAt.day}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(e.content, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, JournalType? type) {
    final selected = _filter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.navy : Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 12.5, color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  String _moodEmoji(int score) {
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
