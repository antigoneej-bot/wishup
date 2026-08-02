import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  final TextEditingController _nameController = TextEditingController();
  final Set<GoalCategory> _selectedAreas = {};

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    final state = context.read<AppState>();
    await state.completeOnboarding(
      name: _nameController.text.trim().isEmpty ? '나' : _nameController.text.trim(),
      areas: _selectedAreas.toList(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainNavigation()));
  }

  bool get _canProceed {
    if (_page == 1) return _nameController.text.trim().isNotEmpty;
    if (_page == 2) return _selectedAreas.isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcomePage(),
                  _namePage(),
                  _focusAreaPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(3, (i) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.navy : AppColors.beige,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _canProceed ? _next : null,
                    child: Text(_page == 2 ? '시작하기' : '다음'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: const Text('✦', style: TextStyle(fontSize: 34, color: Colors.white)),
          ),
          const SizedBox(height: 28),
          const Text('WishUp', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            '위시업은 확언을 반복하는 앱이 아니에요.\n당신의 감정, 습관, 무의식을 함께 바꿔\n실제 현실의 변화를 만드는\n끌어당김 실천 플랫폼입니다.',
            style: TextStyle(fontSize: 15.5, height: 1.6, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _bullet('🧠', '무의식을 재프로그래밍하는 확언 & 정체성 선언'),
          _bullet('🔁', '행동과학 기반 습관으로 목표를 증명'),
          _bullet('📊', '감정·행동 패턴을 분석하는 스마트 인사이트 제공'),
        ],
      ),
    );
  }

  Widget _bullet(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }

  Widget _namePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('어떻게 불러드리면 좋을까요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('앱에서 당신을 부를 이름이에요.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          TextField(
            controller: _nameController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '이름 또는 닉네임을 입력해주세요'),
          ),
        ],
      ),
    );
  }

  Widget _focusAreaPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('어떤 영역의 변화를\n가장 원하시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          const Text('여러 개 선택할 수 있어요.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: GoalCategory.values.map((c) {
              final selected = _selectedAreas.contains(c);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selectedAreas.remove(c) : _selectedAreas.add(c);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.navy : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? AppColors.navy : Colors.black12),
                  ),
                  child: Text(
                    '${c.emoji}  ${c.label}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
