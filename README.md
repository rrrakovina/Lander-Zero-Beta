# Lander Zero: Deep Space Rescue Ops

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Flame Engine](https://img.shields.io/badge/Flame-1.37+-E65100?logo=dart&logoColor=white)](https://flame-engine.org)
[![Forge2D](https://img.shields.io/badge/Physics-Forge2D-29B6F6)](https://pub.dev/packages/flame_forge2d)
[![Security: HMAC--SHA256](https://img.shields.io/badge/Security-HMAC--SHA256-4CAF50)](https://pub.dev/packages/crypto)
[![Tests: 484 Passing](https://img.shields.io/badge/Tests-484%20Passed-brightgreen.svg)](test/)
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

#### 4. Astronaut Customization & Dynamic Pilot Simulation
* **Pilot Wardrobe in Garage:**
  * **Suit Color (100% Free):** Classic Orange, NASA White, Cyber Cyan, Carbon Black, Hazmat Yellow, Crimson Interceptor.
  * **Helmet Types:** Sphere-1 (Retro bubble), Cyber-Visor (Angular neon slit), Miner Helmet (Armored grate), Swift-Aero (Streamlined tint).
  * **Suit Models:** SK-1 Cadet, Exo-Frame (Hydraulic harness), Cryo-Suit (Thermal weave).
* **Live Dynamic Pilot Physics:** Real-time head and ocular tracking oriented toward velocity vectors and terrain hazards, physiological $G$-force strain, and critical status pupil dilation.

#### 5. 5 Distinct Non-Linear Cavern Architectures
* **Echo Canyon (`echo`)**: Classic horizontal traverse with rolling hills, acoustic stalactite falls, and standard gravity ($1.0g$).
* **Deep Core (`core`)**: Pure 60-meter vertical chimney descent into magma depths at high gravity ($1.5g$) with rising heat bubbles and ceiling extraction.
* **Solar Winds (`wind`)**: Stepped zig-zag storm corridor with wind-shadow shelter alcoves dampening lateral plasma gusts by $85\%$.
* **Europa Ice Rift (`ice`)**: Branching maze (upper tight ice ledge vs lower sliding ramp with $\mu=0.08$) and cryo-icicles at $0.65g$.
* **Orbital Wreckage (`orbit`)**: Boundless $360^\circ$ open space zero gravity ($G=0$) with rotating kinetic debris and perimeter beacons.

#### 6. Thematic Cosmetic Cargo Variety
* **Uniform Physics:** Identical mass, tether tension, and docking dynamics across all variants.
* **5 Thematic Vector Models:** Emergency Rescue Pod (with porthole & waving pilot), Heavy Titanium Crate, Cryo Barrel with frosty vapor, Golden Science Probe, and Neon Energy Crystal.

#### 7. Soft Cyber-Tactile Audio Design
* Replaced harsh clicks with pleasant, damped acoustic taps, warm harmonic confirmation chimes, and low-frequency humming cues.

#### 8. Cybernetic Cockpit Telemetry & Save Security
* **Attitude / Artificial Horizon & Radial $G$-Meter:** Dynamic real-time flight data.
* **Directional Proximity Radar:** Audio-visual alarms detecting cavern wall proximity.
* **HMAC-SHA256 Anti-Tamper Security:** Cryptographic signature hashing protecting local `SharedPreferences` progress.

---

### Technical Architecture

```
lander_zero/
├── assets/audio/                 # Tactile UI audio & synthesized retro sound effects
├── lib/
│   ├── game/
│   │   ├── audio/                # GameAudioManager & sound controllers
│   │   ├── components/           # Forge2D entities (Lander, Rope, Cave, Cargo, Hazards)
│   │   ├── config/               # Physical world constants & aesthetic palette
│   │   ├── rendering/            # Unified vector mesh rendering engines
│   │   ├── state/                # GameState, SaveSecurityManager, Achievements
│   │   └── lander_zero_game.dart # Flame Forge2D central game loop
│   ├── ui/
│   │   ├── dialogs/              # Modals (Achievements, Settings, Leaderboards)
│   │   ├── painters/             # ShipMeshRenderer, Radar & Map preview visualizers
│   │   ├── screens/              # Menu, Garage, MapSelect, Flight Cadet Terminal
│   │   └── widgets/              # MinimapWidget, CockpitHUD, GlassPanel
│   └── main.dart                 # Application bootstrap & routing
└── test/                         # 25 comprehensive test suites (424 unit/widget tests)
```

---

## Русская Версия

### О проекте
**Lander Zero: Deep Space Rescue Ops** — это научно-фантастический физический 2D-симулятор спасательных космических операций на **Flutter**, **Flame Engine** и **Forge2D**.

---

### Ключевые Механики и Особенности

1. **Векторное Двухдвигательное Управление**: Дифференциальная тяга, расчет моментов инерции и коэффициентов демпфирования.
2. **Многозвенный 12-Узловой Трос**: Реалистичная эластичность, натяжение и раскачка груза со смещением центра масс.
3. **Флот из 5 Кораблей**: «Спутник-1» и «Стриж-02» (бесплатно на старте), «Ураган», «Игла», «Буран-М / Titan-V» ($240$ щита) и ионный «Квазар / Quasar-IX».
4. **Кастомизация Космонавта в Гараже**: Бесплатная палитра цветов скафандра + покупка шлемов («Сфера-1», «Кибер-Визор», «Горняк», «Стриж-Аэро») и костюмов («СК-1 Кадет», «Экзо-Каркас», «Крио-Комбинезон»).
5. **5 Уникальных Архитектур Карт**:
   * **Каньон Эхо (`echo`)**: Горизонтальный полет над холмами со сталактитами ($1.0g$).
   * **Глубинное Ядро (`core`)**: 60-метровый вертикальный колодец при $1.5g$ с подъемом груза со дна к потолочному шлюзу.
   * **Солнечные Ветра (`wind`)**: Ступенчатый зигзаг с уступами-укрытиями от бокового шквала.
   * **Ледяные Разломы Европы (`ice`)**: Разветвленный лабиринт (верхний карниз vs нижний скользкий пандус $\mu=0.08$) и сосульки.
   * **Орбитальные Обломки (`orbit`)**: Открытый космос $360^\circ$ без стен в невесомости ($G=0$) с вращающимися обломками.
6. **Косметическое Разнообразие Грузов**: Спасательная капсула с машущим космонавтом, титановый контейнер с рудой, крио-бочка с паром, золотистый научный зонд и кристалл с неоновым свечением (физика везде одинаковая).
7. **Мягкие Тактильные Звуки Меню**: Приятные приглушенные щелчки, теплые перезвоны подтверждения и мягкий зуммер отказа.
8. **HMAC-SHA256 Защита Сейвов**: Криптографическая валидация сохранений `SharedPreferences`.


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

### Запуск и Разработка (PC / Web)

```bash
# 1. Установка зависимостей
flutter pub get

# 2. Запуск полного набора автотестов (484 теста)
flutter test

# 3. Локальный запуск в браузере (Google Chrome)
flutter run -d chrome

# 4. Сборка продакшн-версии для Веб / Яндекс Игр (CanvasKit)
flutter build web --release --base-href="./"
```
