import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const HabitTile({super.key, required this.habit, required this.onToggle, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final done = habit.isDoneToday();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onToggle,
        onLongPress: onDelete,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? AppColors.success : Colors.transparent,
            border: Border.all(color: done ? AppColors.success : AppColors.textSecondary, width: 1.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: done ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        trailing: habit.streak > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 3),
                  Text('${habit.streak}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            : null,
      ),
    );
  }
}
