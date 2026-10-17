import 'package:fl_clash/common/common.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Poker guess: guess red or black, win points.
///
/// Win: +8 points, lose: nothing.
class VanqPokerGameView extends ConsumerStatefulWidget {
  const VanqPokerGameView({super.key});

  @override
  ConsumerState<VanqPokerGameView> createState() => _VanqPokerGameViewState();
}

class _VanqPokerGameViewState extends ConsumerState<VanqPokerGameView> {
  final _random = Random();
  String _card = '🂠';
  bool _isRed = false;
  String? _result;
  bool _playing = false;

  static const _redCards = ['♥', '♦'];
  static const _blackCards = ['♠', '♣'];
  static const _ranks = [
    'A',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K',
  ];

  Future<void> _guess(bool guessRed) async {
    if (_playing) return;
    setState(() {
      _playing = true;
      _result = null;
      _card = '🂠';
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final isRed = _random.nextBool();
    final suit = isRed
        ? _redCards[_random.nextInt(2)]
        : _blackCards[_random.nextInt(2)];
    final rank = _ranks[_random.nextInt(_ranks.length)];
    final win = isRed == guessRed;
    if (win) {
      await ref.read(vanqGameProvider.notifier).addPoints(8);
    }
    if (!mounted) return;
    setState(() {
      _playing = false;
      _isRed = isRed;
      _card = '$rank$suit';
      _result = win ? '🎉 猜对了！+8 积分' : '😅 猜错了，再试一次';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('猜扑克')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 168,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C5CE7), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _card,
                  style: TextStyle(
                    fontSize: _card == '🂠' ? 64 : 40,
                    color: _card == '🂠'
                        ? Colors.grey
                        : _isRed
                        ? Colors.red
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: _playing ? null : () => _guess(true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('♥ 红色'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _playing ? null : () => _guess(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                  ),
                  child: const Text('♠ 黑色'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('猜对 +8 积分，猜错不扣分', style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
