import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../models/ritual_audio.dart';
import '../../theme/app_theme.dart';

/// 리츄얼 오디오(시각화/명상) 전체화면 플레이어
class RitualPlayerScreen extends StatefulWidget {
  final RitualAudio ritual;
  const RitualPlayerScreen({super.key, required this.ritual});

  @override
  State<RitualPlayerScreen> createState() => _RitualPlayerScreenState();
}

class _RitualPlayerScreenState extends State<RitualPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    try {
      await _player.setSource(AssetSource(widget.ritual.assetPath));
    } catch (_) {
      // 로드 실패 시에도 UI는 정상 표시
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> _rewind() async {
    final target = _position - const Duration(seconds: 10);
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> _forward() async {
    final target = _position + const Duration(seconds: 10);
    await _player.seek(target > _duration ? _duration : target);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ritual = widget.ritual;
    final maxMs = _duration.inMilliseconds.toDouble();
    final curMs = _position.inMilliseconds.toDouble();

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(ritual.title, style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(ritual.emoji, style: const TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 32),
              Text(ritual.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                ritual.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 44),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs > 0 ? maxMs : 1,
                    value: curMs.clamp(0, maxMs > 0 ? maxMs : 1),
                    onChanged: (v) async {
                      await _player.seek(Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(_position), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      Text(_fmt(_duration), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _rewind,
                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.navy, size: 36),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: _forward,
                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
              Text(
                '🎧 이어폰 착용을 권장해요 · 조용한 공간에서 눈을 감고 들어보세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
