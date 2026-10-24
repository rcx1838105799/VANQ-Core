import 'package:fl_clash/common/common.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Slot machine: 3 reels. Three of a kind: +30, two: +5.
class VanqSlotsGameView extends ConsumerStatefulWidget {
  const VanqSlotsGameView({super.key});

  @override
  ConsumerState<VanqSlotsGameView> createState() => _VanqSlotsGameViewState();
}

class _VanqSlotsGameViewState extends ConsumerState<VanqSlotsGameView> {
  final _random = Random();
  final _reels = [0, 0, 0];
  bool _spinning = false;
  String? _result;

  static const _symbols = ['🍒', '🍋', '🍇', '⭐', '💎', '7️⃣'];

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _result = null;
    });
    for (var tick = 0; tick < 18; tick++) {
      await Future.delayed(Duration(milliseconds: 60 + tick * 8));
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < 3; i++) {
          if (tick < 6 + i * 6) {
            _reels[i] = _random.nextInt(_symbols.length);
          }
        }
      });
    }
    final a = _reels[0];
    final b = _reels[1];
    final c = _reels[2];
    final award = a == b && b == c ? 30 : (a == b || b == c || a == c ? 5 : 0);
    var result = award == 0 ? '没中，再来一次' : '';
    if (award > 0) {
      final awarded = await ref
          .read(vanqGameProvider.notifier)
          .playGame('slots', award);
      if (awarded < 0) {
        result = '今日次数已用完，明天再来';
      } else if (awarded > 0) {
        result = '🎉 中了！+$awarded 积分';
      } else {
        result = '🎉 中了！今日积分已达上限';
      }
    } else {
      await ref.read(vanqGameProvider.notifier).recordPlay('slots');
    }
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('slots') <= 0;
    final remaining = game?.remainingPlays('slots') ?? 20;
    return Scaffold(
      appBar: AppBar(title: const Text('老虎机')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: ShapeDecoration(
                color: const Color(0xFF141416),
                shape: AppShape.all(AppCorner.lg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Text(
                      _symbols[_reels[i]],
                      style: const TextStyle(fontSize: 56),
                    ),
                    if (i < 2) const SizedBox(width: 16),
                  ],
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _spinning || outOfPlays ? null : _spin,
              child: Text(_spinning ? '转动中...' : '拉杆！'),
            ),
            const SizedBox(height: 16),
            Text(
              outOfPlays ? '今日次数已用完，明天再来' : '三连 +30，两连 +5，今日剩余 $remaining 次',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
