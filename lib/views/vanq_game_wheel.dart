import 'package:fl_clash/common/common.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Lucky wheel: spin for random points (2-20).
///
/// Free spin with cooldown to prevent farming.
class VanqWheelGameView extends ConsumerStatefulWidget {
  const VanqWheelGameView({super.key});

  @override
  ConsumerState<VanqWheelGameView> createState() => _VanqWheelGameViewState();
}

class _VanqWheelGameViewState extends ConsumerState<VanqWheelGameView>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late final AnimationController _controller;
  double _angle = 0;
  String? _result;
  bool _spinning = false;
  DateTime? _lastSpin;

  static const _prizes = [2, 5, 8, 12, 15, 20];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.addListener(() {
      setState(() {
        _angle = _controller.value * 2 * pi * 5;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final now = DateTime.now();
    if (_lastSpin != null && now.difference(_lastSpin!).inSeconds < 10) {
      final wait = 10 - now.difference(_lastSpin!).inSeconds;
      if (mounted) context.showSnackBar('转太快了，$wait 秒后再来');
      return;
    }
    setState(() {
      _spinning = true;
      _result = null;
    });
    _controller.reset();
    await _controller.forward();
    if (!mounted) return;
    final prize = _prizes[_random.nextInt(_prizes.length)];
    final awarded = await ref
        .read(vanqGameProvider.notifier)
        .playGame('wheel', prize);
    String result;
    if (awarded < 0) {
      result = '今日次数已用完，明天再来';
    } else if (awarded > 0) {
      result = '🎉 恭喜获得 $awarded 积分！';
    } else {
      result = '今日积分已达上限';
    }
    setState(() {
      _spinning = false;
      _lastSpin = DateTime.now();
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('wheel') <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('幸运转盘')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: _angle,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    for (var i = 0; i < 6; i++)
                      Positioned.fill(
                        child: Transform.rotate(
                          angle: i * pi / 3,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                '${_prizes[i]}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Center(
                      child: Text('🎡', style: TextStyle(fontSize: 48)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('👆 指针', style: TextStyle(fontSize: 24)),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _spinning || outOfPlays ? null : _spin,
              child: Text(_spinning ? '转动中...' : '开始转动'),
            ),
            const SizedBox(height: 16),
            Text(
              outOfPlays ? '今日次数已用完，明天再来' : '每次转动随机获得 2-20 积分，10秒冷却，每日限 20 次',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
