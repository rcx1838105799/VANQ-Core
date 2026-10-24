import 'package:fl_clash/common/common.dart';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Standard 2048 on a 4x4 board. Swipe or use arrow buttons.
/// End-of-game award: score/100, capped at 30.
class VanqGame2048View extends ConsumerStatefulWidget {
  const VanqGame2048View({super.key});

  @override
  ConsumerState<VanqGame2048View> createState() => _VanqGame2048ViewState();
}

enum _Dir { up, down, left, right }

class _VanqGame2048ViewState extends ConsumerState<VanqGame2048View> {
  final _random = Random();
  List<int> _board = List.filled(16, 0);
  int _score = 0;
  bool _started = false;
  bool _over = false;
  bool _won = false;
  bool _awarded = false;
  String? _result;

  void _start() async {
    final ok = await ref.read(vanqGameProvider.notifier).recordPlay('g2048');
    if (!mounted) return;
    if (!ok) {
      setState(() => _result = '今日次数已用完，明天再来');
      return;
    }
    setState(() {
      _board = List.filled(16, 0);
      _score = 0;
      _started = true;
      _over = false;
      _won = false;
      _awarded = false;
      _result = null;
    });
    _spawn();
    _spawn();
  }

  void _spawn() {
    final empty = [
      for (var i = 0; i < 16; i++)
        if (_board[i] == 0) i,
    ];
    if (empty.isEmpty) return;
    final cell = empty[_random.nextInt(empty.length)];
    setState(() => _board[cell] = _random.nextDouble() < 0.9 ? 2 : 4);
  }

  List<int> _slide(List<int> line) {
    final tiles = line.where((v) => v != 0).toList();
    final out = <int>[];
    var i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
        final merged = tiles[i] * 2;
        out.add(merged);
        _score += merged;
        if (merged == 2048) _won = true;
        i += 2;
      } else {
        out.add(tiles[i]);
        i++;
      }
    }
    while (out.length < 4) {
      out.add(0);
    }
    return out;
  }

  bool _listsEqual(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _move(_Dir dir) {
    if (!_started || _over) return;
    final before = List<int>.of(_board);
    final next = List<int>.of(_board);
    for (var k = 0; k < 4; k++) {
      List<int> line;
      if (dir == _Dir.left) {
        line = [for (var c = 0; c < 4; c++) _board[k * 4 + c]];
      } else if (dir == _Dir.right) {
        line = [for (var c = 3; c >= 0; c--) _board[k * 4 + c]];
      } else if (dir == _Dir.up) {
        line = [for (var r = 0; r < 4; r++) _board[r * 4 + k]];
      } else {
        line = [for (var r = 3; r >= 0; r--) _board[r * 4 + k]];
      }
      final moved = _slide(line);
      for (var c = 0; c < 4; c++) {
        if (dir == _Dir.left) {
          next[k * 4 + c] = moved[c];
        } else if (dir == _Dir.right) {
          next[k * 4 + 3 - c] = moved[c];
        } else if (dir == _Dir.up) {
          next[c * 4 + k] = moved[c];
        } else {
          next[(3 - c) * 4 + k] = moved[c];
        }
      }
    }
    if (_listsEqual(before, next)) return;
    setState(() => _board = next);
    _spawn();
    if (_won) {
      _endGame('🎉 合成 2048！');
    } else if (!_canMove()) {
      _endGame('游戏结束');
    }
  }

  bool _canMove() {
    if (_board.contains(0)) return true;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final v = _board[r * 4 + c];
        if (c < 3 && _board[r * 4 + c + 1] == v) return true;
        if (r < 3 && _board[(r + 1) * 4 + c] == v) return true;
      }
    }
    return false;
  }

  Future<void> _endGame(String prefix) async {
    if (_awarded) return;
    _awarded = true;
    final award = (_score ~/ 100).clamp(0, 30);
    final awarded = await ref
        .read(vanqGameProvider.notifier)
        .awardGamePoints(award);
    if (!mounted) return;
    setState(() {
      _over = true;
      _started = false;
      _result = awarded > 0
          ? '$prefix 分数 $_score，+$awarded 积分'
          : '$prefix 分数 $_score，今日积分已达上限';
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('g2048') <= 0;
    final remaining = game?.remainingPlays('g2048') ?? 20;
    return Scaffold(
      appBar: AppBar(title: const Text('2048')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '分数：$_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton(
                  onPressed: _started || outOfPlays ? null : _start,
                  child: Text(_started ? '进行中' : '开始游戏'),
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onPanEnd: (details) {
                  final v = details.velocity.pixelsPerSecond;
                  if (v.dx.abs() < 100 && v.dy.abs() < 100) return;
                  if (v.dx.abs() > v.dy.abs()) {
                    _move(v.dx > 0 ? _Dir.right : _Dir.left);
                  } else {
                    _move(v.dy > 0 ? _Dir.down : _Dir.up);
                  }
                },
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, i) {
                    final v = _board[i];
                    return Container(
                      decoration: ShapeDecoration(
                        color: v == 0 ? const Color(0xFF1E1E20) : _tileColor(v),
                        shape: AppShape.all(AppCorner.md),
                      ),
                      child: Center(
                        child: Text(
                          v == 0 ? '' : '$v',
                          style: TextStyle(
                            fontSize: v >= 1024 ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: '向左',
                  onPressed: _started ? () => _move(_Dir.left) : null,
                  icon: const Text('⬅️', style: TextStyle(fontSize: 24)),
                ),
                Column(
                  children: [
                    IconButton(
                      tooltip: '向上',
                      onPressed: _started ? () => _move(_Dir.up) : null,
                      icon: const Text('⬆️', style: TextStyle(fontSize: 24)),
                    ),
                    IconButton(
                      tooltip: '向下',
                      onPressed: _started ? () => _move(_Dir.down) : null,
                      icon: const Text('⬇️', style: TextStyle(fontSize: 24)),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: '向右',
                  onPressed: _started ? () => _move(_Dir.right) : null,
                  icon: const Text('➡️', style: TextStyle(fontSize: 24)),
                ),
              ],
            ),
            Text(
              outOfPlays
                  ? '今日次数已用完，明天再来'
                  : '滑动或点方向键合成，结算按分数/100 给分（上限 30），今日剩余 $remaining 次',
              style: context.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _tileColor(int v) {
    const colors = {
      2: 0xFF6C5CE7,
      4: 0xFF7C6CF0,
      8: 0xFFFD79A8,
      16: 0xFFE17055,
      32: 0xFFFDCB6E,
      64: 0xFF00B894,
      128: 0xFF0984E3,
      256: 0xFF6C5CE7,
      512: 0xFFD63031,
      1024: 0xFF2D3436,
      2048: 0xFFFFD700,
    };
    return Color(colors[v] ?? 0xFF636E72);
  }
}
