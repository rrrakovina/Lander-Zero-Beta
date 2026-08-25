# Lander Zero: Deep Space Rescue Ops

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Flame Engine](https://img.shields.io/badge/Flame-1.37+-E65100?logo=dart&logoColor=white)](https://flame-engine.org)
[![Forge2D](https://img.shields.io/badge/Physics-Forge2D-29B6F6)](https://pub.dev/packages/flame_forge2d)
[![Security: HMAC--SHA256](https://img.shields.io/badge/Security-HMAC--SHA256-4CAF50)](https://pub.dev/packages/crypto)
[![Tests: 376 Passing](https://img.shields.io/badge/Tests-376%20Passed-brightgreen.svg)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**🎮 Play Online / Играть онлайн:** [https://rrrakovina.github.io/Lander-Zero-Beta/](https://rrrakovina.github.io/Lander-Zero-Beta/)

> [🇷🇺 Русский](#русская-версия) | [🇬🇧 English](#english-version)

---

## English Version

### Overview
**Lander Zero: Deep Space Rescue Ops** is a retro-futuristic, physics-driven planetary salvage simulation developed with **Flutter**, **Flame Engine**, and **Forge2D**. 

Piloting specialized landing craft through hazardous extraterrestrial subterranean caverns and zero-gravity orbital wreckage, players must execute high-precision navigation, tether cargo containers with multi-link elastic ropes, and safely extract assets while countering gravitational anomalies, lateral plasma winds, and structural hazards.

---

### Key Game Mechanics

#### 1. Dual-Vector Propulsion & Flight Dynamics
* **Independent Differential Thrust:** Dual thruster controls enabling simultaneous pitch management, differential torque, and coordinated vertical ascent.
* **Mass Multipliers & Aerodynamic Profiles:** Unique vessel weights, moments of inertia, and linear/angular damping profiles across the fleet.

#### 2. Multi-Segment Tether & Pendulum Physics
* **12-Node Discrete Elastic Cable:** Realistic tensile mechanics with visual stress-state HUD coloring (cyan for nominal load, orange for elastic strain, crimson for critical failure).
* **Dynamic Center-of-Mass Shifts:** Oscillating cargo dynamics induce rotational momentum on the host vessel, demanding counter-thrust corrections.

#### 3. Expanded Fleet & Specialization
* **«Sputnik-1» (`sputnik`)**: Classic Soviet-era space pioneer; balanced thrust, fuel, and armor. *(Default starter, free)*
* **«Swift-02» (`swift`)**: Lightweight high-speed interceptor ($40.0$ thrust, agile vectoring, reduced hull strength). *(Default starter, free)*
* **«Cyclone» (`cyclone`)**: Heavy industrial transporter ($180.0$ armor rating, high-capacity propellant tanks).
* **«Needle» (`needle`)**: Precision speedster with low aerodynamic drag and lightweight ski skids.
* **«Titan-V» (`titan`)**: Armored dreadnought with triple-cluster main thrusters and heavy impact damping ($240.0$ shield).
* **«Quasar-IX» (`quasar`)**: Experimental ion craft featuring bilateral reaction control micro-thrusters (RCS).

#### 4. Vector Decals & Live Astronaut Simulation
* **Procedural Vector Insignias:** High-contrast hull typography and hazard striping (`СССР-01`, `SWIFT-02`, `TITAN-V`, `QUASAR-IX`, `CY-88`, `INTERCEPTOR-07`).
* **Dynamic Pilot Simulation:** Real-time head and ocular tracking oriented toward velocity vectors and terrain hazards, physiological $G$-force strain, and critical status pupil dilation.

#### 5. Planetary Biomes & Environmental Anomalies
* **Echo Canyon (`echo`)**: Temperate baseline cavern with falling limestone formations and standard gravity ($1.0g$).
* **Solar Winds (`wind`)**: Exposed cosmic rift with ionized lateral plasma gusts and micro-meteorite turbulence.
* **Deep Core (`core`)**: High-gravity anomaly ($1.5g$) with geothermal magma vents, thermal air distortion, and elevated structural collision multipliers.
* **Europa Ice Rift (`ice`)**: Cryogenic sub-surface cavern with reduced lunar gravity ($0.65g$), ultra-low surface friction ($\mu=0.08$), and falling ice stalactites.
* **Orbital Wreckage (`orbit`)**: Microgravity environment ($0.0g$) requiring reverse thruster deceleration and pure rotational inertia governance.
* **Endless Rescue Mode (`endless`)**: Procedural chunk-based endless expedition featuring chained survivor extractions and outpost refuel depots.

#### 6. Cybernetic Cockpit Telemetry
* **Attitude / Artificial Horizon:** Pitch ladder and banking inclination gauges.
* **Radial $G$-Force Meter:** Dynamic real-time acceleration tracking.
* **Directional Proximity Radar:** Audio-visual alarms detecting imminent cavern wall collisions.
* **Base Radio Transceiver:** Contextual procedural dialogue with animated speaker portraits.

#### 7. 12 Persistent Achievements & Cryptographic Security
* Comprehensive achievement matrix rewarding economic efficiency, terminal velocity thresholds, zero-damage landings, and fleet mastery.
* **HMAC-SHA256 Anti-Tamper Security:** Cryptographic signature hashing protecting local `SharedPreferences` state from unauthorized modification.

---

### Technical Architecture & Directory Layout

```
lander_zero/
├── assets/audio/                 # Synthesized retro audio assets (SFX & BGM)
├── lib/
│   ├── game/
│   │   ├── audio/                # GameAudioManager & sound FX controllers
│   │   ├── components/           # Forge2D physics entities (Lander, Rope, Cave, Pickups)
│   │   ├── config/               # Physical world constants & aesthetic palette
│   │   ├── rendering/            # Unified vector mesh rendering engines
│   │   ├── state/                # GameState, SaveSecurityManager, Achievements
│   │   └── lander_zero_game.dart # Flame Forge2D central game loop
│   ├── ui/
│   │   ├── dialogs/              # Modals (Achievements, Settings, Leaderboards)
│   │   ├── painters/             # ShipMeshRenderer, Radar & Holographic visualizers
│   │   ├── screens/              # Menu, Garage, MapSelect, Flight Cadet Terminal
│   │   └── widgets/              # MinimapWidget, CockpitHUD, GlassPanel
│   └── main.dart                 # Application bootstrap & routing
└── test/                         # 19 comprehensive test suites (376 unit/widget tests)
```

---

## Русская Версия

### О проекте
**Lander Zero: Deep Space Rescue Ops** — это научно-фантастический физический 2D-симулятор спасательных космических операций, разработанный на базе **Flutter**, **Flame Engine** и **Forge2D**.

Игроку предстоит управлять специализированными посадочными модулями в недрах аномальных внеземных каньонов и в невесомости орбитальных свалок, осуществлять ювелирный спуск, захватывать спасательные контейнеры многозвенным тросом и эвакуировать груз в условиях гравитационных перегрузок, боковых солнечных ветров и сложного рельефа.

---

### Ключевые Механики и Особенности

#### 1. Векторное Двухдвигательное Управление
* **Дифференциальная тяга:** Независимое управление левым и правым маршевыми двигателями для регулирования угла тангажа, маневрирования и вертикального подъема.
* **Физика массы и инерции:** Реалистичный расчет момента инерции, массы корпуса и сопротивления среды для каждого корабля.

#### 2. Физика 12-Звенного Гибкого Троса
* **Дискретный упругий кабель:** Динамическое натяжение с визуальной цветовой индикацией нагрузки (бирюзовый — штатно, оранжевый — натяжение, красный — критическая нагрузка/обрыв).
* **Маятниковый эффект:** Раскачивание подвешенного контейнера смещает центр тяжести корабля, требуя постоянной компенсации вектором тяги.

#### 3. Расширенный Флот Кораблей
* **«Спутник-1» (`sputnik`)**: Базовый советский модуль со сбалансированными характеристиками. *(Открыт на старте бесплатно)*
* **«Стриж / Swift-02» (`swift`)**: Высокоскоростной маневренный перехватчик с форсированной тягой ($40.0$), но облегченным корпусом. *(Открыт на старте бесплатно)*
* **«Ураган» (`cyclone`)**: Тяжелый грузовой тягач с усиленной броней ($180.0$) и объемными баками.
* **«Игла» (`needle`)**: Обтекаемый скоростной модуль с минимальным профилем сопротивления и посадочными лыжами.
* **«Буран-М / Titan-V» (`titan`)**: Тяжелый спасательный дредноут с трехсопельной силовой установкой и бронезащитой ($240.0$).
* **«Квазар / Quasar-IX» (`quasar`)**: Научный модуль на ионной тяге с боковыми импульсными маневровыми микродвигателями (RCS).

#### 4. Векторные Декали и Живой Космонавт
* **Четкая бортовая маркировка:** Векторные надписи, шевроны опасности и номера (`СССР-01`, `SWIFT-02`, `TITAN-V`, `QUASAR-IX`, `CY-88`, `INTERCEPTOR-07`).
* **Анимация пилота:** Слежение взглядом и поворот шлема по вектору скорости и к опасным объектам, деформация лица при перегрузках $G$, расширение зрачков и паника при критическом уроне или нехватке топлива.

#### 5. Планетарные Биомы и Режимы
* **Каньон Эхо (`echo`)**: Базовая пещера со стандартной гравитацией ($1.0g$) и разрушаемыми сталактитами.
* **Солнечные Ветра (`wind`)**: Разлом с открытым космосом, непрерывным боковым сносом плазменным ветром и турбулентностью.
* **Глубинное Ядро (`core`)**: Тяжелая гравитация ($1.5g$), геотермальные гейзеры и повышенный урон от соударений.
* **Ледяные Разломы Европы (`ice`)**: Криогенная шахта с пониженной гравитацией ($0.65g$), сверхскользким грунтом ($\mu=0.08$) и падающими сосульками.
* **Орбитальные Обломки (`orbit`)**: Полная невесомость ($0.0g$), требующая реверсивного торможения и гашения угловой инерции.
* **Бесконечная Экспедиция (`endless`)**: Процедурный бесконечный режим с цепочкой спасаемых капсул, чекпоинтами дозаправки и возрастающей сложностью.

#### 6. Кибернетический HUD Кокпита
* **Авиагоризонт и шкала тангажа.**
* **Дуговой стрелочный $G$-метр перегрузки.**
* **Датчик опасного сближения (Proximity Warning)** со звуковым и визуальным предупреждением.
* **Окно радиопереговоров ЦУП** с анимированными портретами и репликами.

#### 7. 12 Достижений и Защита Сохранений (HMAC-SHA256)
* Прогресс по 12 уникальным достижениям с выдачей наград.
* Криптографическая защита локального прогресса и монет от несанкционированной модификации.

---

### Запуск и Разработка

```bash
# 1. Установка зависимостей
flutter pub get

# 2. Запуск локального тестового набора (376 тестов)
flutter test

# 3. Сборка для Веб (WASM / CanvasKit)
flutter build web --release --base-href="./"

# 4. Локальный запуск на десктопе / мобильных устройствах
flutter run
```
