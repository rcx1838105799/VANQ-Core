import 'package:fl_clash/common/common.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Memory matching: 4x4, 8 pairs. Each match: +2, clear board: +20.
/// One board counts as one daily play.
class VanqMemoryGameView extends ConsumerStatefulWidget {
  const VanqMemoryGameView({super.key});

  @override
  ConsumerState<VanqMemoryGameView> createState() => _VanqMemoryGameViewState();
}

class _VanqMemoryGameViewState extends ConsumerState<VanqMemoryGameView> {
  final _random = Random();
  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _first;
  bool _busy = false;
  bool _started = false;
  int _matches = 0;
  int _sessionAwarded = 0;
  String? _result;

  static const _faces = ['🌸', '🦊', '⭐', '🌙', '🎀', '🍓', '🐱', '💎'];

  void _start() async {
    final ok = await ref.read(vanqGameProvider.notifier).recordPlay('memory');
    if (!mounted) return;
    if (!ok) {
      setState(() => _result = '今日次数已用完，明天再来');
      return;
    }
    final deck = [..._faces, ..._faces]..shuffle(_random);
    setState(() {
      _cards = deck;
      _flipped = List.filled(16, false);
      _matched = List.filled(16, false);
      _first = null;
      _busy = false;
      _started = true;
      _matches = 0;
      _sessionAwarded = 0;
      _result = null;
    });
  }

  Future<void> _award(int amount) async {
    final awarded = await ref
        .read(vanqGameProvider.notifier)
        .awardGamePoints(amount);
    _sessionAwarded += awarded;
  }

  Future<void> _flip(int index) async {
    if (!_started || _busy || _flipped[index] || _matched[index]) return;
    setState(() {
      _flipped[index] = true;
    });
    if (_first == null) {
      _first = index;
      return;
    }
    final first = _first!;
    _first = null;
    if (_cards[first] == _cards[index]) {
      await _award(2);
      if (!mounted) return;
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
        _matches++;
      });
      if (_matches == 8) {
        await _award(20);
        if (!mounted) return;
        setState(() {
          _started = false;
          _result = '🎉 通关！本局共得 $_sessionAwarded 积分';
        });
      }
      return;
    }
    _busy = true;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _flipped[first] = false;
      _flipped[index] = false;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('memory') <= 0;
    final remaining = game?.remainingPlays('memory') ?? 20;
    return Scaffold(
      appBar: AppBar(title: const Text('记忆翻牌')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_result != null) ...[
              Text(_result!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 16,
                itemBuilder: (context, i) {
                  final faceUp = _started && (_flipped[i] || _matched[i]);
                  return GestureDetector(
                    onTap: () => _flip(i),
                    child: Container(
                      decoration: ShapeDecoration(
                        color: faceUp ? Colors.white : const Color(0xFF6C5CE7),
                        shape: AppShape.all(AppCorner.md),
                      ),
                      child: Center(
                        child: Text(
                          faceUp && i < _cards.length ? _cards[i] : '❔',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _started || outOfPlays ? null : _start,
              child: Text(_started ? '进行中…' : '开始游戏'),
            ),
            const SizedBox(height: 8),
            Text(
              outOfPlays ? '今日次数已用完，明天再来' : '翻对 +2，通关 +20，今日剩余 $remaining 次',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
