import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../models/celebration.dart';
import '../theme/app_theme.dart';

/// 스트릭/목표 달성 축하 오버레이 (행동과학 - 도파민 루프 강화)
class CelebrationOverlay {
  static void show(BuildContext context, CelebrationType type) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'celebration',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => _CelebrationDialog(type: type),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }
}

class _CelebrationDialog extends StatefulWidget {
  final CelebrationType type;
  const _CelebrationDialog({required this.type});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 24,
            gravity: 0.25,
            colors: const [AppColors.navy, AppColors.gold, AppColors.success, AppColors.warning],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.type.emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                Text(widget.type.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  widget.type.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('계속하기', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
