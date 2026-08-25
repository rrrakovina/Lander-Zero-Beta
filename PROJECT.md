# Project: Lander Zero Retro-Futuristic Space Rescue Upgrade

## Architecture
- **Game Engine**: Flutter + Flame + Forge2D physics engine.
- **Rendering Layer**:
  - `lib/ui/painters/ship_mesh_renderer.dart`: Unified vector ship rendering engine for all 5 ships with crisp vector decals (`СССР-01`, `SWIFT-02`, `TITAN-V`, `QUASAR-IX`, `CY-88`, `INTERCEPTOR-07`), landing gear, and live cockpit astronaut animations.
  - `lib/ui/painters/rocket_painter.dart`: CustomPainter wrapping `ShipMeshRenderer` for garage, shop, map select, and menus.
  - `lib/game/components/lander.dart`: Flame/Forge2D body component delegating rendering to `ShipMeshRenderer` with live dynamic physics, G-force strain, and danger vector eye-tracking.
- **UI/UX & Atmosphere Layer**:
  - `lib/ui/screens/nick_entry_screen.dart`: Flight Cadet Terminal with ID badge layout, laser scanline animation, call sign sanitization, and starter ship selector (`sputnik` and `swift`).
  - `lib/ui/screens/main_menu_screen.dart` & `lib/ui/widgets/menu_background.dart`: Live hangar atmosphere with multi-layer cosmic parallax, docking bay steam/exhaust particle emitters, high-contrast glow buttons, and live telemetry ticker marquee.
  - `lib/ui/screens/map_select_screen.dart` & `lib/ui/painters/map_preview_painter.dart`: Tactical holographic briefing interface displaying environmental stats (gravity, wind drag, thermal flux, radiation, seismic, bounty), CRT scanlines, and wireframe planetary spheres for all 5 biomes + endless mode.
  - `lib/ui/screens/game_screen.dart` & Cockpit HUD widgets: Cybernetic flight instruments (G-force indicator, attitude/pitch horizon meter, Proximity Warning audio-visual alarm, pilot/base radio chatter overlay).
- **Physics, Biomes & Modes**:
  - `lib/game/lander_zero_game.dart`: Flame game loop orchestrating world gravity, wind, proximity calculations, stats updates, and game mode lifecycle.
  - `lib/game/components/cave.dart` & biomes: Custom terrain fixtures for `echo`, `wind`, `core`, `ice` (Europa $0.65G$, $\mu=0.08$, low friction, cryo-geysers, icicles), and `orbit` (zero-G $G=0$, drift, reverse thrusters).
  - `lib/game/components/stalactite.dart`, `geyser.dart`, `plasma_gust.dart`, `magma_bubble.dart`: Interactive environmental hazards.
  - `lib/game/components/endless_cave_manager.dart`: Procedural chunk-based endless rescue mode with chained capsule extractions, refuel/repair checkpoints, progressive difficulty, and infinite score tracking.
- **Persistence & Security Layer**:
  - `lib/game/state/game_state.dart`: Manages persistent game state with starter ships (`['sputnik', 'swift']`) and 5 ship configs.
  - `lib/game/state/save_security_manager.dart`: HMAC-SHA256 cryptographic signature generation and verification over sensitive state (`totalCoins`, `ownedRockets`, `leaderboard`), graceful tampering recovery, and nickname sanitization.
  - `lib/game/state/achievements_manager.dart`: 12 achievements (+7 new: `speed_demon`, `titanium_tether`, `zero_fuel_hero`, `fleet_admiral`, `ice_breaker`, `zero_g_master`, `cosmic_tycoon`) with persistent progress and rewards.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | HMAC-SHA256 Save Protection | Cryptographic tamper protection for coins, unlocks, leaderboard; graceful reset on tamper | M1 (DONE) | ORIGINAL_REQUEST §R5 |
| 2 | Nickname Sanitization | Strip control characters, enforce 1-15 valid character length | M1 (DONE) | ORIGINAL_REQUEST §R5 |
| 3 | Starter Ships Persistence | Default `['sputnik', 'swift']` unlocked at 0 cost in GameState | M1 (DONE) | ORIGINAL_REQUEST §R2 |
| 4 | 7 New Achievements System | 12 total achievements with rewards & persistent tracking in AchievementsManager | M1 (DONE) | ORIGINAL_REQUEST §R4 |
| 5 | Unified Ship Mesh Renderer | Extract `ShipMeshRenderer` eliminating duplicate geometry across painters & lander | M2 (DONE) | ORIGINAL_REQUEST §R2, §R5 |
| 6 | 5 Ships Fleet Expansion | Complete specs & upgrade tracks for Sputnik, Swift, Titan, Quasar, Cyclone | M2 (DONE) | ORIGINAL_REQUEST §R2 |
| 7 | Vector Decals & Insignias | Crisp vector markings (`СССР-01`, `SWIFT-02`, `TITAN-V`, `QUASAR-IX`, `CY-88`, `INTERCEPTOR-07`) | M2 (DONE) | ORIGINAL_REQUEST §R2 |
| 8 | Live Dynamic Astronaut Simulation | Head bobbing, G-force strain, velocity/hazard eye-tracking, panic blinks, unique suits | M2 (DONE) | ORIGINAL_REQUEST §R2 |
| 9 | Flight Cadet ID Terminal | Retro-futuristic ID badge, laser scanline animation, starter ship selection | M3 | ORIGINAL_REQUEST §R1 |
| 10 | Live Hangar Main Menu | Cosmic parallax backdrop, docking steam/exhaust emitters, glow buttons, telemetry ticker | M3 | ORIGINAL_REQUEST §R1 |
| 11 | Tactical Hologram Map Select | 5 maps + endless mode, 3D rotating planetary wireframe, CRT scanlines, full environmental stats | M3 | ORIGINAL_REQUEST §R1 |
| 12 | Cockpit Cybernetic HUD | G-force meter, pitch/artificial horizon, proximity warning alarm, radio chatter overlay | M3 | ORIGINAL_REQUEST §R1 |
| 13 | Ice Biome (Europa) | $0.65G$, $\mu=0.08$ low-friction terrain, cryo-geysers, falling icicles, cyan aesthetic | M4 | ORIGINAL_REQUEST §R3 |
| 14 | Orbit Biome (Zero-G) | $G=0$ gravity, deep space salvage, inertia drift, reverse thruster braking | M4 | ORIGINAL_REQUEST §R3 |
| 15 | Cavern Interactivity Hazards | Destructible/falling stalactites, turbulent plasma wind gusts, magma bubbles | M4 | ORIGINAL_REQUEST §R3 |
| 16 | Procedural Endless Rescue Mode | Chunk-based infinite cave generation, chained extractions, outposts, infinite score | M4 | ORIGINAL_REQUEST §R3 |
| 17 | E2E Test Suite & Hardening | Complete requirement-driven opaque-box test suites (Tiers 1-5), 0 analyze warnings, 100% tests | M5 | ORIGINAL_REQUEST §R5 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Core Security, Persistence & Achievements | HMAC-SHA256 tamper protection, nickname sanitization, 12 achievements system, starter ship persistence | none | **DONE** |
| 2 | M2: Unified Fleet, Vector Decals & Live Astronaut | `ShipMeshRenderer` unification, 5 ships with vector decals & bounds, live astronaut dynamics with G-strain & eye tracking | M1 | **DONE** |
| 3 | M3: UI/UX & Game Atmosphere Overhaul | Cadet ID Terminal, Live Hangar with parallax & steam, Tactical Holographic Map Select, Cockpit Cybernetic HUD | M1, M2 | PLANNED |
| 4 | M4: Cavern Biomes, Interactive Elements & Endless Rescue | `ice` Europa biome ($0.65G$, $\mu=0.08$), `orbit` zero-G biome, cavern hazards, procedural Endless Rescue mode | M2 | PLANNED |
| 5 | M5: E2E Test Pass & Adversarial Hardening | Pass 100% of E2E test suite (Tiers 1-4), Tier 5 adversarial testing, `flutter analyze` 0 warnings, 100% test pass | M1, M2, M3, M4 | PLANNED |

## Interface Contracts
### `SaveSecurityManager` ↔ `GameState`
```dart
class SaveSecurityManager {
  static String computeHmac({required int coins, required List<String> ownedRockets, required String leaderboardJson});
  static bool verifyHmac({required int coins, required List<String> ownedRockets, required String leaderboardJson, required String? signature});
  static String sanitizeNickname(String input);
}
```

### `ShipMeshRenderer` ↔ `RocketPainter` & `Lander`
```dart
class ShipMeshRenderer {
  static void renderShip({
    required Canvas canvas,
    required String shipId,
    required double scale,
    required double engineThrust,
    required double rcsThrust,
    required Vector2 pilotHeadOffset,
    required Vector2 pilotLookDirection,
    required double pilotGStrain,
    required bool isPanicking,
    required bool showLandingGear,
  });
  static Rect getModelBounds(String shipId);
}
```

### `CockpitHUD` ↔ `LanderZeroGame`
```dart
class CockpitTelemetryData {
  final double gForce;
  final double pitchAngle;
  final double proximityDistance;
  final bool isProximityAlert;
  final String? radioChatterMessage;
}
```

### `EndlessCaveManager` ↔ `LanderZeroGame`
```dart
class EndlessCaveManager extends Component with HasGameRef<LanderZeroGame> {
  void updateLanderPosition(Vector2 landerPosition);
  int get rescuesCompleted;
  int get currentScore;
}
```

## Code Layout
- `lib/game/rendering/ship_mesh_renderer.dart`: Unified vector ship drawing, vector insignias, live astronaut.
- `lib/game/state/save_security_manager.dart`: HMAC-SHA256 verification and nickname sanitization.
- `lib/game/state/achievements_manager.dart`: 12 achievements tracker and rewards.
- `lib/game/state/game_state.dart`: Persistence, 5 ships fleet config, upgrades.
- `lib/game/components/lander.dart`: Lander physics body, astronaut dynamic simulation.
- `lib/game/components/cave.dart`: Biome terrain generators (echo, wind, core, ice, orbit).
- `lib/game/components/endless_cave_manager.dart`: Procedural chunk-based endless rescue mode.
- `lib/game/components/hazards/`: Stalactites, cryo-geysers, plasma gusts, magma bubbles.
- `lib/ui/screens/nick_entry_screen.dart`: Cadet ID Terminal.
- `lib/ui/screens/main_menu_screen.dart`: Live Hangar main menu.
- `lib/ui/screens/map_select_screen.dart`: Tactical holographic map select.
- `lib/ui/widgets/cockpit_hud/`: G-force meter, artificial horizon, proximity alarm, radio chatter overlay.
- `test/`: Test suites covering all modules.
