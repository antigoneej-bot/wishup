import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalCard({super.key, required this.goal, this.onTap});

  Color get _color => AppColors.categoryColors[goal.category.index % AppColors.categoryColors.length];

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(goal.category.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.beige,
                        valueColor: AlwaysStoppedAnimation<Color>(_color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, color: _color)),
            ],
          ),
        ),
      ),
    );
  }
}
