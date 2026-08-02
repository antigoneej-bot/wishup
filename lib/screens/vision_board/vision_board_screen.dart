import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vision_item.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/entitlement_service.dart';
import '../../widgets/free_limit_banner.dart';
import '../premium/paywall_screen.dart';

class VisionBoardScreen extends StatelessWidget {
  const VisionBoardScreen({super.key});

  void _handleAddPressed(BuildContext context) {
    final state = context.read<AppState>();
    if (!state.canAddVisionItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            triggerReason: '무료 플랜은 비전보드 카드를 최대 5개까지 만들 수 있어요.\n프리미엄으로 제한 없이 채워보세요.',
          ),
        ),
      );
      return;
    }
    _showAddSheet(context);
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.navy),
                title: const Text('이미지 추가'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppColors.gold),
                title: const Text('예시 이미지로 추가'),
                subtitle: const Text('풍요·건강·커리어·사랑 카테고리 이미지', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showExampleSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: AppColors.navy),
                title: const Text('텍스트 비전 카드 추가'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTextOnlyDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExampleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('예시 이미지 선택', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('원하는 카테고리를 눌러 비전보드에 추가해보세요', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: VisionExample.all.length,
                itemBuilder: (context, i) {
                  final ex = VisionExample.all[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<AppState>().addVisionItem(
                            imagePath: ex.assetPath,
                            caption: ex.caption,
                            isAssetImage: true,
                          );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(ex.assetPath, fit: BoxFit.cover),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                                ),
                              ),
                              child: Text(
                                '${ex.emoji} ${ex.category}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null && context.mounted) {
        await context.read<AppState>().addVisionItem(imagePath: file.path);
      }
    } catch (_) {
      if (context.mounted) {
        _showTextOnlyDialog(context);
      }
    }
  }

  void _showTextOnlyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('비전 카드 추가'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '이미 이루어진 것처럼 적어보세요')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<AppState>().addVisionItem(caption: controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('비전보드')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'vision_fab',
        backgroundColor: AppColors.navy,
        onPressed: () => _handleAddPressed(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!state.isPremium && state.visionItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FreeLimitBanner(
                  text: '비전보드 ${state.visionItems.length}/${FreeLimits.maxVisionItems}개 · 프리미엄으로 무제한 이용하기',
                  onTap: () => _handleAddPressed(context),
                ),
              ),
            Expanded(
              child: state.visionItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('🖼', style: TextStyle(fontSize: 44)),
                            SizedBox(height: 14),
                            Text('비전보드가 비어있어요', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 6),
                            Text('이미 이루어진 모습을 이미지나 글로 채워보세요', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: state.visionItems.length,
                itemBuilder: (context, i) {
                  final v = state.visionItems[i];
                  return GestureDetector(
                    onLongPress: () => context.read<AppState>().deleteVisionItem(v.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.beige,
                        borderRadius: BorderRadius.circular(16),
                        image: v.imagePath != null
                            ? DecorationImage(
                                image: v.isAssetImage
                                    ? AssetImage(v.imagePath!) as ImageProvider
                                    : FileImage(File(v.imagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.all(12),
                      alignment: v.imagePath == null ? Alignment.center : Alignment.bottomLeft,
                      child: v.caption.isEmpty
                          ? null
                          : Text(
                              v.caption,
                              textAlign: v.imagePath == null ? TextAlign.center : TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: v.imagePath != null ? Colors.white : AppColors.textPrimary,
                                shadows: v.imagePath != null ? [const Shadow(blurRadius: 6, color: Colors.black54)] : null,
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
}
