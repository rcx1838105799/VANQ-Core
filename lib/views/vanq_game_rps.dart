import 'package:fl_clash/common/common.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Rock-paper-scissors vs AI. Win: +8 points.
class VanqRpsGameView extends ConsumerStatefulWidget {
  const VanqRpsGameView({super.key});

  @override
  ConsumerState<VanqRpsGameView> createState() => _VanqRpsGameViewState();
}

class _VanqRpsGameViewState extends ConsumerState<VanqRpsGameView> {
  final _random = Random();
  String _ai = '❔';
  String? _result;
  bool _playing = false;

  static const _hands = ['✊', '✌️', '🖐️'];

  Future<void> _play(int mine) async {
    if (_playing) return;
    setState(() {
      _playing = true;
      _result = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final ai = _random.nextInt(3);
    final diff = (mine - ai + 3) % 3;
    final win = diff == 1;
    final draw = diff == 0;
    var result = draw
        ? '平局，再来一次'
        : win
        ? '🎉 你赢了！'
        : '😅 你输了';
    if (win) {
      final awarded = await ref
          .read(vanqGameProvider.notifier)
          .playGame('rps', 8);
      if (awarded < 0) {
        result = '今日次数已用完，明天再来';
      } else if (awarded > 0) {
        result = '🎉 你赢了！+$awarded 积分';
      } else {
        result = '🎉 你赢了！今日积分已达上限';
      }
    } else {
      await ref.read(vanqGameProvider.notifier).recordPlay('rps');
    }
    if (!mounted) return;
    setState(() {
      _playing = false;
      _ai = _hands[ai];
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('rps') <= 0;
    final remaining = game?.remainingPlays('rps') ?? 20;
    return Scaffold(
      appBar: AppBar(title: const Text('猜拳')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('AI 出了', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(_ai, style: const TextStyle(fontSize: 72)),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  FilledButton(
                    onPressed: _playing || outOfPlays ? null : () => _play(i),
                    child: Text(
                      _hands[i],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              outOfPlays ? '今日次数已用完，明天再来' : '赢 +8 积分，今日剩余 $remaining 次',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
