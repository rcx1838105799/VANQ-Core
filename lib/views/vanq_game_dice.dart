import 'package:fl_clash/common/common.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Dice game: guess big/small, win points.
///
/// Lightweight, anime style. Win: +8 points, lose: nothing.
class VanqDiceGameView extends ConsumerStatefulWidget {
  const VanqDiceGameView({super.key});

  @override
  ConsumerState<VanqDiceGameView> createState() => _VanqDiceGameViewState();
}

class _VanqDiceGameViewState extends ConsumerState<VanqDiceGameView> {
  final _random = Random();
  int _dice1 = 1;
  int _dice2 = 1;
  String? _result;
  bool _rolling = false;

  int get _total => _dice1 + _dice2;

  Future<void> _guess(bool guessBig) async {
    if (_rolling) return;
    setState(() {
      _rolling = true;
      _result = null;
    });
    // Rolling animation.
    for (var i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        _dice1 = _random.nextInt(6) + 1;
        _dice2 = _random.nextInt(6) + 1;
      });
    }
    final isBig = _total >= 7;
    final win = isBig == guessBig;
    var result = win ? '🎉 猜对了！' : '😅 猜错了，再试一次';
    if (win) {
      final awarded = await ref
          .read(vanqGameProvider.notifier)
          .playGame('dice', 8);
      if (awarded < 0) {
        result = '今日次数已用完，明天再来';
      } else if (awarded > 0) {
        result = '🎉 猜对了！+$awarded 积分';
      } else {
        result = '🎉 猜对了！今日积分已达上限';
      }
    }
    if (!mounted) return;
    setState(() {
      _rolling = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('dice') <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('掷骰子')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DiceFace(value: _dice1),
                const SizedBox(width: 24),
                _DiceFace(value: _dice2),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '点数：$_total',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: _rolling || outOfPlays
                      ? null
                      : () => _guess(false),
                  child: const Text('小 (2-6)'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _rolling || outOfPlays ? null : () => _guess(true),
                  child: const Text('大 (7-12)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              outOfPlays ? '今日次数已用完，明天再来' : '猜对 +8 积分，猜错不扣分',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  final int value;

  const _DiceFace({required this.value});

  @override
  Widget build(BuildContext context) {
    const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return Container(
      width: 80,
      height: 80,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: AppShape.all(AppCorner.md),
      ),
      child: Center(
        child: Text(
          faces[value - 1],
          style: const TextStyle(fontSize: 48, color: Colors.white),
        ),
      ),
    );
  }
}
