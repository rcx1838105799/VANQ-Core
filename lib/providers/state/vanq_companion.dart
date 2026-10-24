part of '../state.dart';

enum VanqRarity { ur, ssr, sr }

extension VanqRarityLabel on VanqRarity {
  String get label => switch (this) {
    VanqRarity.ur => 'UR',
    VanqRarity.ssr => 'SSR',
    VanqRarity.sr => 'SR',
  };
}

class VanqCharacter {
  final String id;
  final String name;
  final VanqRarity rarity;
  final String title;

  const VanqCharacter({
    required this.id,
    required this.name,
    required this.rarity,
    required this.title,
  });

  String get portraitAsset => 'assets/images/waifu/waifu_$id.jpg';

  String voiceAsset(String action) => action == 'greet'
      ? 'assets/voices/char_${id}_greet.mp3'
      : 'assets/voices/act_${id}_$action.mp3';

  static VanqCharacter byId(String id) => vanqCharacters.firstWhere(
    (c) => c.id == id,
    orElse: () => vanqCharacters.first,
  );

  static VanqCharacter get fallback => vanqCharacters.first;
}

const vanqCharacters = [
  VanqCharacter(
    id: 'yuzuki',
    name: '星野紫音',
    rarity: VanqRarity.ur,
    title: '盛夏球场汽水甜心',
  ),
  VanqCharacter(
    id: 'seoyeon',
    name: '韩瑞妍',
    rarity: VanqRarity.ur,
    title: '魅影顶流女团主舞',
  ),
  VanqCharacter(
    id: 'shirahime',
    name: '白姬绫乃',
    rarity: VanqRarity.ur,
    title: '晨光梳妆台的白姬',
  ),
  VanqCharacter(
    id: 'lilia',
    name: '羽月莉莉亚',
    rarity: VanqRarity.ur,
    title: '月夜堕天使',
  ),
  VanqCharacter(
    id: 'ayano',
    name: '白宫绫乃',
    rarity: VanqRarity.ur,
    title: '月夜神社白银狐仙',
  ),
  VanqCharacter(
    id: 'shiranui',
    name: '白银凛音',
    rarity: VanqRarity.ssr,
    title: '银发冷艳黑客女武神',
  ),
  VanqCharacter(
    id: 'chaewon',
    name: '柳采源',
    rarity: VanqRarity.ssr,
    title: '甜辣财阀私人秘书',
  ),
  VanqCharacter(
    id: 'aoba',
    name: '青羽雪乃',
    rarity: VanqRarity.ssr,
    title: '蓝白瓷韵眼镜秘书',
  ),
  VanqCharacter(
    id: 'rino',
    name: '高坂梨乃',
    rarity: VanqRarity.ssr,
    title: '涩谷豹纹甜心',
  ),
  VanqCharacter(
    id: 'momo',
    name: '猫宫桃',
    rarity: VanqRarity.ssr,
    title: '元气猫耳女仆',
  ),
  VanqCharacter(
    id: 'riri',
    name: '金泽莉莉',
    rarity: VanqRarity.ssr,
    title: '绿茵应援队长',
  ),
  VanqCharacter(
    id: 'sakura',
    name: '星见咲良',
    rarity: VanqRarity.ssr,
    title: '星月魔法少女',
  ),
  VanqCharacter(
    id: 'hotaru',
    name: '星野萤',
    rarity: VanqRarity.sr,
    title: '赛博幻音双马尾歌姬',
  ),
  VanqCharacter(
    id: 'freya',
    name: '芙蕾雅·薇尔莉特',
    rarity: VanqRarity.sr,
    title: '极光星使领主',
  ),
  VanqCharacter(
    id: 'himari',
    name: '夏目陽葵',
    rarity: VanqRarity.sr,
    title: '深夜天台元气邻家妹',
  ),
  VanqCharacter(
    id: 'minami',
    name: '樱泽美波',
    rarity: VanqRarity.sr,
    title: '夏日泳池学姐',
  ),
];

const vanqInteractLines = {
  'greet': ['主人，今天也要好好上网哦～', '节点都准备好了，随时可以出发！', '今天的流量还很充足，放心用吧～'],
  'headpat': ['唔……再多摸一会儿嘛。', '嘿嘿，主人的手心好暖和。', '被摸头了……今天一整天都会很开心！'],
  'poke': ['呀！别戳啦……再戳我就要撒娇了。', '手指别乱碰呀……嗯，如果是你的话也不是不可以。', '被戳到了！要罚你请我喝汽水。'],
  'date': ['今晚一起去天台看星星吧，拉钩哦！', '月夜散步吗？好吧，允许你走在我身边。', '约会的话……就去有极光的地方，好不好？'],
  'oath': [
    '跨越千年的时光，我选择了你，永远陪在你身边。',
    '我的誓言只说给你一个人听：永远不会离开。',
    '从今往后，我的应援只为你一个人。',
  ],
};

class VanqCompanionData {
  final Set<String> owned;
  final String companionId;
  final Map<String, int> affection;
  final Map<String, int> addedToday;
  final String affectionDay;

  const VanqCompanionData({
    required this.owned,
    required this.companionId,
    required this.affection,
    required this.addedToday,
    required this.affectionDay,
  });

  VanqCharacter get companion => VanqCharacter.byId(companionId);

  int affectionOf(String id) => affection[id] ?? 0;
}

class VanqInteractResult {
  final String line;
  final int awarded;

  const VanqInteractResult({required this.line, required this.awarded});
}

class VanqGachaResult {
  final VanqCharacter character;
  final bool isNew;

  const VanqGachaResult({required this.character, required this.isNew});
}

@Riverpod(keepAlive: true)
class VanqCompanion extends _$VanqCompanion {
  static const singleCost = 100;
  static const tenCost = 950;
  static const duplicateRefund = 50;
  static const dailyAffectionCap = 10;
  static const affectionPerInteract = 2;

  @override
  Future<VanqCompanionData> build() async {
    final owned = await preferences.getVanqOwnedChars();
    final companionId = await preferences.getVanqCompanionId();
    final affection = await preferences.getVanqAffection();
    final day = await preferences.getVanqAffectionDay();
    final added = await preferences.getVanqAddedToday();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final ownedSet = owned.isEmpty ? {'yuzuki'} : owned.toSet();
    if (owned.isEmpty) {
      await preferences.saveVanqOwnedChars(['yuzuki']);
    }
    return VanqCompanionData(
      owned: ownedSet,
      companionId: companionId ?? 'yuzuki',
      affection: affection,
      addedToday: day == today ? added : {},
      affectionDay: today,
    );
  }

  Future<void> setCompanion(String id) async {
    final current = state.value;
    if (current == null || !current.owned.contains(id)) return;
    await preferences.saveVanqCompanionId(id);
    state = AsyncData(
      VanqCompanionData(
        owned: current.owned,
        companionId: id,
        affection: current.affection,
        addedToday: current.addedToday,
        affectionDay: current.affectionDay,
      ),
    );
  }

  Future<VanqInteractResult> interact(String action) async {
    final current = state.value;
    final lines = vanqInteractLines[action] ?? vanqInteractLines['greet']!;
    final line = lines[Random().nextInt(lines.length)];
    if (current == null) return VanqInteractResult(line: line, awarded: 0);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final addedToday = current.affectionDay == today
        ? Map<String, int>.from(current.addedToday)
        : <String, int>{};
    final id = current.companionId;
    final added = addedToday[id] ?? 0;
    if (added >= dailyAffectionCap) {
      return VanqInteractResult(line: line, awarded: 0);
    }
    const awarded = affectionPerInteract;
    addedToday[id] = added + awarded;
    final affection = Map<String, int>.from(current.affection);
    affection[id] = (affection[id] ?? 0) + awarded;
    await preferences.saveVanqAffectionDay(today);
    await preferences.saveVanqAddedToday(addedToday);
    await preferences.saveVanqAffection(affection);
    state = AsyncData(
      VanqCompanionData(
        owned: current.owned,
        companionId: id,
        affection: affection,
        addedToday: addedToday,
        affectionDay: today,
      ),
    );
    return VanqInteractResult(line: line, awarded: awarded);
  }

  VanqCharacter _roll(Random rng) {
    final roll = rng.nextDouble();
    final pool = roll < 0.03
        ? vanqCharacters.where((c) => c.rarity == VanqRarity.ur)
        : roll < 0.15
        ? vanqCharacters.where((c) => c.rarity == VanqRarity.ssr)
        : vanqCharacters.where((c) => c.rarity == VanqRarity.sr);
    final list = pool.toList();
    return list[rng.nextInt(list.length)];
  }

  Future<List<VanqGachaResult>?> _draw(int count, int cost) async {
    final current = state.value;
    if (current == null) return null;
    final game = ref.read(vanqGameProvider.notifier);
    final points = ref.read(vanqGameProvider).value?.points ?? 0;
    if (points < cost) return null;
    await game.addPoints(-cost);
    final rng = Random();
    final rolled = List.generate(count, (_) => _roll(rng));
    if (count > 1 && !rolled.any((c) => c.rarity != VanqRarity.sr)) {
      final pool = vanqCharacters
          .where((c) => c.rarity != VanqRarity.sr)
          .toList();
      rolled[rolled.length - 1] = pool[rng.nextInt(pool.length)];
    }
    final owned = Set<String>.from(current.owned);
    final results = <VanqGachaResult>[];
    for (final c in rolled) {
      if (owned.contains(c.id)) {
        await game.addPoints(duplicateRefund);
        results.add(VanqGachaResult(character: c, isNew: false));
      } else {
        owned.add(c.id);
        results.add(VanqGachaResult(character: c, isNew: true));
      }
    }
    await preferences.saveVanqOwnedChars(owned.toList());
    state = AsyncData(
      VanqCompanionData(
        owned: owned,
        companionId: current.companionId,
        affection: current.affection,
        addedToday: current.addedToday,
        affectionDay: current.affectionDay,
      ),
    );
    return results;
  }

  Future<List<VanqGachaResult>?> drawSingle() => _draw(1, singleCost);

  Future<List<VanqGachaResult>?> drawTen() => _draw(10, tenCost);
}
