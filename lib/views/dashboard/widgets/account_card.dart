import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/vanq_login.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// VANQ Core account card on the dashboard.
///
/// Shows a sign-in prompt when logged out, and the plan / traffic / expiry
/// when signed in.
class VanqAccountCard extends ConsumerWidget {
  const VanqAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(vanqAccountProvider);
    return CommonCard(
      type: CommonCardType.filled,
      radius: AppCorner.lg,
      padding: const EdgeInsets.all(20),
      child: account.when(
        data: (data) => data == null
            ? _SignInPrompt(onSignIn: () => _openLogin(context))
            : _AccountInfo(
                onSignOut: () =>
                    ref.read(vanqAccountProvider.notifier).signOut(),
                onRefresh: () =>
                    ref.read(vanqAccountProvider.notifier).refresh(),
              ),
        loading: () => const Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => _SignInPrompt(onSignIn: () => _openLogin(context)),
      ),
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    final signedIn = await showExtend<bool>(
      context,
      builder: (_) => const VanqLoginView(),
    );
    if (signedIn == true && context.mounted) {
      context.showNotifier(
        context.appLocalizations.vanqSignInSuccess,
        level: MessageLevel.success,
      );
    }
  }
}

class _SignInPrompt extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignInPrompt({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const GlyphIcon(AppGlyphs.account, size: 20),
            const SizedBox(width: 8),
            Text(
              appLocalizations.vanqAccount,
              style: textTheme.titleMedium?.toSoftBold,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          appLocalizations.vanqSignInPrompt,
          style: textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(
            onPressed: onSignIn,
            child: Text(appLocalizations.vanqLogin),
          ),
        ),
      ],
    );
  }
}

class _AccountInfo extends ConsumerWidget {
  final VoidCallback onSignOut;
  final VoidCallback onRefresh;

  const _AccountInfo({required this.onSignOut, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(vanqAccountProvider).value;
    if (data == null) return const SizedBox();
    final info = data.info;
    final appLocalizations = context.appLocalizations;
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final usedRatio = info.transferEnable > 0
        ? (info.used / info.transferEnable).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.planName ?? appLocalizations.vanqAccount,
                    style: textTheme.titleMedium?.toSoftBold,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.email,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: appLocalizations.vanqRefresh,
              onPressed: onRefresh,
              icon: const GlyphIcon(AppGlyphs.sync),
            ),
            TextButton(
              onPressed: onSignOut,
              child: Text(appLocalizations.vanqSignOut),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TrafficBar(usedRatio: usedRatio),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${appLocalizations.vanqRemainingTraffic} ${info.remaining.traffic.show}',
              style: textTheme.bodyMedium,
            ),
            if (info.expiredAt != null)
              Text(
                appLocalizations.vanqExpiresOn(_formatDate(info.expiredAt!)),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _TrafficBar extends StatelessWidget {
  final double usedRatio;

  const _TrafficBar({required this.usedRatio});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: ShapeDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        shape: AppShape.all(AppCorner.full),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: usedRatio,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
            ),
            shape: AppShape.all(AppCorner.full),
          ),
        ),
      ),
    );
  }
}
