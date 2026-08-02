import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../providers/app_state.dart';
import '../../services/affirmation_service.dart';
import '../../services/share_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/affirmation_share_card.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  GoalCategory _category = GoalCategory.growth;

  @override
  void initState() {
    super.initState();
    final focus = context.read<AppState>().primaryFocus;
    if (focus != null) _category = focus;
  }

  @override
  Widget build(BuildContext context) {
    final list = AffirmationService.all(_category);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('확언 라이브러리')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: GoalCategory.values.map((c) {
                  final selected = _category == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.navy : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppColors.navy : Colors.black12),
                        ),
                        alignment: Alignment.center,
                        child: Text('${c.emoji} ${c.label}', style: TextStyle(fontSize: 12.5, color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                itemCount: list.length,
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('"${list[i]}"', style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => ShareService.shareAsCard(
                          context,
                          AffirmationShareCard(text: list[i]),
                          text: '오늘의 확언 · WishUp',
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.share_rounded, size: 18, color: AppColors.navy),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
