import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/universe_letter.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/entitlement_service.dart';
import '../../widgets/free_limit_banner.dart';
import '../premium/paywall_screen.dart';

class UniverseLetterScreen extends StatelessWidget {
  const UniverseLetterScreen({super.key});

  void _handleWriteLetter(BuildContext context) {
    final state = context.read<AppState>();
    if (!state.canWriteLetterThisMonth) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            triggerReason: '무료 플랜은 우주편지를 한 달에 1개까지 쓸 수 있어요.\n프리미엄으로 원하는 만큼 편지를 남겨보세요.',
          ),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _WriteLetterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('우주에 편지쓰기')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () => _handleWriteLetter(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!state.isPremium)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: FreeLimitBanner(
                  text: '이번 달 편지 ${state.lettersThisMonth}/${FreeLimits.maxLettersPerMonth}개 · 프리미엄으로 무제한 작성하기',
                  onTap: () => _handleWriteLetter(context),
                ),
              ),
            Expanded(
              child: state.letters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('✉️', style: TextStyle(fontSize: 44)),
                            SizedBox(height: 14),
                            Text('아직 보낸 편지가 없어요', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 6),
                            Text(
                              '이미 이루어진 미래의 나에게\n또는 우주에게 편지를 써보세요.\n정해진 날짜가 되면 열어볼 수 있어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: state.letters.length,
                      itemBuilder: (context, i) {
                        final l = state.letters[i];
                        return _LetterCard(letter: l);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final UniverseLetter letter;
  const _LetterCard({required this.letter});

  @override
  Widget build(BuildContext context) {
    final unlocked = letter.isUnlocked;
    return GestureDetector(
      onTap: unlocked
          ? () {
              context.read<AppState>().markLetterRead(letter.id);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('${letter.createdAt.year}.${letter.createdAt.month}.${letter.createdAt.day}의 편지'),
                  content: SingleChildScrollView(child: Text(letter.content, style: const TextStyle(height: 1.5))),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기'))],
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.surface : AppColors.beige.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(unlocked ? Icons.mark_email_read_outlined : Icons.lock_clock, color: AppColors.navy),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? (letter.isRead ? '읽은 편지' : '지금 열어볼 수 있어요!') : '열람 가능일',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${letter.openDate.year}.${letter.openDate.month.toString().padLeft(2, '0')}.${letter.openDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!unlocked) const Icon(Icons.hourglass_bottom, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _WriteLetterScreen extends StatefulWidget {
  const _WriteLetterScreen();

  @override
  State<_WriteLetterScreen> createState() => _WriteLetterScreenState();
}

class _WriteLetterScreenState extends State<_WriteLetterScreen> {
  final _controller = TextEditingController();
  int _daysAhead = 30;

  static const List<int> _presets = [7, 30, 90, 365];

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    await context.read<AppState>().addLetter(
          content: _controller.text.trim(),
          openDate: DateTime.now().add(Duration(days: _daysAhead)),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('편지 쓰기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.beige.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  '이미 원하는 것을 이룬 미래의 나의 시점에서,\n지금의 나에게 또는 우주에게 편지를 써보세요.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              const Text('언제 열어볼까요?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _presets.map((d) {
                  final selected = _daysAhead == d;
                  return GestureDetector(
                    onTap: () => setState(() => _daysAhead = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.navy : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.navy : Colors.black12),
                      ),
                      child: Text(
                        d < 60 ? '$d일 후' : d < 365 ? '${d ~/ 30}개월 후' : '1년 후',
                        style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('편지 내용', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 10,
                decoration: const InputDecoration(hintText: '지금 이 순간, 이미 이루어진 것처럼 적어보세요...'),
              ),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('편지 봉인하기'))),
            ],
          ),
        ),
      ),
    );
  }
}
