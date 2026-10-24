import 'package:fl_clash/common/common.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';

/// Reaction test: tap as soon as the light turns green.
/// <250ms: +20, <400ms: +10, else +5. Early tap counts as a play.
class VanqReactionGameView extends ConsumerStatefulWidget {
  const VanqReactionGameView({super.key});

  @override
  ConsumerState<VanqReactionGameView> createState() =>
      _VanqReactionGameViewState();
}

enum _Phase { idle, waiting, ready, done }

class _VanqReactionGameViewState extends ConsumerState<VanqReactionGameView> {
  final _random = Random();
  _Phase _phase = _Phase.idle;
  Timer? _timer;
  DateTime? _greenAt;
  int? _ms;
  String? _result;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.waiting;
      _ms = null;
      _result = null;
    });
    final delay = 1000 + _random.nextInt(3000);
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _greenAt = DateTime.now();
      });
    });
  }

  Future<void> _tap() async {
    if (_phase == _Phase.waiting) {
      _timer?.cancel();
      await ref.read(vanqGameProvider.notifier).playGame('reaction', 0);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _result = '抢跑了！等绿灯再点';
      });
      return;
    }
    if (_phase != _Phase.ready || _greenAt == null) return;
    final ms = DateTime.now().difference(_greenAt!).inMilliseconds;
    final award = ms < 250
        ? 20
        : ms < 400
        ? 10
        : 5;
    final awarded = await ref
        .read(vanqGameProvider.notifier)
        .playGame('reaction', award);
    if (!mounted) return;
    String result;
    if (awarded < 0) {
      result = '今日次数已用完，明天再来';
    } else if (awarded > 0) {
      result = '反应 $ms 毫秒！+$awarded 积分';
    } else {
      result = '反应 $ms 毫秒！今日积分已达上限';
    }
    setState(() {
      _phase = _Phase.done;
      _ms = ms;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(vanqGameProvider).value;
    final outOfPlays = game != null && game.remainingPlays('reaction') <= 0;
    final remaining = game?.remainingPlays('reaction') ?? 20;
    final isGreen = _phase == _Phase.ready;
    return Scaffold(
      appBar: AppBar(title: const Text('反应测试')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: (_phase == _Phase.waiting || _phase == _Phase.ready)
                  ? _tap
                  : null,
              child: Container(
                width: 220,
                height: 220,
                decoration: ShapeDecoration(
                  color: _phase == _Phase.idle
                      ? Colors.grey
                      : isGreen
                      ? Colors.green
                      : Colors.red,
                  shape: AppShape.all(AppCorner.full),
                ),
                child: Center(
                  child: Text(
                    _phase == _Phase.idle
                        ? '点开始'
                        : isGreen
                        ? '点我！'
                        : '等绿灯…',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (_ms != null) ...[
              const SizedBox(height: 16),
              Text('反应时间：$_ms 毫秒', style: const TextStyle(fontSize: 18)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(_result!, style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed:
                  (_phase == _Phase.idle || _phase == _Phase.done) &&
                      !outOfPlays
                  ? _start
                  : null,
              child: const Text('开始测试'),
            ),
            const SizedBox(height: 16),
            Text(
              outOfPlays
                  ? '今日次数已用完，明天再来'
                  : '<250ms +20，<400ms +10，否则 +5，今日剩余 $remaining 次',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
