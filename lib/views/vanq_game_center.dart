import 'package:fl_clash/common/common.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/features/vanq/vanq_api.dart';

import 'vanq_game_2048.dart';
import 'vanq_game_blackjack.dart';
import 'vanq_game_ddz.dart';
import 'vanq_game_dice.dart';
import 'vanq_game_memory.dart';
import 'vanq_game_poker.dart';
import 'vanq_game_reaction.dart';
import 'vanq_game_rhythm.dart';
import 'vanq_game_rps.dart';
import 'vanq_game_slots.dart';
import 'vanq_game_wheel.dart';

/// VANQ Core game center: check-in, mini-games, points.
///
/// Anime style, violet→pink brand gradient. Rewards are intentionally tiny
/// (25 points = 1MB); paid plans remain the main path.
class VanqGameCenterView extends ConsumerWidget {
  const VanqGameCenterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(vanqGameProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('游戏中心')),
      body: game.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PointsHeader(data: data),
            const SizedBox(height: 16),
            _CheckInCard(data: data),
            const SizedBox(height: 16),
            Text(
              '小游戏',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '每种游戏每日限 20 次，游戏积分每日上限 200',
              style: context.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: [
                _GameGridTile(
                  gameId: 'ddz',
                  title: '斗地主',
                  icon: '🃏',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqDdzGameView()),
                ),
                _GameGridTile(
                  gameId: 'g2048',
                  title: '2048',
                  icon: '🔢',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqGame2048View()),
                ),
                _GameGridTile(
                  gameId: 'memory',
                  title: '记忆翻牌',
                  icon: '🌸',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqMemoryGameView()),
                ),
                _GameGridTile(
                  gameId: 'blackjack',
                  title: '21 点',
                  icon: '♠️',
                  data: data,
                  onTap: () => BaseNavigator.push(
                    context,
                    const VanqBlackjackGameView(),
                  ),
                ),
                _GameGridTile(
                  gameId: 'slots',
                  title: '老虎机',
                  icon: '🎰',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqSlotsGameView()),
                ),
                _GameGridTile(
                  gameId: 'rps',
                  title: '猜拳',
                  icon: '✊',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqRpsGameView()),
                ),
                _GameGridTile(
                  gameId: 'rhythm',
                  title: '节奏打击',
                  icon: '♪',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqRhythmGameView()),
                ),
                _GameGridTile(
                  gameId: 'reaction',
                  title: '反应测试',
                  icon: '⚡',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqReactionGameView()),
                ),
                _GameGridTile(
                  gameId: 'dice',
                  title: '掷骰子',
                  icon: '🎲',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqDiceGameView()),
                ),
                _GameGridTile(
                  gameId: 'poker',
                  title: '猜扑克',
                  icon: '♥️',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqPokerGameView()),
                ),
                _GameGridTile(
                  gameId: 'wheel',
                  title: '幸运转盘',
                  icon: '🎡',
                  data: data,
                  onTap: () =>
                      BaseNavigator.push(context, const VanqWheelGameView()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RedeemCard(),
          ],
        ),
      ),
    );
  }
}

class _PointsHeader extends StatelessWidget {
  final VanqGameData data;

  const _PointsHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: AppShape.all(AppCorner.lg),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.points}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text('我的积分', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '可兑 ${data.redeemableMb} MB',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '25积分 = 1MB',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckInCard extends ConsumerWidget {
  final VanqGameData data;

  const _CheckInCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final checkedIn = data.lastCheckIn == today;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '每日签到',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    checkedIn
                        ? '今日已签到，连续 ${data.streak} 天'
                        : data.streak > 0
                        ? '连续 ${data.streak} 天，别断了！'
                        : '签到领积分，连续签到奖励更多',
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: checkedIn
                  ? null
                  : () async {
                      final award = await ref
                          .read(vanqGameProvider.notifier)
                          .checkIn();
                      if (context.mounted && award > 0) {
                        context.showSnackBar('签到成功！+$award 积分');
                      }
                    },
              child: Text(checkedIn ? '已签到' : '签到'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameGridTile extends StatelessWidget {
  final String gameId;
  final String title;
  final String icon;
  final VanqGameData data;
  final VoidCallback onTap;

  const _GameGridTile({
    required this.gameId,
    required this.title,
    required this.icon,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = data.remainingPlays(gameId);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                remaining > 0 ? '剩余 $remaining 次' : '今日已用完',
                style: TextStyle(
                  fontSize: 11,
                  color: remaining > 0 ? null : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RedeemCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RedeemCard> createState() => _RedeemCardState();
}

class _RedeemCardState extends ConsumerState<_RedeemCard> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '兑换码',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('输入兑换码兑换流量', style: context.textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '请输入兑换码',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final code = _controller.text.trim();
                          if (code.isEmpty) return;
                          setState(() => _busy = true);
                          try {
                            final account = ref.read(vanqAccountProvider).value;
                            if (account == null) {
                              context.showSnackBar('请先登录');
                              return;
                            }
                            final msg = await VanqApi().redeemCode(
                              authData: account.authData,
                              code: code,
                            );
                            _controller.clear();
                            if (context.mounted) {
                              context.showSnackBar(msg);
                            }
                            // Refresh subscription info after redeem.
                            await ref
                                .read(vanqAccountProvider.notifier)
                                .refresh();
                          } catch (e) {
                            if (context.mounted) {
                              context.showSnackBar('兑换失败: $e');
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('兑换'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
