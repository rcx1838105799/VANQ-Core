import 'package:fl_clash/common/common.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Blackjack vs dealer AI. Win: +15, push: 0, lose: 0.
class VanqBlackjackGameView extends ConsumerStatefulWidget {
  const VanqBlackjackGameView({super.key});

  @override
  ConsumerState<VanqBlackjackGameView> createState() =>
      _VanqBlackjackGameViewState();
}

class _VanqBlackjackGameViewState extends ConsumerState<VanqBlackjackGameView> {
  final _random = Random();
  List<int> _deck = [];
  List<int> _player = [];
  List<int> _dealer = [];
  bool _inRound = false;
  bool _dealerHidden = true;
  String? _result;

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

  int _value(List<int> hand) {
    var total = 0;
    var aces = 0;
    for (final card in hand) {
      final rank = card % 13;
      if (rank == 0) {
        aces++;
        total += 11;
      } else if (rank >= 10) {
        total += 10;
      } else {
        total += rank + 1;
      }
    }
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }
    return total;
  }

  String _label(int card) {
    const suits = ['♠', '♥', '♣', '♦'];
    return '${_ranks[card % 13]}${suits[card ~/ 13]}';
  }

  void _deal() {
    _deck = List.generate(52, (i) => i)..shuffle(_random);
    setState(() {
      _player = [_deck.removeLast(), _deck.removeLast()];
      _dealer = [_deck.removeLast(), _deck.removeLast()];
      _inRound = true;
      _dealerHidden = true;
      _result = null;
    });
  }

  Future<void> _finish() async {
    setState(() => _dealerHidden = false);
    while (_value(_dealer) < 17) {
      _dealer.add(_deck.removeLast());
    }
    final pv = _value(_player);
    final dv = _value(_dealer);
    final win = (pv <= 21 && dv > 21) || (pv <= 21 && dv <= 21 && pv > dv);
    final push = pv <= 21 && dv <= 21 && pv == dv;
    var result = push
        ? '平局'
        : win
        ? '🎉 你赢了！'
        : '😅 庄家赢了';
    if (win) {
      final awarded = await ref
          .read(vanqGameProvider.notifier)
          .playGame('blackjack', 15);
      if (awarded < 0) {
        result = '今日次数已用完，明天再来';
      } else if (awarded > 0) {
        result = '🎉 你赢了！+$awarded 积分';
      } else {
        result = '🎉 你赢了！今日积分已达上限';
      }
    } else {
      await ref.read(vanqGameProvider.notifier).recordPlay('blackjack');
    }
    if (!mounted) return;
    setState(() {
      _inRound = false;
      _result = result;
    });
  }

  void _hit() {
    setState(() => _player.add(_deck.removeLast()));
    if (_value(_player) > 21) {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('blackjack') <= 0;
    final remaining = game?.remainingPlays('blackjack') ?? 20;
    return Scaffold(
      appBar: AppBar(title: const Text('21 点')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '庄家 ${_dealerHidden && _inRound ? '(一张暗牌)' : '(${_value(_dealer)} 点)'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < _dealer.length; i++)
                  _CardChip(
                    label: _dealerHidden && _inRound && i == 1
                        ? '🂠'
                        : _label(_dealer[i]),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '你 (${_player.isEmpty ? 0 : _value(_player)} 点)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final card in _player) _CardChip(label: _label(card)),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_inRound)
                  FilledButton(
                    onPressed: outOfPlays ? null : _deal,
                    child: const Text('发牌'),
                  )
                else ...[
                  FilledButton(onPressed: _hit, child: const Text('要牌')),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _finish, child: const Text('停牌')),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                outOfPlays ? '今日次数已用完，明天再来' : '赢 +15 积分，今日剩余 $remaining 次',
                style: context.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final String label;

  const _CardChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final red = label.contains('♥') || label.contains('♦');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: AppShape.all(AppCorner.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: red ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}
