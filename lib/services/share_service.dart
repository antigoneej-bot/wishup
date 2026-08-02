import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 확언 카드를 이미지로 캡처해 공유하는 서비스 (바이럴 성장 채널)
class ShareService {
  /// 오버레이에 오프스크린으로 위젯을 렌더링한 뒤 캡처하여 공유
  static Future<void> shareAsCard(BuildContext context, Widget card, {String? text}) async {
    if (kIsWeb) {
      // 웹에서는 이미지 캡처 대신 텍스트 공유로 대체
      try {
        await Share.share(text ?? 'WishUp에서 확인해보세요!');
      } catch (_) {}
      return;
    }

    final key = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -3000,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 340,
            child: RepaintBoundary(key: key, child: card),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 80));

    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        entry.remove();
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wishup_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (e) {
      if (kDebugMode) debugPrint('카드 공유 실패: $e');
    } finally {
      entry.remove();
    }
  }
}
