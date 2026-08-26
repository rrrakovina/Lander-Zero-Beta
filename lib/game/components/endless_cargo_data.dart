import 'dart:math';
import 'package:flutter/material.dart';
import 'cargo_capsule.dart';

/// Rarity tier for procedural expedition cargo capsules.
enum EndlessCargoRarity {
  standard(
    multiplier: 1.0,
    color: Color(0xFFECEFF1),
    glowColor: Color(0x33ECEFF1),
    nameRu: 'Обычный',
    nameEn: 'Standard',
  ),
  highValue(
    multiplier: 1.5,
    color: Color(0xFF00E5FF),
    glowColor: Color(0x6600E5FF),
    nameRu: 'Ценный',
    nameEn: 'High-Value',
  ),
  prototype(
    multiplier: 2.5,
    color: Color(0xFFE040FB),
    glowColor: Color(0x88E040FB),
    nameRu: 'Прототип',
    nameEn: 'Prototype',
  ),
  relic(
    multiplier: 5.0,
    color: Color(0xFFFFD600),
    glowColor: Color(0xAAFFD600),
    nameRu: 'Древний Реликт',
    nameEn: 'Ancient Relic',
  );

  final double multiplier;
  final Color color;
  final Color glowColor;
  final String nameRu;
  final String nameEn;

  const EndlessCargoRarity({
    required this.multiplier,
    required this.color,
    required this.glowColor,
    required this.nameRu,
    required this.nameEn,
  });
}

/// Physical and gameplay modifiers for procedural cargo.
enum EndlessCargoModifier {
  none(
    nameRu: 'Стандарт',
    nameEn: 'Standard',
    density: 0.10,
    icon: Icons.check_circle_outline_rounded,
  ),
  magnetic(
    nameRu: 'Магнитный',
    nameEn: 'Magnetic',
    density: 0.10,
    icon: Icons.all_inclusive_rounded,
  ),
  volatile(
    nameRu: 'Нестабильный',
    nameEn: 'Volatile',
    density: 0.10,
    icon: Icons.warning_amber_rounded,
  ),
  heavy(
    nameRu: 'Сверхтяжелый',
    nameEn: 'Super-Dense',
    density: 0.18,
    icon: Icons.fitness_center_rounded,
  ),
  antigrav(
    nameRu: 'Антигравитация',
    nameEn: 'Zero-G Core',
    density: 0.05,
    icon: Icons.flight_takeoff_rounded,
  );

  final String nameRu;
  final String nameEn;
  final double density;
  final IconData icon;

  const EndlessCargoModifier({
    required this.nameRu,
    required this.nameEn,
    required this.density,
    required this.icon,
  });
}

/// Complete procedural cargo description with rarity, modifiers, and telemetry serials.
class EndlessCargoInfo {
  final CargoType archetype;
  final EndlessCargoRarity rarity;
  final EndlessCargoModifier modifier;
  final String serialCode;
  final int baseScore;
  final int baseCoins;

  const EndlessCargoInfo({
    required this.archetype,
    required this.rarity,
    required this.modifier,
    required this.serialCode,
    required this.baseScore,
    required this.baseCoins,
  });

  int get totalScore => (baseScore * rarity.multiplier).toInt();
  int get totalCoins => (baseCoins * rarity.multiplier).toInt();

  String getTitle(String lang) {
    final archetypeRu = _getArchetypeRu(archetype);
    final archetypeEn = _getArchetypeEn(archetype);
    final isRu = lang == 'ru';

    final name = isRu ? archetypeRu : archetypeEn;
    final rName = isRu ? rarity.nameRu : rarity.nameEn;
    return '[$serialCode] $name ($rName)';
  }

  static String _getArchetypeRu(CargoType type) {
    switch (type) {
      case CargoType.rescuePod:
        return 'Крио-капсула';
      case CargoType.titaniumCrate:
        return 'Титановый Сейф';
      case CargoType.cryoBarrel:
        return 'Крио-Контейнер';
      case CargoType.scienceProbe:
        return 'Научный Зонд';
      case CargoType.energyCrystal:
        return 'Изотопный Кристалл';
    }
  }

  static String _getArchetypeEn(CargoType type) {
    switch (type) {
      case CargoType.rescuePod:
        return 'Cryo Pod';
      case CargoType.titaniumCrate:
        return 'Titanium Vault';
      case CargoType.cryoBarrel:
        return 'Cryo Canister';
      case CargoType.scienceProbe:
        return 'Science Probe';
      case CargoType.energyCrystal:
        return 'Energy Crystal';
    }
  }
}

/// Generator for diverse, balanced procedural cargo capsules.
class EndlessCargoGenerator {
  static EndlessCargoInfo generate({
    required double distanceMeters,
    required Random random,
    int? chunkIndex,
  }) {
    // 1. Archetype selection
    final allArchetypes = CargoType.values;
    final archetype = allArchetypes[random.nextInt(allArchetypes.length)];

    // 2. Rarity roll with distance-based scaling
    final double roll = random.nextDouble();
    EndlessCargoRarity rarity;

    if (distanceMeters < 400.0) {
      // Early depth: mostly standard and high-value
      if (roll < 0.65) {
        rarity = EndlessCargoRarity.standard;
      } else if (roll < 0.92) {
        rarity = EndlessCargoRarity.highValue;
      } else {
        rarity = EndlessCargoRarity.prototype;
      }
    } else if (distanceMeters < 1200.0) {
      // Medium depth: high chance of high-value and prototype
      if (roll < 0.35) {
        rarity = EndlessCargoRarity.standard;
      } else if (roll < 0.75) {
        rarity = EndlessCargoRarity.highValue;
      } else if (roll < 0.94) {
        rarity = EndlessCargoRarity.prototype;
      } else {
        rarity = EndlessCargoRarity.relic;
      }
    } else {
      // Deep abyss: high tier prototypes and relics
      if (roll < 0.20) {
        rarity = EndlessCargoRarity.standard;
      } else if (roll < 0.55) {
        rarity = EndlessCargoRarity.highValue;
      } else if (roll < 0.85) {
        rarity = EndlessCargoRarity.prototype;
      } else {
        rarity = EndlessCargoRarity.relic;
      }
    }

    // 3. Modifier roll
    final double modRoll = random.nextDouble();
    EndlessCargoModifier modifier;
    if (modRoll < 0.55) {
      modifier = EndlessCargoModifier.none;
    } else if (modRoll < 0.70) {
      modifier = EndlessCargoModifier.magnetic;
    } else if (modRoll < 0.80) {
      modifier = EndlessCargoModifier.volatile;
    } else if (modRoll < 0.90) {
      modifier = EndlessCargoModifier.heavy;
    } else {
      modifier = EndlessCargoModifier.antigrav;
    }

    // 4. Serial Code generation
    final prefix = _getPrefix(archetype);
    final number = 100 + random.nextInt(900);
    final serialCode = '$prefix-$number';

    // 5. Base score and coins
    final int baseScore = 1000;
    final int baseCoins = 100;

    return EndlessCargoInfo(
      archetype: archetype,
      rarity: rarity,
      modifier: modifier,
      serialCode: serialCode,
      baseScore: baseScore,
      baseCoins: baseCoins,
    );
  }

  static String _getPrefix(CargoType type) {
    switch (type) {
      case CargoType.rescuePod:
        return 'POD';
      case CargoType.titaniumCrate:
        return 'VALT';
      case CargoType.cryoBarrel:
        return 'CRYO';
      case CargoType.scienceProbe:
        return 'PROB';
      case CargoType.energyCrystal:
        return 'CORE';
    }
  }
}