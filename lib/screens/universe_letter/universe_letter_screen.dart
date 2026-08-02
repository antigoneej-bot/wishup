import 'package:audioplayers/audioplayers.dart';
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
                              '지금 원하는 소원이나 목표를 우주에 편지로 보내보세요.\n정해진 날이 되면 "우주의 답장"이 도착해요 💌',
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

class _LetterCard extends StatefulWidget {
  final UniverseLetter letter;
  const _LetterCard({required this.letter});

  @override
  State<_LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<_LetterCard> {
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _openLetter(BuildContext context) async {
    final letter = widget.letter;
    final justArrived = !letter.isRead;
    context.read<AppState>().markLetterRead(letter.id);

    if (justArrived) {
      try {
        await _player.play(AssetSource('audio/ding_dong.mp3'));
      } catch (_) {}
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${letter.createdAt.year}.${letter.createdAt.month}.${letter.createdAt.day}에 보낸 편지'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('나의 소원', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(letter.content, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💌 우주의 답장', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Text(letter.replyMessage, style: const TextStyle(height: 1.6, fontSize: 13.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;
    final unlocked = letter.isUnlocked;
    final justArrived = unlocked && !letter.isRead;
    return GestureDetector(
      onTap: unlocked ? () => _openLetter(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.surface : AppColors.beige.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: justArrived ? AppColors.gold.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.06),
            width: justArrived ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              justArrived ? Icons.mark_email_unread : (unlocked ? Icons.mark_email_read_outlined : Icons.lock_clock),
              color: justArrived ? AppColors.gold : AppColors.navy,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    justArrived ? '💌 우주의 답장이 도착했어요!' : (unlocked ? '읽은 편지' : '답장 도착 예정일'),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: justArrived ? AppColors.navy : null),
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
  int _daysAhead = 1;

  static const List<int> _presets = [1, 7, 30, 90, 365];

  String _presetLabel(int d) {
    if (d == 1) return '내일 (24시간 후)';
    if (d < 30) return '$d일 후';
    if (d < 365) return '${d ~/ 30}개월 후';
    return '1년 후';
  }

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
                  '지금 원하는 소원이나 목표를 이미 이루어진 것처럼 적어보세요.\n정해진 날이 되면 "우주의 답장" 💌이 도착해요 — 당신의 소원이 이루어졌다는 소식과 함께요.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              const Text('답장은 언제 도착할까요?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                        _presetLabel(d),
                        style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('소원 / 목표', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 10,
                decoration: const InputDecoration(hintText: '지금 이 순간, 이미 이루어진 것처럼 적어보세요...'),
              ),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('우주로 보내기 🚀'))),
            ],
          ),
        ),
      ),
    );
  }
}
