import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'vanq_theme.dart';

const _actions = [
  ('greet', '打招呼'),
  ('headpat', '摸头'),
  ('poke', '轻戳'),
  ('date', '约会'),
  ('oath', '誓约'),
];

Color _rarityColor(VanqRarity rarity) => switch (rarity) {
  VanqRarity.ur => const Color(0xFFE879F9),
  VanqRarity.ssr => const Color(0xFFFBBF24),
  VanqRarity.sr => VanqTheme.violetSoft,
};

class VanqCompanionView extends ConsumerStatefulWidget {
  const VanqCompanionView({super.key});

  @override
  ConsumerState<VanqCompanionView> createState() => _VanqCompanionViewState();
}

class _VanqCompanionViewState extends ConsumerState<VanqCompanionView> {
  String? _bubble;
  bool _busy = false;

  Future<void> _interact(String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(vanqCompanionProvider.notifier)
        .interact(action);
    setState(() {
      _busy = false;
      _bubble = result.awarded > 0
          ? '${result.line}（好感 +${result.awarded}）'
          : '${result.line}（今日好感已满）';
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(vanqCompanionProvider).value;
    final companion = data?.companion ?? VanqCharacter.fallback;
    final affection = data?.affectionOf(companion.id) ?? 0;
    final level = affection ~/ 20 + 1;
    final progress = (affection % 20) / 20;
    final owned = data?.owned ?? {companion.id};
    return Scaffold(
      backgroundColor: VanqTheme.background,
      appBar: AppBar(title: const Text('伴侣舱')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Portrait(character: companion, bubble: _bubble),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  companion.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: VanqTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  color: _rarityColor(companion.rarity),
                  shape: AppShape.all(AppCorner.full),
                ),
                child: Text(
                  companion.rarity.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            companion.title,
            style: const TextStyle(
              fontSize: 13,
              color: VanqTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '好感 Lv.$level',
                style: const TextStyle(
                  fontSize: 13,
                  color: VanqTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: ShapeDecoration(
                    color: VanqTheme.cardBorder,
                    shape: AppShape.all(AppCorner.full),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        gradient: VanqTheme.brandGradient,
                        shape: AppShape.all(AppCorner.full),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$affection',
                style: const TextStyle(
                  fontSize: 13,
                  color: VanqTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final action in _actions)
                FilledButton(
                  onPressed: _busy ? null : () => _interact(action.$1),
                  style: FilledButton.styleFrom(
                    backgroundColor: VanqTheme.violet,
                  ),
                  child: Text(action.$2),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '已拥有角色',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: VanqTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vanqCharacters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = vanqCharacters[index];
                final has = owned.contains(c.id);
                final selected = c.id == companion.id;
                return _OwnedAvatar(
                  character: c,
                  owned: has,
                  selected: selected,
                  onTap: has
                      ? () => ref
                            .read(vanqCompanionProvider.notifier)
                            .setCompanion(c.id)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  final VanqCharacter character;
  final String? bubble;

  const _Portrait({required this.character, required this.bubble});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
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
          if (bubble != null)
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
                  bubble!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: VanqTheme.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnedAvatar extends StatelessWidget {
  final VanqCharacter character;
  final bool owned;
  final bool selected;
  final VoidCallback? onTap;

  const _OwnedAvatar({
    required this.character,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: ShapeDecoration(
              color: VanqTheme.card,
              shape: AppShape.all(AppCorner.full).copyWith(
                side: selected
                    ? const BorderSide(color: VanqTheme.violet, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: ClipOval(
              child: owned
                  ? Image.asset(
                      character.portraitAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          character.name[0],
                          style: const TextStyle(
                            fontSize: 20,
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
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              owned ? character.name : '???',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: VanqTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VanqBackgroundView extends ConsumerWidget {
  const VanqBackgroundView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(vanqCompanionProvider).value;
    final bgId = ref.watch(vanqBackgroundProvider).value ?? '';
    final owned = data?.owned ?? {};
    final options = vanqCharacters.where((c) => owned.contains(c.id)).toList();
    return Scaffold(
      backgroundColor: VanqTheme.background,
      appBar: AppBar(title: const Text('背景主题')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _BackgroundOption(
            label: '默认暗黑',
            selected: bgId.isEmpty,
            onTap: () async {
              await ref.read(vanqBackgroundProvider.notifier).clearBackground();
              if (context.mounted) {
                context.showSnackBar('已切换为默认暗黑背景');
              }
            },
          ),
          const SizedBox(height: 12),
          for (final c in options) ...[
            _BackgroundOption(
              label: '${c.name} · ${c.title}',
              selected: bgId == c.id,
              portraitAsset: c.portraitAsset,
              onTap: () async {
                await ref
                    .read(vanqBackgroundProvider.notifier)
                    .setBackground(c.id);
                if (context.mounted) {
                  context.showSnackBar('背景已换成 ${c.name}');
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BackgroundOption extends StatelessWidget {
  final String label;
  final bool selected;
  final String? portraitAsset;
  final VoidCallback onTap;

  const _BackgroundOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.portraitAsset,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: VanqTheme.card,
          shape: AppShape.all(AppCorner.md).copyWith(
            side: selected
                ? const BorderSide(color: VanqTheme.violet, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            if (portraitAsset != null)
              SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(
                  portraitAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0x33FFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: VanqTheme.textPrimary,
                  ),
                ),
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: GlyphIcon(
                  AppGlyphs.check,
                  size: 20,
                  color: VanqTheme.violetSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
