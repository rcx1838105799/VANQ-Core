import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'vanq_gacha.dart';
import 'vanq_game_center.dart';
import 'vanq_login.dart';
import 'vanq_plans.dart';
import 'vanq_theme.dart';

const _greetings = [
  '主人，今天也要好好上网哦～',
  '节点都准备好了，随时可以出发！',
  '今天的流量还很充足，放心用吧～',
  '记得签到领积分，可以兑流量哦！',
];

class VanqHomeView extends ConsumerStatefulWidget {
  const VanqHomeView({super.key});

  @override
  ConsumerState<VanqHomeView> createState() => _VanqHomeViewState();
}

class _VanqHomeViewState extends ConsumerState<VanqHomeView> {
  int _greetingIndex = 0;
  bool _showGreeting = false;

  Future<void> _toggleCore() async {
    final status = ref.read(coreStatusProvider);
    if (status == CoreStatus.connecting) return;
    if (status == CoreStatus.connected) {
      await ref.read(coreHandlerProvider).stop();
      ref.read(coreStatusProvider.notifier).value = CoreStatus.disconnected;
      return;
    }
    await ref.read(coreActionProvider.notifier).startCore();
  }

  void _openLogin() {
    showExtend<bool>(context, builder: (_) => const VanqLoginView());
  }

  @override
  Widget build(BuildContext context) {
    final coreStatus = ref.watch(coreStatusProvider);
    final account = ref.watch(vanqAccountProvider).value;
    final companion =
        ref.watch(vanqCompanionProvider).value?.companion ??
        VanqCharacter.fallback;
    final bgId = ref.watch(vanqBackgroundProvider).value ?? '';
    final bgChar = bgId.isEmpty ? null : VanqCharacter.byId(bgId);
    return Scaffold(
      backgroundColor: VanqTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            if (bgChar != null)
              Positioned.fill(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.25,
                        child: Image.asset(
                          bgChar.portraitAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(color: const Color(0xB30A0A0B)),
                    ),
                  ],
                ),
              ),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _TopBar(email: account?.info.email, onAvatarTap: _openLogin),
                const SizedBox(height: 20),
                _CompanionArea(
                  character: companion,
                  greeting: _showGreeting ? _greetings[_greetingIndex] : null,
                  onTap: () {
                    setState(() {
                      _greetingIndex = (_greetingIndex + 1) % _greetings.length;
                      _showGreeting = true;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _ConnectButton(status: coreStatus, onTap: _toggleCore),
                const SizedBox(height: 24),
                _TrafficCard(account: account, onLoginTap: _openLogin),
                const SizedBox(height: 20),
                _QuickEntries(
                  onProxies: () => ref
                      .read(currentPageLabelProvider.notifier)
                      .toPage(PageLabel.proxies),
                  onGames: () =>
                      BaseNavigator.push(context, const VanqGameCenterView()),
                  onPlans: () =>
                      BaseNavigator.push(context, const VanqPlansView()),
                  onGacha: () =>
                      BaseNavigator.push(context, const VanqGachaView()),
                ),
                const SizedBox(height: 20),
                const _CurrentNodeBar(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String? email;
  final VoidCallback onAvatarTap;

  const _TopBar({required this.email, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'VANQ Core',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: VanqTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onAvatarTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: VanqTheme.card,
              shape: AppShape.all(AppCorner.full),
            ),
            child: Center(
              child: email == null
                  ? const GlyphIcon(
                      AppGlyphs.account,
                      size: 20,
                      color: VanqTheme.textSecondary,
                    )
                  : Text(
                      email![0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: VanqTheme.platinum,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanionArea extends StatelessWidget {
  final VanqCharacter character;
  final String? greeting;
  final VoidCallback onTap;

  const _CompanionArea({
    required this.character,
    required this.greeting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 220,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          gradient: VanqTheme.companionPlaceholder,
          shape: AppShape.all(AppCorner.lg),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                character.portraitAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      color: Color(0x33FFFFFF),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: Text(
                '${character.name} · 看板娘',
                style: const TextStyle(
                  fontSize: 13,
                  color: VanqTheme.textSecondary,
                ),
              ),
            ),
            if (greeting != null)
              Positioned(
                left: 16,
                right: 16,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xCC141416),
                    shape: AppShape.all(AppCorner.md),
                  ),
                  child: Text(
                    greeting!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: VanqTheme.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final CoreStatus status;
  final VoidCallback onTap;

  const _ConnectButton({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final connected = status == CoreStatus.connected;
    final connecting = status == CoreStatus.connecting;
    final label = connected
        ? '已连接'
        : connecting
        ? '连接中…'
        : '未连接';
    final sub = connected
        ? '点按断开'
        : connecting
        ? '正在启动核心'
        : '点按开始连接';
    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              width: 140,
              height: 140,
              decoration: ShapeDecoration(
                gradient: connected ? VanqTheme.brandGradient : null,
                color: connected ? null : VanqTheme.card,
                shape: AppShape.all(AppCorner.full),
              ),
              child: Center(
                child: connecting
                    ? const SizedBox.square(
                        dimension: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: VanqTheme.platinum,
                        ),
                      )
                    : GlyphIcon(
                        connected ? AppGlyphs.check : AppGlyphs.proxies,
                        size: 44,
                        color: connected
                            ? Colors.white
                            : VanqTheme.textSecondary,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: VanqTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 13,
              color: VanqTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficCard extends StatelessWidget {
  final dynamic account;
  final VoidCallback onLoginTap;

  const _TrafficCard({required this.account, required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    final info = account?.info;
    if (info == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          color: VanqTheme.card,
          shape: AppShape.all(AppCorner.lg),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '登录官网账号，查看套餐与流量',
                style: TextStyle(fontSize: 14, color: VanqTheme.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: onLoginTap,
              style: FilledButton.styleFrom(backgroundColor: VanqTheme.violet),
              child: const Text('登录'),
            ),
          ],
        ),
      );
    }
    final usedRatio = info.transferEnable > 0
        ? (info.used / info.transferEnable).clamp(0.0, 1.0)
        : 0.0;
    final expiry = info.expiredAt != null
        ? DateTime.fromMillisecondsSinceEpoch(info.expiredAt! * 1000)
        : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: VanqTheme.card,
        shape: AppShape.all(AppCorner.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  info.planName ?? '我的套餐',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: VanqTheme.textPrimary,
                  ),
                ),
              ),
              if (expiry != null)
                Text(
                  '到期 ${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: VanqTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 8,
            decoration: ShapeDecoration(
              color: VanqTheme.cardBorder,
              shape: AppShape.all(AppCorner.full),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: usedRatio,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  gradient: VanqTheme.brandGradient,
                  shape: AppShape.all(AppCorner.full),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TrafficStat(
                  label: '上传',
                  value: info.upload.traffic.show,
                ),
              ),
              Expanded(
                child: _TrafficStat(
                  label: '下载',
                  value: info.download.traffic.show,
                ),
              ),
              Expanded(
                child: _TrafficStat(
                  label: '剩余',
                  value: info.remaining.traffic.show,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficStat extends StatelessWidget {
  final String label;
  final String value;

  const _TrafficStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: VanqTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: VanqTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _QuickEntries extends StatelessWidget {
  final VoidCallback onProxies;
  final VoidCallback onGames;
  final VoidCallback onPlans;
  final VoidCallback onGacha;

  const _QuickEntries({
    required this.onProxies,
    required this.onGames,
    required this.onPlans,
    required this.onGacha,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickEntry(
            glyph: AppGlyphs.proxies,
            label: '节点',
            onTap: onProxies,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickEntry(
            glyph: AppGlyphs.tools,
            label: '游戏',
            onTap: onGames,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickEntry(
            glyph: AppGlyphs.profiles,
            label: '套餐',
            onTap: onPlans,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickEntry(
            glyph: AppGlyphs.resources,
            label: '抽卡',
            onTap: onGacha,
          ),
        ),
      ],
    );
  }
}

class _QuickEntry extends StatelessWidget {
  final Glyph glyph;
  final String label;
  final VoidCallback onTap;

  const _QuickEntry({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: ShapeDecoration(
          color: VanqTheme.card,
          shape: AppShape.all(AppCorner.md),
        ),
        child: Column(
          children: [
            GlyphIcon(glyph, size: 24, color: VanqTheme.violetSoft),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: VanqTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentNodeBar extends ConsumerWidget {
  const _CurrentNodeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final delays = ref.watch(trayDelaysProvider);
    final first = groups.isNotEmpty ? groups.first : null;
    final now = first?.now ?? '';
    final groupDelays = first != null ? delays[first.name] : null;
    final delay = groupDelays?[now];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ShapeDecoration(
        color: VanqTheme.card,
        shape: AppShape.all(AppCorner.md),
      ),
      child: Row(
        children: [
          const GlyphIcon(
            AppGlyphs.proxies,
            size: 18,
            color: VanqTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              now.isEmpty ? '未选择节点' : now,
              style: const TextStyle(
                fontSize: 14,
                color: VanqTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            delay == null ? '' : '${delay}ms',
            style: const TextStyle(
              fontSize: 13,
              color: VanqTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
