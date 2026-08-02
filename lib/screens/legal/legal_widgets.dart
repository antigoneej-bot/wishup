import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 개인정보처리방침 / 이용약관 화면에서 공통으로 쓰는 스타일 위젯 모음.
class LegalScaffold extends StatelessWidget {
  final String title;
  final String updatedAt;
  final List<Widget> children;

  const LegalScaffold({
    super.key,
    required this.title,
    required this.updatedAt,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              '최종 업데이트: $updatedAt',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class LegalHeading extends StatelessWidget {
  final String text;
  const LegalHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
    );
  }
}

class LegalBody extends StatelessWidget {
  final String text;
  const LegalBody(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.7, color: AppColors.textPrimary),
      ),
    );
  }
}

class LegalNote extends StatelessWidget {
  final String text;
  const LegalNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.beige.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
      ),
    );
  }
}
