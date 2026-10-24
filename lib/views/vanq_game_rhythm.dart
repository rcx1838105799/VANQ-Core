import 'package:fl_clash/common/common.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Rhythm tap: notes fall down 4 lanes, tap the lane button while a
/// note is in the hit zone. 30 seconds, each hit +1 (session cap 30).
class VanqRhythmGameView extends ConsumerStatefulWidget {
  const VanqRhythmGameView({super.key});

  @override
  ConsumerState<VanqRhythmGameView> createState() => _VanqRhythmGameViewState();
}

class _Note {
  final int lane;
  double y;

  _Note(this.lane, this.y);
}

class _VanqRhythmGameViewState extends ConsumerState<VanqRhythmGameView> {
  final _random = Random();
  Timer? _tick;
  Timer? _spawn;
  Timer? _clock;
  List<_Note> _notes = [];
  bool _playing = false;
  int _secondsLeft = 30;
  int _hits = 0;
  int _sessionAwarded = 0;
  String? _result;

  static const _fallSpeed = 0.012;
  static const _hitZone = 0.82;

  @override
  void dispose() {
    _tick?.cancel();
    _spawn?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  void _start() async {
    final ok = await ref.read(vanqGameProvider.notifier).recordPlay('rhythm');
    if (!mounted) return;
    if (!ok) {
      setState(() => _result = '今日次数已用完，明天再来');
      return;
    }
    _tick?.cancel();
    _spawn?.cancel();
    _clock?.cancel();
    setState(() {
      _notes = [];
      _playing = true;
      _secondsLeft = 30;
      _hits = 0;
      _sessionAwarded = 0;
      _result = null;
    });
    _tick = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        for (final note in _notes) {
          note.y += _fallSpeed;
        }
        _notes.removeWhere((note) => note.y > 1.05);
      });
    });
    _spawn = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted || !_playing) return;
      setState(() => _notes.add(_Note(_random.nextInt(4), 0)));
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _stop();
    });
  }

  void _stop() {
    _tick?.cancel();
    _spawn?.cancel();
    _clock?.cancel();
    if (!mounted) return;
    setState(() {
      _playing = false;
      _notes = [];
      _result = '时间到！命中 $_hits 次，本局 +$_sessionAwarded 积分';
    });
  }

  Future<void> _tapLane(int lane) async {
    if (!_playing) return;
    _Note? target;
    for (final note in _notes) {
      if (note.lane == lane && (note.y - _hitZone).abs() < 0.12) {
        target = note;
        break;
      }
    }
    if (target == null) return;
    setState(() {
      _notes.remove(target);
      _hits++;
    });
    if (_sessionAwarded < 30) {
      final awarded = await ref
          .read(vanqGameProvider.notifier)
          .awardGamePoints(1);
      _sessionAwarded += awarded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('rhythm') <= 0;
    final remaining = game?.remainingPlays('rhythm') ?? 20;
    return Scaffold(
      appBar: AppBar(title: const Text('节奏打击')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '剩余 $_secondsLeft 秒',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '命中 $_hits',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: ShapeDecoration(
                  color: const Color(0xFF141416),
                  shape: AppShape.all(AppCorner.lg),
                ),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        for (var lane = 0; lane < 4; lane++)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: lane < 3
                                      ? const BorderSide(color: Colors.white12)
                                      : BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (final note in _notes)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final laneW = constraints.maxWidth / 4;
                            return Stack(
                              children: [
                                Positioned(
                                  left: note.lane * laneW + laneW * 0.15,
                                  top: note.y * constraints.maxHeight - 20,
                                  child: Container(
                                    width: laneW * 0.7,
                                    height: 40,
                                    decoration: ShapeDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6C5CE7),
                                          Color(0xFFFD79A8),
                                        ],
                                      ),
                                      shape: AppShape.all(AppCorner.md),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '♪',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Positioned(
                                left: 8,
                                right: 8,
                                top: _hitZone * constraints.maxHeight - 20,
                                child: Container(
                                  height: 40,
                                  decoration: ShapeDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: AppShape.all(AppCorner.md),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var lane = 0; lane < 4; lane++) ...[
                  Expanded(
                    child: FilledButton(
                      onPressed: _playing ? () => _tapLane(lane) : null,
                      child: Text('♪ ${lane + 1}'),
                    ),
                  ),
                  if (lane < 3) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _playing || outOfPlays ? null : _start,
              child: Text(_playing ? '进行中…' : '开始游戏'),
            ),
            const SizedBox(height: 8),
            Text(
              outOfPlays
                  ? '今日次数已用完，明天再来'
                  : '音符落到亮区时点对应按钮，每命中 +1（本局上限 30），今日剩余 $remaining 次',
              style: context.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
