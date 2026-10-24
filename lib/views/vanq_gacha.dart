import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'vanq_theme.dart';

Color _rarityColor(VanqRarity rarity) => switch (rarity) {
  VanqRarity.ur => const Color(0xFFE879F9),
  VanqRarity.ssr => const Color(0xFFFBBF24),
  VanqRarity.sr => VanqTheme.violetSoft,
};

class VanqGachaView extends ConsumerStatefulWidget {
  const VanqGachaView({super.key});

  @override
  ConsumerState<VanqGachaView> createState() => _VanqGachaViewState();
}

class _VanqGachaViewState extends ConsumerState<VanqGachaView> {
  List<VanqGachaResult>? _results;
  bool _busy = false;

  Future<void> _draw(Future<List<VanqGachaResult>?> Function() call) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _results = null;
    });
    final results = await call();
    setState(() => _busy = false);
    if (results == null) {
      if (mounted) {
        context.showSnackBar('积分不足');
      }
      return;
    }
    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(vanqCompanionProvider).value;
    final points = ref.watch(vanqGameProvider).value?.points ?? 0;
    final owned = data?.owned ?? {};
    return Scaffold(
      backgroundColor: VanqTheme.background,
      appBar: AppBar(title: const Text('抽卡')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              const GlyphIcon(
                AppGlyphs.resources,
                size: 20,
                color: VanqTheme.violetSoft,
              ),
              const SizedBox(width: 8),
              Text(
                '积分 $points',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: VanqTheme.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                '单抽 100 · 十连 950',
                style: TextStyle(fontSize: 13, color: VanqTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _draw(
                          ref.read(vanqCompanionProvider.notifier).drawSingle,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: VanqTheme.violet,
                  ),
                  child: const Text('单抽'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _draw(
                          ref.read(vanqCompanionProvider.notifier).drawTen,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: VanqTheme.pink,
                  ),
                  child: const Text('十连（保底 SSR）'),
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_results != null) ...[
            const SizedBox(height: 24),
            const Text(
              '抽卡结果',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: VanqTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: _results!.length,
              itemBuilder: (context, index) {
                final result = _results![index];
                return _ResultCard(result: result);
              },
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                '陈列架',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: VanqTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '已拥有 ${owned.length}/16，点卡片设为看板娘',
                style: const TextStyle(
                  fontSize: 12,
                  color: VanqTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: vanqCharacters.length,
            itemBuilder: (context, index) {
              final c = vanqCharacters[index];
              final has = owned.contains(c.id);
              final isCompanion = data?.companionId == c.id;
              return _ShelfCard(
                character: c,
                owned: has,
                isCompanion: isCompanion,
                onTap: has
                    ? () async {
                        await ref
                            .read(vanqCompanionProvider.notifier)
                            .setCompanion(c.id);
                        if (context.mounted) {
                          context.showSnackBar('已设 ${c.name} 为看板娘');
                        }
                      }
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final VanqGachaResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final c = result.character;
    final color = _rarityColor(c.rarity);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 250),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: VanqTheme.card,
          shape: AppShape.all(
            AppCorner.md,
          ).copyWith(side: BorderSide(color: color, width: 1.5)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                c.portraitAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                color: const Color(0xCC141416),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: VanqTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          c.rarity.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    if (!result.isNew)
                      const Text(
                        '重复 +50 积分',
                        style: TextStyle(
                          fontSize: 11,
                          color: VanqTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (result.isNew)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: ShapeDecoration(
                    color: color,
                    shape: AppShape.all(AppCorner.full),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

class _ShelfCard extends StatelessWidget {
  final VanqCharacter character;
  final bool owned;
  final bool isCompanion;
  final VoidCallback? onTap;

  const _ShelfCard({
    required this.character,
    required this.owned,
    required this.isCompanion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(character.rarity);
    return InkWell(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: VanqTheme.card,
          shape: AppShape.all(AppCorner.md).copyWith(
            side: isCompanion
                ? const BorderSide(color: VanqTheme.violet, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: owned
                  ? Image.asset(
                      character.portraitAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          character.name[0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: VanqTheme.textPrimary,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: GlyphIcon(
                        AppGlyphs.more,
                        size: 20,
                        color: VanqTheme.textMuted,
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xCC141416),
                child: Text(
                  owned ? character.name : '???',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: owned ? color : VanqTheme.textMuted,
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
