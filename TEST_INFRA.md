# E2E Test Infra: Lander Zero Upgrade

## Test Philosophy
- Opaque-box, requirement-driven derived strictly from `ORIGINAL_REQUEST.md`.
- No dependency on implementation design details or internal private methods.
- Methodology: Category-Partition + Boundary Value Analysis (BVA) + Pairwise Combinatorial Testing + Real-World Workload Testing.

## Feature Inventory
| # | Feature | Source (Requirement) | Tier 1 (Feature) | Tier 2 (Boundary) | Tier 3 (Pairwise) |
|---|---------|----------------------|:----------------:|:-----------------:|:-----------------:|
| 1 | HMAC-SHA256 Save Protection | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ |
| 2 | Nickname Sanitization | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ |
| 3 | Starter Ships (Sputnik & Swift 0 Cost) | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 4 | Shop Ships (Titan & Quasar & Cyclone) | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 5 | Vector Decals & Insignias Rendering | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 6 | Live Dynamic Astronaut Simulation | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 7 | Cadet ID Registration Terminal | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 8 | Live Hangar Main Menu & Telemetry | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 9 | Tactical Hologram Map Select | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 10 | Cockpit Cybernetic HUD Instruments | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 11 | Ice Biome (Europa 0.65G, Low Friction) | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 12 | Orbit Biome (Zero-G, Drift, Reverse RCS) | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 13 | Cavern Hazards (Stalactites, Plumes, Gusts) | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 14 | Procedural Endless Rescue Mode | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 15 | 7 New Achievements (12 Total) | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |
| 16 | Unified ShipMeshRenderer (0 Duplication) | ORIGINAL_REQUEST §R5 | 5 | 5 | ✓ |
| 17 | Static Analysis & Test Cleanliness | ORIGINAL_REQUEST §Acceptance | 5 | 5 | ✓ |

## Test Architecture
- **Test Runner**: `flutter test`
- **Pass/Fail Semantics**: All test suites must exit with code 0; 0 failed tests, 0 skipped tests.
- **Directory Layout**:
  - `test/unit/`: Pure Dart logic tests (HMAC integrity, security, achievements manager, game state, nickname sanitization).
  - `test/widget/`: Flutter UI/widget tests (Flight Cadet Terminal, Live Hangar, Hologram Map Select, Cockpit HUD, Garage).
  - `test/game/`: Flame & Forge2D physics tests (5 ships physics, live astronaut telemetry, 5 biomes, hazards, endless chunk generation).
  - `test/e2e/`: Full mission flows and real-world scenario tests.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | First-time cadet registration with callsign sanitization and Swift-02 starter deployment | F1, F2, F3, F7, F8 | High |
| 2 | High-speed rescue run on Europa ice cavern with cryo-geyser avoidance and zero-fuel landing | F6, F10, F11, F13, F15 | High |
| 3 | Deep-space zero-G orbital salvage with reverse thruster braking and zero-damage extraction | F4, F6, F10, F12, F15 | High |
| 4 | Endless rescue mode multi-chunk navigation with chained extractions and refuel checkpoints | F6, F10, F14, F15 | High |
| 5 | Fleet upgrade mastery path unlocking Titan-V and Quasar-IX and achieving Fleet Admiral | F1, F3, F4, F15 | High |
| 6 | Save data tamper detection: injected corrupted coin balance reverts cleanly to verified state | F1, F2, F3 | High |
| 7 | Full mission cockpit telemetry validation under intense G-force strain and cavern proximity alarm | F6, F10, F13 | High |
| 8 | Solar wind plasma gust turbulence navigation with titanium tether achievement check | F10, F13, F15 | High |
| 9 | Cosmic Tycoon path: collecting 3000+ coins across all 5 biomes with HMAC signature verified | F1, F4, F11, F12, F15 | High |

## Coverage Thresholds
- **Tier 1 (Feature Coverage)**: ≥85 test cases (5 per feature across 17 features)
- **Tier 2 (Boundary & Corner Cases)**: ≥85 test cases (5 per feature across 17 features)
- **Tier 3 (Cross-Feature Combinations)**: ≥17 test cases (pairwise interaction matrix)
- **Tier 4 (Real-World Application Scenarios)**: ≥9 comprehensive scenario test cases
- **Total Target**: ≥196 test cases across the entire test suite
