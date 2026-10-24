import 'package:fl_clash/common/common.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Simplified Dou Dizhu: player + 2 AI robots.
/// Call landlord, play rounds, first empty hand wins. Win: +20.
class VanqDdzGameView extends ConsumerStatefulWidget {
  const VanqDdzGameView({super.key});

  @override
  ConsumerState<VanqDdzGameView> createState() => _VanqDdzGameViewState();
}

class _Card {
  final int value;
  final int suit;

  const _Card(this.value, this.suit);

  String get label {
    const ranks = {
      3: '3',
      4: '4',
      5: '5',
      6: '6',
      7: '7',
      8: '8',
      9: '9',
      10: '10',
      11: 'J',
      12: 'Q',
      13: 'K',
      14: 'A',
      15: '2',
      16: '小王',
      17: '大王',
    };
    const suits = ['♠', '♥', '♣', '♦'];
    if (value >= 16) return ranks[value]!;
    return '${ranks[value]}${suits[suit]}';
  }

  bool get red => suit == 1 || suit == 2;
}

class _Combo {
  final String type;
  final int key;
  final int length;

  const _Combo(this.type, this.key, this.length);
}

_Combo? _analyze(List<_Card> cards) {
  if (cards.isEmpty) return null;
  final sorted = [...cards]..sort((a, b) => a.value.compareTo(b.value));
  final counts = <int, int>{};
  for (final card in sorted) {
    counts[card.value] = (counts[card.value] ?? 0) + 1;
  }
  final values = counts.keys.toList()..sort();
  final n = sorted.length;
  if (n == 1) return _Combo('single', sorted[0].value, 1);
  if (n == 2) {
    if (sorted[0].value == 16 && sorted[1].value == 17) {
      return const _Combo('rocket', 100, 2);
    }
    if (values.length == 1) return _Combo('pair', values[0], 2);
    return null;
  }
  if (n == 3 && values.length == 1) return _Combo('trio', values[0], 3);
  if (n == 4) {
    if (values.length == 1) return _Combo('bomb', values[0], 4);
    if (values.length == 2 && counts.containsValue(3)) {
      final trio = counts.entries.firstWhere((e) => e.value == 3).key;
      return _Combo('trio1', trio, 4);
    }
    return null;
  }
  if (n == 5) {
    if (values.length == 2 && counts.containsValue(3)) {
      final trio = counts.entries.firstWhere((e) => e.value == 3).key;
      return _Combo('trio2', trio, 5);
    }
  }
  final distinct = values.length == n;
  final consecutive =
      distinct && values.last - values.first == n - 1 && values.last <= 14;
  if (consecutive && n >= 5) return _Combo('straight', values.first, n);
  if (n >= 6 &&
      n.isEven &&
      counts.values.every((c) => c == 2) &&
      values.last - values.first == n ~/ 2 - 1 &&
      values.last <= 14) {
    return _Combo('pairStraight', values.first, n);
  }
  return null;
}

bool _beats(_Combo play, _Combo? last) {
  if (last == null) return true;
  if (play.type == 'rocket') return true;
  if (last.type == 'rocket') return false;
  if (play.type == 'bomb') return last.type != 'bomb' || play.key > last.key;
  if (last.type == 'bomb') return false;
  return play.type == last.type &&
      play.length == last.length &&
      play.key > last.key;
}

class _VanqDdzGameViewState extends ConsumerState<VanqDdzGameView> {
  final _random = Random();
  List<_Card> _hand = [];
  List<_Card> _ai1 = [];
  List<_Card> _ai2 = [];
  List<_Card> _bottom = [];
  List<int> _selected = [];
  int _landlord = -1;
  int _turn = 0;
  List<_Card> _lastCards = [];
  _Combo? _lastCombo;
  int _lastPlayer = -1;
  int _passCount = 0;
  bool _calling = false;
  bool _playing = false;
  bool _over = false;
  bool _aiThinking = false;
  String? _result;
  String _ai1Play = '';
  String _ai2Play = '';

  void _deal() async {
    final ok = await ref.read(vanqGameProvider.notifier).recordPlay('ddz');
    if (!mounted) return;
    if (!ok) {
      setState(() => _result = '今日次数已用完，明天再来');
      return;
    }
    final deck = <_Card>[];
    for (var value = 3; value <= 15; value++) {
      for (var suit = 0; suit < 4; suit++) {
        deck.add(_Card(value, suit));
      }
    }
    deck.add(const _Card(16, -1));
    deck.add(const _Card(17, -1));
    deck.shuffle(_random);
    setState(() {
      _bottom = deck.sublist(51);
      _hand = deck.sublist(0, 17)..sort((a, b) => a.value.compareTo(b.value));
      _ai1 = deck.sublist(17, 34);
      _ai2 = deck.sublist(34, 51);
      _selected = [];
      _landlord = -1;
      _turn = 0;
      _lastCards = [];
      _lastCombo = null;
      _lastPlayer = -1;
      _passCount = 0;
      _calling = true;
      _playing = false;
      _over = false;
      _aiThinking = false;
      _result = null;
      _ai1Play = '';
      _ai2Play = '';
    });
  }

  void _call(bool call) {
    if (call) {
      setState(() {
        _landlord = 0;
        _hand.addAll(_bottom);
        _hand.sort((a, b) => a.value.compareTo(b.value));
        _calling = false;
        _playing = true;
        _turn = 0;
      });
    } else {
      final ai = _random.nextBool() ? 1 : 2;
      setState(() {
        _landlord = ai;
        if (ai == 1) {
          _ai1.addAll(_bottom);
        } else {
          _ai2.addAll(_bottom);
        }
        _calling = false;
        _playing = true;
        _turn = ai;
      });
      _aiTurn();
    }
  }

  Map<int, List<_Card>> _group(List<_Card> hand) {
    final map = <int, List<_Card>>{};
    for (final card in hand) {
      (map[card.value] ??= []).add(card);
    }
    return map;
  }

  List<_Card>? _aiFind(List<_Card> hand, _Combo? last) {
    final groups = _group(hand);
    final values = groups.keys.toList()..sort();
    if (last == null) {
      for (final value in values) {
        return groups[value]!.sublist(0, 1);
      }
      return null;
    }
    if (last.type == 'rocket') return null;
    if (last.type == 'single') {
      for (final value in values) {
        if (value > last.key) return groups[value]!.sublist(0, 1);
      }
    }
    if (last.type == 'pair') {
      for (final value in values) {
        if (value > last.key && groups[value]!.length >= 2) {
          return groups[value]!.sublist(0, 2);
        }
      }
    }
    if (last.type == 'trio' || last.type == 'trio1' || last.type == 'trio2') {
      for (final value in values) {
        if (value > last.key && groups[value]!.length >= 3) {
          final trio = groups[value]!.sublist(0, 3);
          if (last.type == 'trio') return trio;
          final rest = hand.where((c) => c.value != value).toList();
          if (last.type == 'trio1' && rest.isNotEmpty) {
            return [...trio, rest.first];
          }
          if (last.type == 'trio2') {
            for (final entry in groups.entries) {
              if (entry.key != value && entry.value.length >= 2) {
                return [...trio, ...entry.value.sublist(0, 2)];
              }
            }
          }
        }
      }
    }
    if (last.type == 'straight') {
      for (var start = last.key + 1; start + last.length - 1 <= 14; start++) {
        var ok = true;
        final cards = <_Card>[];
        for (var v = start; v < start + last.length; v++) {
          if ((groups[v]?.length ?? 0) < 1) {
            ok = false;
            break;
          }
          cards.add(groups[v]!.first);
        }
        if (ok) return cards;
      }
    }
    if (last.type == 'bomb') {
      for (final value in values) {
        if (value > last.key && groups[value]!.length >= 4) {
          return groups[value]!.sublist(0, 4);
        }
      }
      return null;
    }
    if (last.type != 'bomb') {
      for (final value in values) {
        if (groups[value]!.length >= 4) {
          return groups[value]!.sublist(0, 4);
        }
      }
      final jokers = hand.where((c) => c.value >= 16).toList();
      if (jokers.length == 2) return jokers;
    }
    return null;
  }

  Future<void> _aiTurn() async {
    if (_over || !_playing) return;
    setState(() => _aiThinking = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || _over || !_playing) return;
    final isAi1 = _turn == 1;
    final hand = isAi1 ? _ai1 : _ai2;
    final play = _aiFind(hand, _lastCombo);
    if (play == null) {
      setState(() {
        if (isAi1) {
          _ai1Play = '不出';
        } else {
          _ai2Play = '不出';
        }
        _passCount++;
      });
      _afterPlay(-1);
      return;
    }
    final combo = _analyze(play)!;
    for (final card in play) {
      hand.remove(card);
    }
    setState(() {
      _lastCards = play;
      _lastCombo = combo;
      _lastPlayer = _turn;
      _passCount = 0;
      if (isAi1) {
        _ai1Play = play.map((c) => c.label).join(' ');
      } else {
        _ai2Play = play.map((c) => c.label).join(' ');
      }
    });
    _afterPlay(_turn);
  }

  void _afterPlay(int player) {
    if (_hand.isEmpty || _ai1.isEmpty || _ai2.isEmpty) {
      _endGame();
      return;
    }
    if (_passCount >= 2) {
      setState(() {
        _lastCards = [];
        _lastCombo = null;
        _passCount = 0;
        _turn = _lastPlayer;
        _aiThinking = false;
      });
    } else {
      setState(() {
        _turn = (_turn + 1) % 3;
        _aiThinking = false;
      });
    }
    if (_turn != 0 && _playing && !_over) {
      _aiTurn();
    }
  }

  Future<void> _endGame() async {
    final playerWon = _hand.isEmpty;
    var result = playerWon ? '🎉 你赢了！' : '😅 机器人赢了';
    if (playerWon) {
      final awarded = await ref
          .read(vanqGameProvider.notifier)
          .awardGamePoints(20);
      if (awarded > 0) {
        result = '🎉 你赢了！+$awarded 积分';
      } else {
        result = '🎉 你赢了！今日积分已达上限';
      }
    }
    if (!mounted) return;
    setState(() {
      _over = true;
      _playing = false;
      _result = result;
    });
  }

  void _toggle(int index) {
    if (!_playing || _turn != 0 || _aiThinking) return;
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  void _playSelected() {
    if (_turn != 0 || _selected.isEmpty) return;
    final cards = _selected.map((i) => _hand[i]).toList();
    final combo = _analyze(cards);
    if (combo == null) {
      context.showSnackBar('这手牌不符合牌型');
      return;
    }
    if (!_beats(combo, _lastCombo)) {
      context.showSnackBar('管不上上家的牌');
      return;
    }
    final sorted = [..._selected]..sort((a, b) => b.compareTo(a));
    setState(() {
      for (final i in sorted) {
        _hand.removeAt(i);
      }
      _selected = [];
      _lastCards = cards;
      _lastCombo = combo;
      _lastPlayer = 0;
      _passCount = 0;
    });
    _afterPlay(0);
  }

  void _pass() {
    if (_turn != 0 || _lastCombo == null) return;
    setState(() => _passCount++);
    _afterPlay(-1);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('ddz') <= 0;
    final remaining = game?.remainingPlays('ddz') ?? 20;
    return Scaffold(
      appBar: AppBar(title: const Text('斗地主')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RobotRow(
              name: '机器人乙 ${_landlord == 2 ? '（地主）' : ''}',
              count: _ai2.length,
              play: _ai2Play,
            ),
            const SizedBox(height: 8),
            _RobotRow(
              name: '机器人甲 ${_landlord == 1 ? '（地主）' : ''}',
              count: _ai1.length,
              play: _ai1Play,
            ),
            const SizedBox(height: 16),
            if (_lastCards.isNotEmpty) ...[
              const Text('上家出牌', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  for (final card in _lastCards) _DdzCard(label: card.label),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_result != null) ...[
              Text(_result!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            if (_calling) ...[
              const Center(child: Text('是否叫地主？')),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => _call(true),
                    child: const Text('叫地主'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _call(false),
                    child: const Text('不叫'),
                  ),
                ],
              ),
            ] else if (_playing) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < _hand.length; i++)
                    GestureDetector(
                      onTap: () => _toggle(i),
                      child: _DdzCard(
                        label: _hand[i].label,
                        selected: _selected.contains(i),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed:
                        _turn == 0 && !_aiThinking && _selected.isNotEmpty
                        ? _playSelected
                        : null,
                    child: const Text('出牌'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _turn == 0 && !_aiThinking && _lastCombo != null
                        ? _pass
                        : null,
                    child: const Text('不出'),
                  ),
                ],
              ),
              if (_aiThinking)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: Text('机器人思考中…')),
                ),
            ] else ...[
              Center(
                child: FilledButton(
                  onPressed: outOfPlays ? null : _deal,
                  child: const Text('开始游戏'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Center(
              child: Text(
                outOfPlays ? '今日次数已用完，明天再来' : '赢 +20 积分，输不扣分，今日剩余 $remaining 次',
                style: context.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotRow extends StatelessWidget {
  final String name;
  final int count;
  final String play;

  const _RobotRow({
    required this.name,
    required this.count,
    required this.play,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$name：$count 张', style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            play,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DdzCard extends StatelessWidget {
  final String label;
  final bool selected;

  const _DdzCard({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final red = label.contains('♥') || label.contains('♦');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: ShapeDecoration(
        color: selected ? const Color(0xFF6C5CE7) : Colors.white,
        shape: AppShape.all(AppCorner.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: selected
              ? Colors.white
              : red
              ? Colors.red
              : Colors.black,
        ),
      ),
    );
  }
}
